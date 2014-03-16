Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'

Login = require './login'
Service = require './service'

class QQ
    #
    # Returns nothing.
    constructor:(@account, @password) ->
        @parseVersion()
        @logger = new Log 'info'
        @events = new EventEmitter

    # Public: The version of QQ from npm
    #
    # Returns a String of the version number.
    parseVersion: ->
        pkg = require Path.join __dirname, '..', 'package.json'
        @version = pkg.version

    # Public: A wrapper around the EventEmitter API to make usage
    # semanticly better.
    #
    # event    - The event name.
    # listener - A Function that is called with the event parameter
    #            when event happens.
    #
    # Returns nothing.
    on: (event, args...) ->
        @events.on event, args...

    # Public: A wrapper around the EventEmitter API to make usage
    # semanticly better.
    #
    # event   - The event name.
    # args...  - Arguments emitted by the event
    #
    # Returns nothing.
    emit: (event, args...) ->
        @events.emit event, args...

    run:->
        login = new Login(@account, @password)
        login
            .on 'captcha', (data)=>
                @logger.info 'cap cb', data
                @emit 'captcha', data

            .on 'success', (cookie)=>
                @logger.info 'login success', cookie
                service = new Service(cookie)
                service.run()

                @emit 'login'

            .on 'error', (msg)=>
                @logger.info 'login error', msg
                @emit 'error', msg

        login.run()


module.exports = QQ
