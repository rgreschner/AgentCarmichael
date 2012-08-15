fs     = require 'fs'
{exec} = require 'child_process'

carmichaelServerSrcFiles  = [
  'BaseStreamHandler', 'ControlStreamHandler', 'BaseProcessingNode', 
  'ExpressInternalRequestProcessingNode', 'HttpProxyStreamHandler',
  'ProxyRequestPrepareInputNode', 'ProxyRequestFilterInputNode',
  'InFlightRequestRepository', 'MainController', 'MyExpressApp', 
  'MyOtherExpressApp', 'WebSocketHandler', 'Program'
]


httpProxyServerSrcFiles = [
  'MainController', 'Program'
]

task 'buildHttpProxyServer', 'Build single application file from source files', ->
  appContents = new Array remaining = httpProxyServerSrcFiles.length
  for file, index in httpProxyServerSrcFiles then do (file, index) ->
    fs.readFile "./src/HttpProxyServer/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0
  # TODO: Create folders.
  process = ->
    fs.writeFile './build/current/HttpProxyServer/app.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --compile -b ./build/current/HttpProxyServer/app.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        fs.unlink './build/current/CarmichaelServer/app.coffee', (err) ->
            console.log 'Done with build.'
 task 'buildCarmichaelServer', 'Build single application file from source files', ->
  appContents = new Array remaining = carmichaelServerSrcFiles.length
  for file, index in carmichaelServerSrcFiles then do (file, index) ->
    fs.readFile "./src/CarmichaelServer/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0
    # TODO: Create folders.
  process = ->
    fs.writeFile './build/current/CarmichaelServer/app.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --compile -b ./build/current/CarmichaelServer/app.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        fs.unlink './build/current/CarmichaelServer/app.coffee', (err) ->
            console.log 'Done with build.'

task 'doc', 'Build documentation', ->
  exec 'codo', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
