class JsonRpcDispatcher extends EventEmitter
  constructor: (args) ->
    @rpcHandlers = args.rpcHandlers
  handleCall: (command) ->
    rpcHandler = @rpcHandlers[command.method]
    if undefined == rpcHandler
      rpcHandler = null
    if null != rpcHandler
      res = {}
      res.id = command.id
      res.end = () =>
        result = {jsonrpc: "2.0"}
        result.result = res.result
        result.id = res.id
        @emit 'handledRequest', result
      req = command
      funcParams = [req, res]
      rpcHandler.apply null, funcParams
    return


# Handler for control stream.
#
class ControlStreamHandler extends BaseStreamHandler

  # Public ctor.
  #
  # @param args [Object] Constructor arguments.
  #
  constructor: (args) ->
    super(args)
    
    @isHandling = false
    
    # Initialize handlers for JSON-RPC methods.
    @rpcHandlers = []
    @rpcHandlers['ping'] = (req, res) =>
      @handleRpcMethodPing req, res
      return
    @rpcHandlers['close'] = (req, res) =>
      @handleRpcMethodClose req, res
      return
      
    @jsonRpcDispatcher = new JsonRpcDispatcher {
      stream : @stream,
      rpcHandlers : @rpcHandlers
    }
    @jsonRpcDispatcher.on 'handledRequest', (result) =>
      console.log 'Handled request: ' + JSON.stringify(result)
      @stream.write JSON.stringify(result)
      return
    
  handleRpcMethodClose: (req, res) =>
    console.log 'Close was requested.'
    @connection.close()

  handleRpcMethodPing: (req, res) =>
    params = req.params
    console.log 'Got ping, sender time is \'{0}\'.'.format(params.time)
    res.end()
    
  # Get handler type as string.
  #
  # @returns [String] Type of handler as string.
  #
  getHandlerType: () ->
    return "control"
	
  handleControlCommand: (command) ->
    @jsonRpcDispatcher.handleCall command
    return
    
  # Start stream handling.
  #
  handle: () ->
    @isHandling = true
    
    cbHandleData = (chunk) =>
      if !@isHandling
        return
      command = JSON.parse chunk
      @handleControlCommand command
      return
    @cbHandleData = cbHandleData
    
    @stream.on 'data', cbHandleData
    
    return
  stop: () ->
    @isHandling = false
    if null != @cbHandleData
      cbHandleData = @cbHandleData
      @stream.removeEventListener 'data', @cbHandleData