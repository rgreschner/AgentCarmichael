EventEmitter = require('events').EventEmitter
Express = require('express')

# Base class for processing.
#
class BaseProcessingNode extends EventEmitter

  # Public ctor.
  #
  constructor: () ->
    @outputNode = null
    # Register internal 'finished' handler.
    @on @EVENT_FINISHED, (outputArgs) =>
      if null == @outputNode
        # Abort if no next output node.
        return
      # Pass outputArgs to output node.
      @outputNode.process outputArgs
      return
    return


  # Set output node.
  # 
  # @param outputNode [Object] Output node.
  #
  setOutputNode: (outputNode) ->
    @outputNode = outputNode
    if null == outputNode
      return
    return

  # Process input arguments.
  #
  # @param inputArgs [Object] Input arguments to process.
  #
  process: (inputArgs) ->
    return

  # Callback called when finished processing.
  #
  # @param outputArgs [Object] Output arguments of processing.
  #
  finishedProcessing: (outputArgs) ->
    @emit @EVENT_FINISHED, outputArgs
    return

# Set static fields.
BaseProcessingNode.prototype.EVENT_FINISHED = 'finished'
