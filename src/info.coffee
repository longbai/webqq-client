# {
#     "retcode": 0,
#     "result": {
#         "friends": [
#             {
#                 "flag": 0,
#                 "uin": 3971,
#                 "categories": 0
#             },
#             {
#                 "flag": 0,
#                 "uin": 1525,
#                 "categories": 0
#             }
#         ],
#         "marknames": [],
#         "categories": [],
#         "vipinfo": [
#             {
#                 "vip_level": 0,
#                 "u": 3971,
#                 "is_vip": 0
#             },
#             {
#                 "vip_level": 0,
#                 "u": 1525,
#                 "is_vip": 0
#             }
#         ],
#         "info": [
#             {
#                 "face": 291,
#                 "flag": 2894,
#                 "nick": "K",
#                 "uin": 3971
#             },
#             {
#                 "face": 594,
#                 "flag": 1310,
#                 "nick": "火凤凰",
#                 "uin": 1525
#             }
#         ]
#     }
# }

# friend {
#     face, nick, uin, account, flag,categories
# }

module.exports.parseFriends = (data)->
    friends = data.friends
    for friend in friends
        for info in data.info
            if info.uin is friend.uin
                friend.face = info.face
                friend.nick = info.nick
                friend.flag = info.flag
    return friends

# {
#     "retcode": 0,
#     "result": {
#         "gmasklist": [],
#         "gnamelist": [
#             {
#                 "flag": 1677,
#                 "name": "test",
#                 "gid": 3055,
#                 "code": 3790
#             }
#         ],
#         "gmarklist": []
#     }
# }

# group {
#     name, gid, account, flag, code
# }

module.exports.parseGroups = (data)->
    return data.gnamelist

# {
#     "retcode": 0,
#     "result": {
#         "dnamelist": [
#             {
#                 "name": "test2",
#                 "did": 3604191978
#             }
#         ]
#     }
# }

# dgroup {
#     name, did
# }
module.exports.parseDisscussGroups = (data)->
    return data.dnamelist
