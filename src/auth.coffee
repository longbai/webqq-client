Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'


class Auth
    constructor:(@account, @password) ->
        @logger = new Log 'info'
        @logger.info @account,@password
        @cookie = []
        @session = 'sess'

    run:->
        @logger.info 'hi'
        @captchaCb 'c'
        @successCb 's'
        @errorCb 'e'

    captcha: (callback) ->
        @logger.info 'captcha'
        @captchaCb = callback

    captchaCode:(code) ->
        @logger.info code
        #trigger event

    success: (callback) ->
        @logger.info 'cookie'
        @successCb = callback

    error: (callback) ->
        @logger.info 'error'
        @errorCb = callback

module.exports = Auth
