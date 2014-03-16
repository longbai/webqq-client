QQ = require './src/qq'

module.exports.load = (account, pwd)->
  new QQ(account, pwd)
