Info = require '../src/info'
assert = require 'assert'

friendsData = {
        "friends": [
            {
                "flag": 0,
                "uin": 3971,
                "categories": 0
            },
            {
                "flag": 0,
                "uin": 1525,
                "categories": 0
            }
        ],
        "marknames": [],
        "categories": [],
        "vipinfo": [
            {
                "vip_level": 0,
                "u": 3971,
                "is_vip": 0
            },
            {
                "vip_level": 0,
                "u": 1525,
                "is_vip": 0
            }
        ],
        "info": [
            {
                "face": 291,
                "flag": 2894,
                "nick": "K",
                "uin": 3971
            },
            {
                "face": 594,
                "flag": 1310,
                "nick": "火凤凰",
                "uin": 1525
            }
        ]
    }

friends = Info.parseFriends(friendsData)
assert.equal friends.length, 2
assert.equal friends[0].nick, 'K'
assert.equal friends[1].nick, '火凤凰'
