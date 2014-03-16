Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require './httpclient'
{EventEmitter} = require 'events'
QueryString  = require 'querystring'

Hash = require './hash.js'

genClientId = ->
    [t1, t2] = process.hrtime()
    t2 = '' + ((t2/1000)%1000000)
    t1 = Math.round(90*Math.random()) + 10
    t1 = '' + t1
    return t1.concat(t2)

class Service
    #
    # Returns nothing.
    constructor:(@account, @cookie, @authInfo) ->
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

    friendInfo:(cb) =>
        params =
            tuin: @account
            verifysession:@authInfo.verifysession
            vfwebqq:@authInfo.vfwebqq
            t:new Date().getTime()

        cookie2 = HttpClient.filterCookieByDomain(@cookie, 's.web2.qq.com')
        cookie3 = HttpClient.joinCookie(cookie2)
        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_friend_info2')
            .query(params)
            .header('Cookie', cookie3)
            .get()((err, resp, body) =>
                cb body
        )

    buddyList:(cb) =>
        rValue =
            h: 'hello'
            hash: Hash(@authInfo.uin, @authInfo.ptwebqq)
            vfwebqq: @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        cookie2 = HttpClient.filterCookieByDomain(@cookie, 's.web2.qq.com')
        cookie3 = HttpClient.joinCookie(cookie2)
        data = QueryString.stringify(params)
        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_user_friends2')
            .header('Cookie', cookie3)
            .header('Referer', 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(data)((err, resp, body) =>
                cb body
        )

    groupList: (cb)->
        rValue =
            vfwebqq:  @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_group_name_list_mask2')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
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
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                cb body
        )
    parseAuthInfo: =>
        @authInfo.clientid = genClientId()
        @authInfo.ptwebqq   = @cookie.filter( (item)->item.match /ptwebqq/ )
                           .pop()
                           .replace /ptwebqq\=(.*?);.*/ , '$1'
        [verifysession] = @cookie.filter( (item)->item.match /verifysession/ )
        verifysession = verifysession || ''
        verifysession = verifysession.replace /verifysession\=(.*?);.*/ , '$1'

        @authInfo.verifysession = verifysession || ''

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
            .header('Cookie', @cookie)
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

    discussionGroupList: (cb)->
        params =
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            vfwebqq: @authInfo.vfwebqq
            t: new Date().getTime()

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_group_name_list_mask2')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                cb body
        )

    # discussionGroupMember: ->

    run: ->
        @on 'online', =>
            @friendInfo((data)->
                console.log 'friendInfo', data
            )
            @buddyList((data)->
                console.log 'buddyList', data
            )
            @groupList((data)->
                console.log 'groupList', data
            )
            @discussionGroupList((data)->
                console.log 'discussionGroupList', data
            )
            @groupMember('', (data)->
                console.log 'groupMember',data
            )

        @online()

        #polling every 30 s

module.exports = Service
