QQ = require './src/qq'

# module.exports = {
#   QQ
# }

module.exports.load = ->
  new QQ('QQ', '123', 'pwd')
