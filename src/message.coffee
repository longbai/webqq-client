Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'

Auth = require './auth'

class Message
    #
    # Returns nothing.
    constructor:(@type, @body, @to, @toType='buddy', @from='', @fromType='buddy') ->

module.exports = Message
