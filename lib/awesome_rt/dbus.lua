local prefix = (...):match("(.-)[^%.]+$")
local fake_capi = require(prefix.."fake_capi")

local dbus = fake_capi.module{name = "dbus"}

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
