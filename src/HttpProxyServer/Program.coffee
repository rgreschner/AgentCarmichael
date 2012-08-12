BinaryJS = require 'binaryjs'
net = require 'net'
BinaryClient = BinaryJS.BinaryClient
require '../stringFormat.js'
winston = require 'winston'
 
# Create transports for Winston logger.
#
createWinstonTransports = () ->
  transports = [
      new winston.transports.Console()
  ]
  return transports

args = {
  # Logger instance.
  #
  logger : new winston.Logger {
    transports: createWinstonTransports()
  }
}

mainController = new MainController args
mainController.run()
