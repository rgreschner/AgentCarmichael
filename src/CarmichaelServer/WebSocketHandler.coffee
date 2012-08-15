class WebSocketHandler

  # Public ctor.
  constructor: (args) ->
    @connections = []
    @logger = args.logger
    @inFlightRequestRepo = args.inFlightRequestRepo
  
  # Get handler for stream with specific type.
  #
  # @param streamType [String] Type of stream.
  # @param args [Object] Handler constructor arguments.
  # @return [Object] Handler for stream.
  #
  getHandlerForStreamWithType: (streamType, args) ->
    handler = null
    if 'http_proxy' == streamType
      handler = new HttpProxyStreamHandler args
    if 'control' == streamType
      handler = new ControlStreamHandler args
    return handler

  # Get corresponding connection for client.
  #
  # @param myClient [Object] Client to get connection for.
  # @returns [Object] Connection of client.
  #
  getConnectionForClient: (myClient) ->
    value = @connections[myClient]
    if undefined == value
      value = null
    return value

  # Set correspondin#g connection object for client.
  #
  # @param myClient [Object] Client to set connection for.
  # @param connection [Object] Connection of client.
  #
  setConnectionForClient: (myClient, connection) ->
    @connections[myClient] = connection
    return

  # Accept WebSocket connections.
  # 
  # @param myClient [Object] Client to accept websocket connections for.
  #
  acceptWebSocketConnection: (myClient) ->
    

    # Get or create connection object for WebSocket client.
    connection = @getOrCreateConnectionForClient myClient
    
    internalSocket = myClient._socket
    remoteAddress = {
      address: internalSocket.upgradeReq.connection.remoteAddress,
      port: internalSocket.upgradeReq.connection.remotePort
    }
    connection.remoteAddress = remoteAddress
    formatedRemoteAddress = '{0}:{1}'.format(remoteAddress.address, remoteAddress.port)
    
    @logger.info 'Accepted connection from \'{0}\', assigned id \'{1}\'.'.format(formatedRemoteAddress, connection.id)

    myClient.on 'stream', (stream, meta) =>
      @handleWebSocketStream myClient, stream, meta
      return
    myClient.on 'error', (error) =>
      @logger.error error
      return  


    return

    
  # Get or create connection object for client.
  #
  # @returns [Object] Connection object for client.
  #
  getOrCreateConnectionForClient: (myClient) ->
    connection = @getConnectionForClient myClient
    if null == connection
      connection = @createConnection()
    return connection
    
  isStreamAuthenticationNeeded: (streamType) ->
    if "control" == streamType
      return false
    return true
  

  # Handle supplied WebSocket stream.
  #
  # @param myClient [Object] BinaryJS client.
  # @param stream [Object] Stream to handle.
  # @param meta [Object] Stream meta data.
  #
  handleWebSocketStream: (myClient, stream, meta) ->

    # Get or create connection object for WebSocket client.
    connection = @getOrCreateConnectionForClient myClient
    
    streamType = meta.type
    needsStreamAuthentication = @isStreamAuthenticationNeeded streamType
    @logger.info 'Handling new stream of type \'{0}\', needs authentication is \'{1}\'.'.format(streamType, needsStreamAuthentication)

    if needsStreamAuthentication
    
      isAuthenticated = false
      
      try
        # TODO: Check.
        
      catch error
        isAuthenticated = false
        
      # XXX: Authentication override.
      isAuthenticated = true  
        
      if !isAuthenticated
        @logger.info 'Not authenticated.'
        return
    
    handler = null
    
    args = {
      stream: stream,
      meta: meta,
      logger: @logger,
      inFlightRequestRepo: @inFlightRequestRepo
    }
    handler = @getHandlerForStreamWithType streamType, args
    if null != handler
      connection.handlers.push handler
    
    # Set connection object.
    @setConnectionForClient myClient, connection
    
    # Print connectino object for debug.
    @logger.debug util.inspect connection
    
    if null != handler
      handler.handle()
    
    return

  # Create new connection object.
  #
  # @returns [Object] New connection object.
  #
  createConnection: () ->
    connection = {
      id : uuid.v4(),
      handlers : []
    }
    return connection
   
