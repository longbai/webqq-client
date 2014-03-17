Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'

# to user {id:qq, uin:qqinternal}
# to group {gid:group id, guin:qqinternal}
# to discussion group {did:discussion group id}

# from user {id:qq, uin:qqinternal, name:name, nick:nick, markname:markname}, id maybe be absent
# from group {gid:groupId, guin:qqinternal, member:user}, gid may be absent
# from discussion group {did:discussion group}

# parse one item
exports.parse = (body)->
    # text =

class Message
    #
    # Returns nothing.
    constructor:(@text, @to, @from={}) ->

    message: ->
        JSON.stringify ["#{@text}" , ["font", {name:"宋体", size:"10", style:[0,0,0], color:"000000" }] ]

module.exports.create = (msg, to) ->
    new Message msg, to
