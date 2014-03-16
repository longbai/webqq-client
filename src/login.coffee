Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
Util           = require 'util'
HttpClient     = require './httpclient'
{EventEmitter} = require 'events'

Crypto = require 'crypto'

md5 = (str) ->
    md5sum = Crypto.createHash 'md5'
    console.log str
    md5sum.update(str.toString()).digest('hex')

getLoginSig = (callback)->
    params =
        appid:   1003903
        daid:    164
        enable_qlogin:   0
        f_url:   'loginerroralert'
        login_state: 10
        mibao_css:   'm_webqq'
        no_verifyimg:    1
        s_url:   'http://web2.qq.com/loginproxy.html'
        strong_login:    1
        style:   5
        t:   20131202001
        target:  'self'


    client = HttpClient.create('https://ui.ptlogin2.qq.com')
        .path('cgi-bin/login')
        .query(params)
        .get()((err, resp, body) ->
            if err isnt null
                callback({error:err})
                return
            g_login_sig = body.match(/var g_login_sig=encodeURIComponent\(\"(.*?)\"\)/)
            console.log(g_login_sig[1])
            console.log()
            callback({ok:g_login_sig[1]})
        )

captchaCheck = (account, login_sig, callback)->
    console.log account
    params =
        appid:1003903
        js_type:0
        js_ver:10071
        login_sig:login_sig
        r:Math.random
        u1:'http://web2.qq.com/loginproxy.html'
        uin:account

    parseResult = (body) ->
        captchaRet = {}
        [captchaRet.needVerify, captchaRet.code, captchaRet.accountHex] = body.match(/\'(.*?)\'/g).map (i)->
            last = i.length - 2
            i.substr(1 ,last)
        captchaRet.accountHex = captchaRet.accountHex.replace(/\\x/g,'')
        return captchaRet

    # captchaClient = HttpClient.create("http://captcha.qq.com/getimage?aid=1003903&r=#{Math.random()}&uin=#{account}")

    client = HttpClient.create('https://ssl.ptlogin2.qq.com')
        .path('check')
        .query(params)
        .header('Cookie', "chkuin=#{account}")
        .get()((err, resp, body) ->
            if err isnt null
                callback({error:err})
                return
            console.log(body)
            captchaRet = parseResult(body)
            console.log(captchaRet)
            captchaRet.cookie = resp.headers['set-cookie']
            callback(captchaRet)
        )

encryptedPwd = (accountHex, code, password)->
    password = md5(password)

    hex2ascii = (hexstr) ->
        hexstr.match(/\w{2}/g)
              .map (byte_str) ->
                  String.fromCharCode parseInt(byte_str,16)
              .join('')

    ret = md5( hex2ascii(password) + hex2ascii(accountHex) ).toUpperCase() + code.toUpperCase()
    ret = md5( ret ).toUpperCase()


login = (account, password, accountHex, code, cookie, loginSig, callback) ->
    pwdEncrypted = encryptedPwd(accountHex, code, password)
    params =
        u:account
        verifycode:code
        p:pwdEncrypted
        login_sig:loginSig
        action:'4-22-22992'
        aid:1003903
        daid:164
        fp:'loginerroralert'
        from_ui:1
        dumy:''
        g:1
        h:1
        js_type:0
        js_ver:10071
        login2qq:1
        mibao_css:'m_webqq'
        ptlang:2052
        ptredirect:0
        pttype:1
        remember_uin:1
        t:1
        u1:'http://web2.qq.com/loginproxy.html?login2qq=1&webqq_type=10'
        webqq_type:10

    client = HttpClient.create('https://ssl.ptlogin2.qq.com')
        .path('login')
        .query(params)
        .header('Cookie', cookie)
        .get()((err, resp, body) ->
            if err isnt null
                callback({error:err})
                return
            console.log(body)
            loginRet = {}
            [loginRet.errorCode, tmp, loginRet.url, tmp, loginRet.msg, loginRet.name] = body.match(/\'(.*?)\'/g).map (i)->
                last = i.length - 2
                i.substr(1 ,last)
            loginRet.cookie = resp.headers['set-cookie']
            callback  loginRet
        )

getCookie = (url, cookie, callback)->
    client = HttpClient.create(url)
        .header('Cookie', cookie)
        .get()((err, resp, body) ->
            if err isnt null
                callback({error:err})
                return
            console.log('get cookie', body)
            callback({cookie:resp.headers['set-cookie']})
        )

class Login
    constructor:(@account, @password) ->
        @logger = new Log 'info'
        @logger.info @account,@password
        @cookie = []
        @events = new EventEmitter
    run:->
        @logger.info 'hi'
        @on '_code', (code)=>
            login @account, @password, @accountHex, code, @cookie, @loginSig, (loginRet) =>
                console.log loginRet
                @cookie = loginRet.cookie
                if loginRet.errorCode is '0'
                    getCookie(loginRet.url, @cookie, (cookie) =>
                        if cookie.cookie != undefined
                            cookieOk = HttpClient.filterCookie(cookie.cookie)
                            @cookie = HttpClient.updateCookie(@cookie, cookieOk)
                            @cookie = HttpClient.filterCookie(@cookie)
                            @emit 'success', @cookie
                        else
                            @emit 'error', 'get cookie fail'
                    )
                    return
                if loginRet.errorCode is '?'
                    #todo reget captcha
                    @emit 'captcha', 'captcha'
                    return
                @emit 'error', loginRet.msg


        getLoginSig((data) =>
            if data.error isnt undefined
                @emit 'error', data
                return
            @loginSig = data.ok
            captchaCheck(@account, @loginSig, (captchaRet)=>
                @accountHex = captchaRet.accountHex
                @cookie = captchaRet.cookie
                if captchaRet.needVerify == '1'
                    captchaClient.get((err, resp, body)->
                        @emit 'captcha', body
                        Fs.writeFileSync("test.png", body)
                    )
                    return
                if captchaRet.needVerify == '0'
                    @captchaInput captchaRet.code
                    return
                @emit 'error', 'get captcha failed'
            )
        )

    on: (event, args...) ->
        @events.on event, args...

    emit: (event, args...) ->
        @events.emit event, args...

    captchaInput:(code) ->
        @logger.info code
        @emit '_code', code

module.exports = Login
