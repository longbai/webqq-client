Path = require 'path'

QQ = require './src/qq'

module.exports.load = (account, pwd)->
  new QQ(account, pwd)

module.exports.version = ->
    pkg = require Path.join __dirname, 'package.json'
    pkg.version
