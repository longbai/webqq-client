Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require './httpclient'
Cookie         = require './cookie'
{EventEmitter} = require 'events'
QueryString  = require 'querystring'
Message = require './message'

Hash = require './hash.js'

genClientId = ->
    t1 = Math.round(90*Math.random() + 10)
    [_, t2] = process.hrtime()
    t2 = Math.round(t2/1000)
    return "#{t1}".concat("#{t2%1000000}")

genMessageId = ->
    [_, t] = process.hrtime()
    t = Math.round(t/1000)
    t = (t - t%1000)/1000
    t = Math.round(t)
    t = t%10000 * 10000
    return

class Service
    #
    # Returns nothing.
    constructor:(@account, @cookie, @authInfo) ->
        @events = new EventEmitter
        @stoped = false
        @messageId = genClientId()
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

        cookie2 = Cookie.filterCookieByDomain(@cookie, 's.web2.qq.com')
        cookie3 = Cookie.joinCookie(cookie2)
        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_friend_info2')
            .query(params)
            .header('Cookie', cookie3)
            .get()((err, resp, body) =>
                cb body
        )

    # updateFriends:() ->
    #     result = JSON.parse(data)
    #     if result.retcode != 0
    #         console.log 'invalid data', result.retcode
    #         return

    friendList:(cb) ->
        rValue =
            h: 'hello'
            hash: Hash(@authInfo.uin, @authInfo.ptwebqq)
            vfwebqq: @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        cookie2 = Cookie.filterCookieByDomain(@cookie, 's.web2.qq.com')
        cookie3 = Cookie.joinCookie(cookie2)
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

    discussionGroupList: (cb)->
        params =
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            vfwebqq: @authInfo.vfwebqq
            t: new Date().getTime()

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_discus_list')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                cb body
        )

    discussionGroupInfo: (did, cb)->
        params =
            did: did
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            vfwebqq: @authInfo.vfwebqq
            t: new Date().getTime()

        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/get_discu_info')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                cb body
        )
    accountToUin:(account) ->
        for x in @friends
            if x.account is account
                return x.uin

    groupToUin:(groupId) ->
        for x in @groups
            if x.id is groupId
                return x.guin

    sendToFriend: (msg, callback) ->
        console.log 'send to friend'
        if not msg.to
            console.log 'no to'
            return
        uin = msg.to.uin
        if not uin
            console.log 'uin miss'
            uin = accountToUin msg.to.id
            if not uin
                console.log 'no uin'
                return

        rValue =
            to: uin
            face:600
            msg_id: @messageId++
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            content: msg.message()

        console.log rValue
        params =
            r: JSON.stringify rValue
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid

        console.log params
        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/send_buddy_msg2')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) ->
                console.log 'send friend message', err, body
                callback body
            )

    sendToGroup: (msg, callback) ->
        if not msg.to
            return
        guin = msg.to.guin
        if not guin
            guin = groupToUin msg.to.gid
            if not guin
                return
        rValue =
            group_uin: guin
            msg_id: @messageId++
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            content: msg.message()
        params =
            r: JSON.stringify rValue
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid

        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/send_qun_msg2')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) ->
                console.log 'send group message', err, body
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

    # discussionGroupMember: ->

    poll:(callback)->
        console.log "polling..."
        rValue =
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            key:0
            ids:[]
        params =
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            r: JSON.stringify(rValue)

        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/poll2')
            .header('Cookie', @cookie)
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                console.log 'poll return', body
                @emit 'poll', err, body
        )
    stop: ->
        @emit 'stop'

    run: ->
        @on 'stop', =>
            @stoped = true
            @loop.clearInterval()

        @on 'poll', (err, body)=>
            console.log err, body

        @on 'online', =>
            # @loop = setInterval(=>
            #     if @stoped is false
            #         @poll()
            # , 1000*60
            # )
            @friendInfo((data)->
                console.log 'friendInfo', data
            )
            @friendList((data)->
                console.log 'friendList', data
            )
            @groupList((data)->
                console.log 'groupList', data
            )
            @discussionGroupList((data)->
                console.log 'discussionGroupList', data
            )
            # @groupMember('', (data)->
            #     console.log 'groupMember',data
            # )
            msg = Message.create('hi', {uin:1})
            @sendToFriend(msg, (data)->
                console.log 'send msg', data
            )

        @online()

module.exports = Service
