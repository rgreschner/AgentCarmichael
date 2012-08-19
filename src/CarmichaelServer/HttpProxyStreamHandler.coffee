EventEmitter = require('events').EventEmitter
express = require('express')

# Stream handler for HTTP proxy requests.
#
class HttpProxyStreamHandler extends BaseStreamHandler

  # Public ctor.
  #
  # @params args [Object] Constructor arguments.
  #
  constructor: (args) ->
    super(args)
    @isHandling = false
    @inFlightRequestRepo = args.inFlightRequestRepo
    @myExpressApp = new MyExpressApp().app
    @expressProcessingNode = new ExpressInternalRequestProcessingNode { 
      app : @myExpressApp
    }
    inputNodes = [
      new ProxyRequestPrepareInputNode(),
      new ProxyRequestFilterInputNode()
    ]
    for i in [0..inputNodes.length-2]
      inputNodes[i].setOutputNode inputNodes[i+1]
    lastInputNode = inputNodes[inputNodes.length-1]
    @firstInputNode = inputNodes[0]
    @firstInputNode.on 'finished', (outputArgs) =>
      req = outputArgs.req
      @inFlightRequestRepo.add req
      return
    lastInputNode.on BaseProcessingNode.prototype.EVENT_FINISHED, (outputArgs) =>
      if true == outputArgs.aborted
        @logger.debug 'Aborted processing.'
        return
      @proxyRetrieveResource outputArgs.req
      return

  # Start stream handling.
  #
  handle: () ->
  
    @isHandling = true
    @stream.on 'error', (error) =>
      console.log error
      return
      
    cbHandleData = (chunk) =>
      @handleData chunk
    @cbHandleData = cbHandleData
    @stream.on 'data', cbHandleData
    
    return 
  onParserGotUrl: (hp, buf, start, len) ->
    str = buf.toString('ascii', start, start + len)

    if hp.data.url
      hp.data.url += str
    else
      hp.data.url = str
	  
  # Get handler type as string.
  #
  # @returns [String] Type of handler as string.
  #
  getHandlerType: () ->
    return 'http_proxy'
	
  # Callback called when HTTP parser finished parsing of header field.
  #
  # @params hp [Object] HTTP parser.
  # @params buf [Buffer] Input buffer containing header field.
  # @param start [Int] Start of header field.
  # @param len [Int] Length of header field.
  #
  onParserGotHeaderField: (hp, buf, start, len) ->
    if hp.data.partial.value
      hp.data.headers[hp.data.partial.field] = hp.data.partial.value
      hp.data.partial = {
        'field' : '',
        'value' : ''
      }
      hp.data.partial.field += buf.toString('ascii', start, start + len).toLowerCase()
	  
  # Create HTTP response object for proxied request.
  #
  # @param proxiedReq [Object] Proxied request.
  # @param stream [Stream} Handled input stream.
  # @returns [Object] HTTP response object for proxied request.
  #
  createHttpResponseForRequest: (proxiedReq, stream) ->
    res = new http.ServerResponse proxiedReq
    res.headers = []
	
    # TODO: Move and make user optional.
    res.setHeader 'X-RequestId', proxiedReq.id
    
    stream._httpMessage = res
    res.connection = stream
    res.writable = true
    res._writeRaw = (chunk, encoding) =>
      try
        stream.write(chunk, encoding)
      catch error
        @logger.error error
      return
    return res
	
  # Set HTTP client options to accomplish
  # proxy chaining.
  #
  # @param options [Object] Options of HTTP client.
  #
  setProxyChainingOptions: (options) ->

    # Set default port to 80.
    if (undefined == options.port)
      options.port = null
    if (null == options.port)
      options.port = 80

    oldHost = options.host
    newPath = "http://" + options.host
    if '/' != options.path
      newPath = newPath + options.path
    options.path = newPath
    options.host = "localhost"
    options.port = 8118
    options.headers['Host'] = oldHost
	
    # IPF*ck clone
	# TODO: Move/refactor.
    #options.headers['X-FORWARDED-FOR'] = '127.0.0.1'
    #options.headers['VIA'] = '127.0.0.1'
    #options.headers['CLIENT-IP'] = '127.0.0.1'
	
    return
	
  # Retrieve actual resource.
  #
  # @param proxiedReq [Object] Proxied request.
  #
  proxyRetrieveResource: (proxiedReq) ->

    # Set dummy members and methods on proxiedReq
    # to be compatible to normal HTTP request.
    proxiedReq.socket = {}
    proxiedReq.socket.destroy = () ->

    proxiedReqUrl = proxiedReq.parsedUrl

    stream = @stream
    res = @createHttpResponseForRequest proxiedReq, stream

    @logger.debug 'Host is {0}.'.format(proxiedReqUrl.host)
    if '127.0.0.42' == proxiedReqUrl.host
      @logger.info 'In local mode.'

      inputArgs = {
        req : proxiedReq,
        res: res
      }
      @expressProcessingNode.once BaseProcessingNode.prototype.EVENT_FINISHED, (outputArgs) =>
      
        @logger.debug outputArgs
        # Actually end request.
        outputArgs.res.end()

        return
      @expressProcessingNode.process inputArgs
      
      return
    
    @proxyRetrieveResourceFromHttp proxiedReq, res
    return
  
  # Retrieve HTTP resource for proxied request.
  #
  # @param proxiedReq [Object] Proxied HTTP request.
  # @param res [Object9 HTTP response for proxied request.
  #
  proxyRetrieveResourceFromHttp: (proxiedReq, res) ->
  
    options = proxiedReq.parsedUrl
    options = { 
      host: options.host,
      port: options.port, 
      path: options.path
    }
    
    options.method = 'GET'
    options.headers = {
      'Connection':'close'
    }

    # IPF*ck clone.
	# TODO: Move/refactor.
    #proxiedReq.headers['X-FORWARDED-FOR'] = '127.0.0.1'
    #proxiedReq.headers['VIA'] = '127.0.0.1'
    #proxiedReq.headers['CLIENT-IP'] = '127.0.0.1'

    # Proxy chaining
    @setProxyChainingOptions options
	
    @logger.debug options

    http.get options, (remoteRes) =>
      @onHttpClientRequestFetchComplete proxiedReq, remoteRes, res
      return
    return

   
  # Callback for when HTTP client finished fetch of
  # HTTP request.
  #
  # @param remoteRes [Object] HTTP response from server.
  # @param res [Object] HTTP response for client.
  #
  onHttpClientRequestFetchComplete: (proxiedReq, remoteRes, res) =>
  
    if !@isHandling
        return
  
    remoteRes.useChunkedEncodingByDefault = false
    buffered = []

    @logger.debug 'Got response.'
      
    contentType = remoteRes.headers['content-type']
    contentLength = undefined
    res.headers['content-type'] = contentType

    if (undefined != remoteRes.headers['content-length'])
      contentLength = remoteRes.headers['content-length'];
    if (undefined != contentLength)
      res.headers['content-length'] = contentLength
    statusCode = remoteRes.statusCode
    res.setHeader 'X-AgentCarmichael', 'beta'

    res.statusCode = statusCode
    if 300 <= statusCode && 399 >= statusCode
      location = remoteRes.headers['location']
      @logger.debug 'Redirect, location is \'{0}\'.'.format(location)
      res.setHeader('Location', location)
      res.location = location

    remoteRes.on 'data', (chunk) =>
      res.write(chunk)
      return

    remoteRes.on 'end', () =>
      @logger.debug 'Request stream ended, status is {0}, content-length {1}, content-type {2}'.format(statusCode, contentLength, contentType)
      res.end()

    return

  # Callback when parser finished parsing
  # of HTTP request's headers.
  #
  # @param info [Object] Parsed HTTP request.
  #
  onParserHeadersComplete: (req) ->
    
    inputArgs = {
      req: req
    }

    @firstInputNode.process inputArgs
      
    return
       
  # Create HTTP request parser.
  #
  # @returns [Object] HTTP request parser.
  #
  createRequestParser: () ->
    stream = @stream
    hp = new HTTPParser 'request'
    hp.data = {
      'headers' : {},
      'partial' : {
        'field' : '',
        'value' : ''
      }
    }

    hp.onURL = (buf, start, len) =>
      @onParserGotUrl hp, buf, start, len
      return
  
    hp.onHeaderField = (buf, start, len) =>
      @onParserGotHeaderField hp, buf, start, len
      return

    hp.onHeaderValue = (buf, start, len) =>
      hp.data.partial.value += buf.toString('ascii', start, start + len).toLowerCase()

    hp.onHeadersComplete = (req) =>
      @onParserHeadersComplete req

    return hp
	
  # Handle data of incoming HTTP request.
  #
  # @param chunk [Buffer] Raw data of HTTP request.
  #
  handleData: (chunk) ->
  
    if !@isHandling
        return
  
    # TODO: Find out why chunk is often null...
    if null == chunk || 0 == chunk.length
      # console.log "Chunk is null."
      return
    buffer = new Buffer chunk
	
    @hp = @createRequestParser()
    @hp.execute buffer, 0, buffer.length

    return
  stop: () ->
    @isHandling = false