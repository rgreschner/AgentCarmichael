Express = require('express')

# Factory for internal
# express app.
#
class MyOtherExpressApp

  # Public ctor.
  #
  constructor: () ->
    @app = Express()
    @initializeRoutes()

  # Initialize routes.
  #
  initializeRoutes: () ->
  
    @app.get "*", (req, res) =>
      @handleHelloRoute req, res
	  
    return
	
  # Handle hello route.
  #
  handleHelloRoute: (req, res) ->
    console.log 'Handling request.'
    res.write 'Invalid request.'
    res.statusCode = 500
    res.end()
