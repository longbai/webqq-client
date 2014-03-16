Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'
QueryString  = require 'querystring'

Hash = require './hash.js'

genClientId = ->
    97500000 + parseInt(Math.random() * 99999)

class Service
    #
    # Returns nothing.
    constructor:(@cookie, @authInfo) ->
        @events = new EventEmitter
        if @authInfo is undefined
            @authInfo={}
            @parseAuthInfo()

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

    send:(msg, cb) ->

    onRecieve:(cb) ->

    buddyList:(cb)->
        rValue =
            h: 'hello'
            hash: Hash(@authInfo.uin, @authInfo.ptwebqq)
            vfwebqq: @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_user_friends2')
            .query(params)
            .header('User-Agent','Mozilla/5.0 (X11; Linux x86_64; rv:10.0) Gecko/20100101 Firefox/10.0')
            .header('Cookie', @cookie)
            .get()((err, resp, body) =>
                @cookie = resp.headers['set-cookie']
                console.log body
                cb body
        )

    groupList: (cb)->
        rValue =
            vfwebqq:  @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_group_name_list_mask2')
            .query(params)
            .header('User-Agent','Mozilla/5.0 (X11; Linux x86_64; rv:10.0) Gecko/20100101 Firefox/10.0')
            .header('Cookie', @cookie)
            .get()((err, resp, body) =>
                @cookie = resp.headers['set-cookie']
                console.log body
                cb body
        )

    groupMember: (number, cb)->
        params =
            gcode: number
            cb:'undefined'
            vfwebqq:@authInfo.vfwebqq
            t:new Date().getTime()

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_group_info_ext2')
            .query(params)
            .header('User-Agent','Mozilla/5.0 (X11; Linux x86_64; rv:10.0) Gecko/20100101 Firefox/10.0')
            .header('Cookie', @cookie)
            .get()((err, resp, body) =>
                @cookie = resp.headers['set-cookie']
                console.log body
                cb body
        )
    parseAuthInfo: ->
        @authInfo.clientid = genClientId()
        @authInfo.ptwebqq   = @cookie.filter( (item)->item.match /ptwebqq/ )
                           .pop()
                           .replace /ptwebqq\=(.*?);.*/ , '$1'
        console.log @authInfo

    online: ->
        rValue =
            status: 'online',
            ptwebqq: @authInfo.ptwebqq,
            passwd_sig: '',
            clientid: "#{@authInfo.clientid}",
            psessionid: null

        params =
            clientid: @authInfo.clientid,
            psessionid: 'null',
            r: JSON.stringify(rValue)

        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/login2')
            .header('User-Agent','Mozilla/5.0 (X11; Linux x86_64; rv:10.0) Gecko/20100101 Firefox/10.0')
            .header('Cookie', @cookie)
            .header('Referer', 'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3')
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body)=>
                console.log err
                console.log 'online', body
                if err != null
                    @emit 'error', err
                    return
                if resp.statusCode != 200
                    @emit 'error', 'online fail'

                ret = JSON.parse(body)
                if ret.retcode == 0
                    console.log 'success'
                    @authInfo.psessionid = ret.result.psessionid
                    @authInfo.uin = ret.result.uin
                    @authInfo.vfwebqq = ret.result.vfwebqq
                    @emit 'online'
                else
                    @emit 'error', 'online failed'
            )

    # discussionGroupList: ->

    # discussionGroupMember: ->

    run: ->
        @on 'online', =>
            @buddyList((data)->
                console.log data
            )

        @online()

        #polling every 30 s

module.exports = Service
