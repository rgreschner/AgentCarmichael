EventEmitter = require('events').EventEmitter

# Base class for stream handlers.
#
class BaseStreamHandler extends EventEmitter

  # Public ctor.
  #
  # @param args [Object] Constructor arguments.
  #
  constructor: (args) ->
    super()
	
    # Assign fields.
    @stream = args.stream
    @meta = args.meta
    @logger = args.logger

    # Get handler type as string.
    @handlerType = @getHandlerType()

  # Get handler type as string.
  #
  # @returns [String] Type of handler as string.
  #
  getHandlerType: () ->
    return undefined

  # Start stream handling.
  #
  handle: () ->
    throw new Error 'Not implemented.'
    return
