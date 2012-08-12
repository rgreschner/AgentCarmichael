# Internal express app processing 
# node.
#
class ExpressInternalRequestProcessingNode extends BaseProcessingNode

  # Public ctor.
  #
  constructor: (args) ->
    super()
    if undefined == args
      args = null
    if null != args  
      @app = args.app

  # Process input arguments.
  #
  # @params inputArgs [Object] Input arguments to process.
  #
  process: (inputArgs) ->
    res = inputArgs.res
    req = inputArgs.req
    @app req, res
    outputArgs = {
      req : req,
      res : res
    }
    @finishedProcessing outputArgs
    return
