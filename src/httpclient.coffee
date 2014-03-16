HttpClient     = require 'scoped-http-client'

exports.create = (url, options) ->
    HttpClient.create(url, options)
    .header('User-Agent','Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:27.0) Gecko/20100101 Firefox/27.0')
    .header('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
    .header('Referer', 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3')
    .header('Connection', 'keep-alive')

parsePair = (item)->
    eq_idx = item.indexOf('=')

    # skip things that don't look like key=value
    if eq_idx < 0
        return false;

    key = item.substr(0, eq_idx).trim()
    val = item.substr(++eq_idx, item.length).trim();

    # quoted values
    if  '"' is val[0]
        val = val.slice(1, -1)
    return [key, val]

validCookieItem = (item)->
    [key, val] = parsePair(item)
    if val is ''
        return false
    return true

exports.filterCookie = (cookie) ->
    cookie.filter((item)->
        t = item.split(';')
        if validCookieItem(t[0])
            return item
    )

exports.updateCookie = (cookieOld, cookieNew) ->
    old = cookieOld.filter((item)->
        eq_idx = item.indexOf('=')
        if eq_idx <= 0
            return
        key = item.substr(0, eq_idx).trim()
        replaced = false
        for it in cookieNew
            if it.indexOf(key) is 0
                replaced = true
                break

        if !replaced
            return item
    )
    old.concat(cookieNew)

exports.filterCookieByDomain = (cookie, domainSrc)->
    cookie.filter((item)->
        t = item.split(';')
        [domainItem] = t.filter((x)->
            if x.indexOf('DOMAIN') >= 0
                return x
        )
        if domainItem is undefined
            return

        [key, val] = parsePair(domainItem)
        if domainSrc.indexOf(val) >= 0
            return item
    )

exports.joinCookie = (cookie) ->
    m = cookie.map((item)->
        t = item.split(';')
        return t[0]
    )
    m.join('; ')
