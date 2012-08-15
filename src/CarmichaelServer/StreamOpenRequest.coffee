class StreamOpenRequest
  constructor: (args) ->
    @connectionId = args.connectionId
    @name = args.name
    @passphrase = uuid.v4()
    @isUsed = false
