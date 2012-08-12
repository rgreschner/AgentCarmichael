EventEmitter = require('events').EventEmitter

# Repository for in-flight HTTP requests.
#
class InFlightRequestRepository extends EventEmitter

  # Public ctor.
  #
  constructor: () ->
    super()
    @inFlightRequests = []
	
  # Add new request.
  #
  # @param req [Object] Request to add.
  #
  add: (req) ->
    @inFlightRequests[req.id] = req
    @emit @EVENT_ADDED, req.id
    return
	
  # Remove request.
  #
  # @param req [Object] Request to remove.
  #
  remove: (req) ->
    @inFlightRequests[req.id] = undefined
    @emit @EVENT_REMOVED, req.id
    return
	
  # Find request with id.
  # 
  # @param id [String] Id of request to find.
  # @returns [Object] Found request instance or null.
  #
  find: (id) ->
    req = @inFlightRequests[id]
    return req

# Set static fields.
InFlightRequestRepository.prototype.EVENT_ADDED = 'added'
InFlightRequestRepository.prototype.EVENT_REMOVED = 'removed'
