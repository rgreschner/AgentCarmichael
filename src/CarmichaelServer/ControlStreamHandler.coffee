# Handler for control stream.
#
class ControlStreamHandler extends BaseStreamHandler

  # Public ctor.
  #
  # @param args [Object] Constructor arguments.
  #
  constructor: (args) ->
    super(args)
	
  # Get handler type as string.
  #
  # @returns [String] Type of handler as string.
  #
  getHandlerType: () ->
    return "control"
	
  handleControlCommand: (command) ->
    if "ping" == command.method
      console.log 'Got ping, sender time is \'{0}\'.'.format(command.params.time)
    return
	
  # Start stream handling.
  #
  handle: () ->
    @stream.on 'data', (chunk) =>
      command = JSON.parse chunk
      @handleControlCommand command
    return
	