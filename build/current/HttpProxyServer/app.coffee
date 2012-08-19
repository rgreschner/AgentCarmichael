# Main controller.
#
class MainController

  constructor: (args) ->
    @logger = args.logger

  # Callback for when HTTP proxy server starts
  # listening.
  #
  # @param proxyServer [Object] Server instance.
  #
  onProxyServerStartsListening: (proxyServer) ->
    address = proxyServer.address()
    @logger.info 'Proxy server listening on {0}:{1}'.format(address.address, address.port)
    return

  # Called when data on HTTP proxy server was received.
  #
  # @param chunk [Buffer] Received data.
  # @param socket [Object] HTTP proxy server socket data was received on.
  #
  onProxyServerSocketGotData: (chunk, socket) ->
  
    if undefined == socket.wsClientStream
      socket.wsClientStream = null
      
    if null == socket.wsClientStream
      # Buffer received data.
      socket.buffered.push chunk
      return
      
    # Push received data directly to Carmichael server.
    try
      socket.wsClientStream.write chunk
    catch error
      @logger.error error
    return

  # Callback for when HTTP proxy server accepted
  # connection.
  #
  # @param socket [Object] Accepted connection.
  #
  onProxyServerAcceptedConnection: (socket) ->
  
    # TODO: Refactor/extract callback methods.
  
    streamId = @nextStreamId
    @nextStreamId = @nextStreamId + 1
    stream = @wsClient.createStream {
      name : 'stream'+streamId,
      type : 'http_proxy'
    }
    stream.on 'data', (chunk) ->
      try
        socket.write chunk
      catch error
        @logger.error error
    stream.on 'end', () ->
      try
        socket.end()
      catch error
        @logger.error error

    stream.on 'error', (e) ->
        @logger.error error

    socket.wsClientStream = stream
    socket.buffered = []
    @logger.info 'Accepted connection from {0}:{1}'.format(socket.remoteAddress, socket.remotePort)

    socket.on 'data', (chunk) =>
      @onProxyServerSocketGotData chunk, socket

    socket.on 'error', (e) ->
      @logger.error error

    cbInterval = () ->
      for i in [0..socket.buffered.length-1]
        bufferedChunk = socket.buffered[i]
        try
          socket.wsClientStream.write bufferedChunk
        catch error
          @logger.error error
      socket.buffered = []
    setInterval cbInterval, 1000
    return

  # Perform ping on stream.
  # 
  # @param stream2 [Stream] Control stream.
  #
  doPingCallback: (stream2) ->
    try
      params = {
        time: new Date().toString()
      }
      command = { 
        method: 'ping',
        params: params
      }
      stream2.write JSON.stringify(command)
      console.log 'ping'
    catch error
      @logger.error error
    return

  # Called when WebSocket connection was opened.
  #
  onWebSocketOpen: () ->
    wsClient = @wsClient
    stream2 = wsClient.createStream {
      type : 'control'
    }
    
    cbInterval = () =>
      @doPingCallback stream2
      return


      
    setInterval cbInterval, 1000
    return

  # Run controller.
  #
  run: () ->
    DEFAULT_SERVER_ADDRESS = 'wss://localhost:9000'
    serverAddress = DEFAULT_SERVER_ADDRESS
    if undefined != process.argv[2]
      serverAddress = process.argv[2]
    @nextStreamId = 0
    @logger.info 'Connecting to WebSocket on \'{0}\'.'.format(serverAddress)
    @wsClient = new BinaryClient serverAddress
    @wsClient.on 'open', (stream) =>
      @onWebSocketOpen()
    @wsClient.on 'error', (error) =>
      console.log error
    proxyServer = net.createServer()
    proxyServer.on 'listening', () =>
      @onProxyServerStartsListening proxyServer

    proxyServer.on 'connection', (socket) =>
      @onProxyServerAcceptedConnection socket

    proxyServerPort = 9001
    proxyServer.listen proxyServerPort
    return



BinaryJS = require 'binaryjs'
net = require 'net'
BinaryClient = BinaryJS.BinaryClient
require '../stringFormat.js'
winston = require 'winston'
 
# Create transports for Winston logger.
#
createWinstonTransports = () ->
  transports = [
      new winston.transports.Console()
  ]
  return transports

args = {
  # Logger instance.
  #
  logger : new winston.Logger {
    transports: createWinstonTransports()
  }
}

mainController = new MainController args
mainController.run()
