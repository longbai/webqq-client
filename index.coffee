QQ = require './src/qq'

module.exports = {
  QQ
}

module.exports.load = ->
  new QQ()
