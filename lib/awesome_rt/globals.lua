local prefix = (...):match("(.-)[^%.]+$")
local fake_capi = require(prefix.."fake_capi")

_G.awesome = require(prefix.."awesome")

_G.root = require(prefix.."root")

_G.tag = fake_capi.module{name = "tag"}

_G.key = require(prefix.."key")

_G.button = require(prefix.."button")

_G.screen = require(prefix.."screen")

_G.drawin = require(prefix.."drawin")

_G.mouse = require(prefix.."mouse")

local client = fake_capi.module{name = "client"}

function client.get()
    return {}
end

_G.client = client

_G.keygrabber = require(prefix.."keygrabber")

_G.mousegrabber = require(prefix.."mousegrabber")

_G.dbus = require(prefix.."dbus")
