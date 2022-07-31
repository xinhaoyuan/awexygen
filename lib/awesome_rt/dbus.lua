local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")

local dbus = common.fake_capi_module{name = "dbus"}

function dbus.request_name()
    -- Ignore
end

function dbus.release_name()
    -- Ignore
end

function dbus.add_match()
    -- Ignore
end

function dbus.remove_match()
    -- Ignore
end

return dbus
