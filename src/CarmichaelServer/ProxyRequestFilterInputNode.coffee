# Proxy request filter node.
#
class ProxyRequestFilterInputNode extends BaseProcessingNode

  # Public ctor.
  #
  constructor: () ->
    super()

  # Process input arguments.
  #
  # @param inputArgs [Object] Input arguments to process.
  #
  process: (inputArgs) ->
    console.log "Filtering..."
    @finishedProcessing inputArgs
    return
