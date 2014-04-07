Fs             = require 'fs'
Log            = require 'log'
Path           = require 'path'
HttpClient     = require 'scoped-http-client'
{EventEmitter} = require 'events'

# to user {id:qq, uin:qqinternal, nick:nickname, markname:markname, type:user}
# to group {id:group id, uin:qqinternal, name:name, type:group}
# to discussion group {id:discussion group id, name:name, type:dgroup}

# from user {id:qq, uin:qqinternal, name:name, nick:nick, markname:markname}, id maybe be absent
# from group {gid:groupId, guin:qqinternal, member:user}, gid may be absent
# from discussion group {did:discussion group}

# parse one item
# buddy message
# [
#     {
#         "poll_type": "message",
#         "value": {
#             "msg_id": 23915,
#             "from_uin": 1,
#             "to_uin": 2,
#             "msg_id2": 564718,
#             "msg_type": 9,
#             "reply_ip": 176884842,
#             "time": 1396855005,
#             "content": [
#                 [
#                     "font",
#                     {
#                         "size": 9,
#                         "color": "000000",
#                         "style": [
#                             0,
#                             0,
#                             0
#                         ],
#                         "name": "Microsoft YaHei"
#                     }
#                 ],
#                 "hi "
#             ]
#         }
#     }
# ]

# group message
# [
#     {
#         "poll_type": "group_message",
#         "value": {
#             "msg_id": 6987,
#             "from_uin": 3055869334,
#             "to_uin": 218,
#             "msg_id2": 146412,
#             "msg_type": 43,
#             "reply_ip": 176886378,
#             "group_code": 37,
#             "send_uin": 1819,
#             "seq": 6,
#             "time": 1396857738,
#             "info_seq": 366,
#             "content": [
#                 [
#                     "font",
#                     {
#                         "size": 9,
#                         "color": "000000",
#                         "style": [
#                             0,
#                             0,
#                             0
#                         ],
#                         "name": "Microsoft YaHei"
#                     }
#                 ],
#                 "群消息 "
#             ]
#         }
#     }
# ]

# dissgus group
# [
#     {
#         "poll_type": "discu_message",
#         "value": {
#             "msg_id": 7003,
#             "from_uin": 10000,
#             "to_uin": 218,
#             "msg_id2": 541681,
#             "msg_type": 42,
#             "reply_ip": 176489029,
#             "did": 3,
#             "send_uin": 1,
#             "seq": 3,
#             "time": 1396858685,
#             "info_seq": 1,
#             "content": [
#                 [
#                     "font",
#                     {
#                         "size": 9,
#                         "color": "000000",
#                         "style": [
#                             0,
#                             0,
#                             0
#                         ],
#                         "name": "Microsoft YaHei"
#                     }
#                 ],
#                 "QQ"
#             ]
#         }
#     }
# ]

contentText = (content)->
    for data in content
        if !Array.isArray(data)
            return data

module.exports.parse = (msg)->
    body = msg.value
    if msg.poll_type is 'message'
        from = {type:'user', uin:body.from_uin}
        text = contentText(body.content)
        return new Message(text, null, from)

    if msg.poll_type is 'group_message'
        from = {type:'group', uin:body.from_uin, talker:body.send_uin}
        text = contentText(body.content)
        return new Message(text, null, from)

    if msg.poll_type is 'discu_message'
        from = {type:'dgroup', uin:body.did, talker:body.send_uin}
        text = contentText(body.content)
        return new Message(text, null, from)

class Message
    #
    # Returns nothing.
    constructor:(@text, @to, @from={}) ->

    message: ->
        JSON.stringify ["#{@text}" , ["font", {"name":"宋体", "size":"10", "style":[0,0,0], "color":"000000" }] ]

module.exports.create = (msg, to) ->
    new Message msg, to
