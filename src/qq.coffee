Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'

Auth = require './auth'

class QQ
    #
    # name        - A String of the qq name, defaults to QQ.
    #
    # Returns nothing.
    constructor:(@name='QQ', @account, @password) ->
        @parseVersion()
        @logger = new Log 'info'

    # Public: The version of QQ from npm
    #
    # Returns a String of the version number.
    parseVersion: ->
        pkg = require Path.join __dirname, '..', 'package.json'
        @version = pkg.version

    run:->
        auth = new Auth(@account, @password)
        auth.captcha (data)->
            @logger.info 'cap cb', data

        auth.success (session)->
            @logger.info 'suc cb', session

        auth.error (msg)->
            @logger.info 'err cb', msg

        auth.run()

module.exports = QQ
