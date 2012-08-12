uuid = require('node-uuid')

# Proxy request preapre input node.
#
class ProxyRequestPrepareInputNode extends BaseProcessingNode

  # Public ctor.
  #
  constructor: () ->
    super()

  # Process input arguments.
  #
  # @param inputArgs [Object] Input arguments to process.
  #
  process: (inputArgs) ->

    req = inputArgs.req
    
    id = uuid.v4().toString()

    console.log "Assigned id %s to request.", id

    req.id = id
    parsedUrl = require("url").parse(inputArgs.req.url)
    req.parsedUrl = parsedUrl

    inputArgs.req = req
    console.log "ProxyRequestInputNode finished processing."

    @finishedProcessing inputArgs
    return
