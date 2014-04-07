Path = require 'path'

QQ = require './src/qq'
Message = require './src/message'

module.exports.load = (account, pwd)->
  new QQ(account, pwd)


module.exports.createMessage = Message.create

module.exports.version = ->
    pkg = require Path.join __dirname, 'package.json'
    pkg.version
