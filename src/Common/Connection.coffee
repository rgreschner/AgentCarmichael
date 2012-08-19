class Connection extends EventEmitter
  constructor: (myClient) ->
    @id = uuid.v4()
    @handlers = []
    @myClient = myClient
  close: () ->
    @emit 'closing'
    for handler in @handlers
      handler.stop()
    @myClient.close()
    @emit 'closed'