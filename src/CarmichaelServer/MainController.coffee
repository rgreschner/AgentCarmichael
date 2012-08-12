BinaryJS = require 'binaryjs'
BinaryServer = BinaryJS.BinaryServer
BinaryClient = BinaryJS.BinaryClient
http = require 'http'
https = require 'https'
util = require 'util'
HTTPParser = process.binding('http_parser').HTTPParser
winston = require('winston')
fs = require 'fs'
require '../stringFormat.js'

# Main controller.
#
class MainController

  # Public ctor.
  #
  # @param args [Object] Constructor arguments.
  #
  constructor: (args) ->

    # Set field values to null.
    @logger = null
    @connections = []
    @serverArgs = null

    @inFlightRequestRepo = new InFlightRequestRepository()
    @inFlightRequestRepo.on 'added', (id) ->
      console.log 'Added in-flight request with id {0}'.format(id)
    @inFlightRequestRepo.on 'removed', (id) ->
      console.log 'Removed in-flight request with id {0}'.format(id)
    
    # Set field values from args.
    if null != args
      @logger = args.logger
      @serverArgs = args.serverArgs

    # Normalize assigned values.
    if undefined == @serverArgs
      @serverArgs = null

    # Set fallback values.
    if null == @serverArgs
      @serverArgs = {
        port : 9000,
        protocol : 'https'
      }

  # Create new connection object.
  #
  # @returns [Object] New connection object.
  #
  createConnection: () ->
    connection = {
      handlers : []
    }
    return connection
   
  # Get or create connection object for client.
  #
  # @returns [Object] Connection object for client.
  #
  getOrCreateConnectionForClient: (myClient) ->
    connection = @getConnectionForClient myClient
    if null == connection
      connection = @createConnection()
    return connection
    
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
    @logger.info 'Handling new stream of type \'{0}\'.'.format(streamType)

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
    @logger.info 'Accepted connection'

    myClient.on 'stream', (stream, meta) =>
      @handleWebSocketStream myClient, stream, meta
      return
    myClient.on 'error', (error) =>
      @logger.error error
      return  


    return

  # Default handler for HTTP requests.
  #
  # @param req [Object] HTTP request.
  # @param res [Object9 HTTP response.
  #
  defaultHttpHandler: (req, res) ->
    res.write 'Invalid request.'
    res.statusCode = 500
    res.end()

  # Create HTTP server to use.
  #
  # @param serverArgs [Object] Args to create server with.
  #
  createHttpServer: (serverArgs) ->
    serverOpts = {
      pfx: fs.readFileSync(__dirname+'/testcert.pfx'),
      passphrase: 'test'
    }
    protocol = serverArgs.protocol

    httpHandler = (req, res) =>
      @defaultHttpHandler req, res
      return
    httpServer = null
    @logger.info 'Creating server for protocol \'{0}\'.'.format(protocol)
    if 'http' == protocol
      
      httpServer = http.createServer httpHandler 
    if 'https' == protocol
      httpServer = https.createServer serverOpts, httpHandler
    

    httpServer.on 'error', (error) =>
      @logger.error error
      return

    return httpServer

  # Create BinaryJS server to use.
  #
  # @returns [Object] BinaryJS server.
  #
  createBinaryJsServer: () ->
    server = BinaryServer {
      server: @httpServer
    }

    server.on 'connection', (myClient) =>
      @acceptWebSocketConnection myClient
      return
    server.on 'error', (error) =>
      @logger.error error
      return

    return server

  # Run controller.
  #
  run: () ->
    serverArgs = @serverArgs
    port = serverArgs.port

    @httpServer = @createHttpServer serverArgs
    @server = @createBinaryJsServer()

    @logger.info 'Starting server on port {0}.'.format(port)

    @httpServer.listen port

    return
