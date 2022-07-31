local spawn = require("awful.spawn")
local helper = require("helper")

local naughty
local notif

require("_runner").run_steps{
    function ()
        naughty = require("naughty")
        naughty.connect_signal(
            "request::display", function (new_notif)
                notif = new_notif
            end)
        return true
    end,
    -- Needs some round trips to connect the dbus handlers.
    helper.skip(3),
    function ()
        spawn.with_shell("notify-send 'test-message'")
        return true
    end,
    function ()
        if notif ~= nil and
            notif.text == "test-message" then
            return true
        end
    end,
}
