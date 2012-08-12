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
	
  # Start stream handling.
  #
  handle: () ->
    @stream.on 'data', (chunk) ->
      if "ping" == chunk.toString()
        console.log "Got ping"
    return
	