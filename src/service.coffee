Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require './httpclient'
Cookie         = require './cookie'
{EventEmitter} = require 'events'
QueryString  = require 'querystring'
Message = require './message'

QQLib = require './qqlib.js'

class Service
    #
    # Returns nothing.
    constructor:(@account, @_cookie, @authInfo) ->
        @events = new EventEmitter
        @stoped = false
        @messageId = QQLib.genMessageId()
        @groups = []
        @dgroups = []
        @friends = []
        if @authInfo is undefined
            @authInfo={}
            @parseAuthInfo()

    cookie:->
        cookie2 = Cookie.filterCookieByDomain(@_cookie, 'web2.qq.com')
        return Cookie.joinCookie(cookie2)

    parseAuthInfo: =>
        @authInfo.clientid = QQLib.genClientId()
        @authInfo.ptwebqq   = @_cookie.filter( (item)->item.match /ptwebqq/ )
                           .pop()
                           .replace /ptwebqq\=(.*?);.*/ , '$1'
        [verifysession] = @_cookie.filter( (item)->item.match /verifysession/ )
        verifysession = verifysession || ''
        verifysession = verifysession.replace /verifysession\=(.*?);.*/ , '$1'

        @authInfo.verifysession = verifysession || ''


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

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_friend_info2')
            .query(params)
            .header('Cookie', @cookie())
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
            hash: QQLib.hash(@authInfo.uin, @authInfo.ptwebqq)
            vfwebqq: @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        data = QueryString.stringify(params)
        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_user_friends2')
            .header('Cookie', @cookie())
            .header('Referer', 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(data)((err, resp, body) =>
                cb err, body
        )

    groupList: (cb)->
        rValue =
            vfwebqq:  @authInfo.vfwebqq
        params =
            r: JSON.stringify(rValue)

        client = HttpClient.create('http://s.web2.qq.com')
            .path('api/get_group_name_list_mask2')
            .header('Cookie', @cookie())
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
            .header('Cookie', @cookie())
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
            .header('Cookie', @cookie())
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
            .header('Cookie', @cookie())
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                cb body
        )
    getUserUin:(user) ->
        for x in @friends
            if user.name && x.name is user.name
                return x.uin
            if user.id && x.id is user.id
                return x.uin

    getGroupUin:(group) ->
        for x in @groups
            if group.name && x.name is group.name
                return x.uin
            if group.id && x.id is group.id
                return x.uin

    getDiscussionGroupUin:(dgroup) ->
        for x in @dgroups
            if dgroup.name && x.name is dgroup.name
                return x.uin

    sendToFriend: (msg, callback) ->
        console.log 'send to friend'
        if not msg.to
            console.log 'no to'
            return
        uin = msg.to.uin
        if not uin
            console.log 'uin miss'
            uin = getUserUin msg.to
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
            .header('Cookie', @cookie())
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) ->
                console.log 'send friend message', err, body
                callback && callback body
            )

    sendToGroup: (msg, callback) ->
        if not msg.to
            return
        guin = msg.to.uin
        if not guin
            guin = getGroupUin msg.to
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
            .header('Cookie', @cookie())
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) ->
                console.log 'send group message', err, body
            )

    sendToDiscussionGroup: (msg, callback) ->
        if not msg.to
            return
        did = msg.to.uin
        if not did
            did = getDiscussionGroupUin msg.to
            if not did
                return

        rValue =
            did: did
            msg_id: @messageId++
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            content: msg.message()
        params =
            r: JSON.stringify rValue
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid

        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/send_discu_msg2')
            .header('Cookie', @cookie())
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) ->
                console.log 'send discussion group message', err, body
            )

    online: (callback)->
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
            .header('Cookie', @cookie())
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
                if ret.retcode is 0
                    console.log 'success'
                    @authInfo.psessionid = ret.result.psessionid
                    @authInfo.uin = ret.result.uin
                    @authInfo.vfwebqq = ret.result.vfwebqq

                callback && callback(err, ret)
            )

    # discussionGroupMember: ->

    poll: ->
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
            .header('Cookie', @cookie())
            .header('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
            .post(QueryString.stringify(params))((err, resp, body) =>
                console.log 'poll return', body
                @emit 'poll', err, body
        )

    handleMessage: (data)->
        if data is undefined
            return


    logout: ->
        @stop()
        params =
            clientid: @authInfo.clientid
            psessionid: @authInfo.psessionid
            ids:''
            t: new Date().getTime()

        client = HttpClient.create('http://d.web2.qq.com')
            .path('channel/logout2')
            .header('Cookie', @cookie())
            .post(QueryString.stringify(params))((err, resp, body) =>
                console.log 'logout return', body
        )

    stop: ->
        @emit 'stop'

    run: ->
        @on 'stop', =>
            @stoped = true
            @loop.clearInterval()

        @on 'poll', (err, body)=>
            ret = JSON.parse body
            if ret.retcode is 0
                @handleMessage(ret.result)

            if ret.retcode is 116
                console.log 'need refrsh ptweb'
                return

            if ret.retcode is 121
                @online()
                return

        @on 'online', =>
            @loop = setInterval(=>
                if @stoped is false
                    @poll()
            , 1000*60
            )

            @friendInfo((data)->
                console.log 'friendInfo', data
            )
            @friendList((err, data)->
                if err isnt null
                    @emit 'error', err
                    return
                ret = JSON.parse(data)

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

            # msg = Message.create('hi', {uin:})
            # @sendToFriend(msg, (data)->
            #     console.log 'send msg', data
            # )
            # msg = Message.create('hiqun', {uin:})
            # @sendToGroup(msg, (data)->
            #     console.log 'send group msg', data
            # )
            # msg = Message.create('hiqun', {uin:})
            # @sendToDiscussionGroup(msg, (data)->
            #     console.log 'send discus group msg', data
            # )

        @online((err, ret)=>
            if err is null and ret.retcode is 0
                @emit 'online'
        )

module.exports = Service
