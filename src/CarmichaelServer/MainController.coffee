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
    @serverArgs = null
    
    @myOtherExpressApp = new MyOtherExpressApp().app

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
    webSocketHandlerArgs = {
      logger: @logger,
      inFlightRequestRepo: @inFlightRequestRepo
    }
    @webSocketHandler = new WebSocketHandler webSocketHandlerArgs
    # Set fallback values.
    if null == @serverArgs
      @serverArgs = {
        port : 9000,
        protocol : 'https'
      }

  # Default handler for HTTP requests.
  #
  # @param req [Object] HTTP request.
  # @param res [Object] HTTP response.
  #
  defaultHttpHandler: (req, res) ->
    @myOtherExpressApp req, res
    return

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
      @webSocketHandler.acceptWebSocketConnection myClient
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
