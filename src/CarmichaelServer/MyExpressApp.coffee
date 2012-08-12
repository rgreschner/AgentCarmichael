Express = require('express')

# Factory for internal
# express app.
#
class MyExpressApp

  # Public ctor.
  #
  constructor: () ->
    @app = Express()
    @initializeRoutes()

  # Initialize routes.
  #
  initializeRoutes: () ->
  
    @app.get "/", (req, res) =>
      @handleHelloRoute req, res

    @app.get "/hello", (req, res) =>
      @handleHelloRoute req, res
	  
    return
	
  # Handle hello route.
  #
  handleHelloRoute: (req, res) ->
    console.log "I just came to say hello!"  
    res.write "Hello world!"
    res.end()
