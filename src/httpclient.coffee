HttpClient     = require 'scoped-http-client'
Url  = require 'url'

exports.create = (url, options) ->
    u = Url.parse url
    referer = ''
    if u.host is 's.web2.qq.com'
        referer = 'http://s.web2.qq.com/proxy.html?v=20110412001&callback=1&id=3'
    else if u.host is 'd.web2.qq.com'
        referer = 'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=2'

    client = HttpClient.create(url, options)
        .header('User-Agent','Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:27.0) Gecko/20100101 Firefox/27.0')
        .header('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
    if referer isnt ''
        client.header('Referer', referer)
    return client
