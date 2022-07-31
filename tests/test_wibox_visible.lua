local awful = require("awful")
local wibox = require("wibox")
local helper = require("helper")

local b
local signals

require("_runner").run_steps{
    function ()
        b = awful.popup{
            widget = wibox.container.background(),
            x = 10,
            y = 20,
            width = 200,
            height = 300,
            visible = false
        }
        signals = helper.monitor_signals(
            b, {"property::visible"})
        return true
    end,
    function ()
        b.visible = true
        return true
    end,
    function ()
        if signals.logs["property::visible"] then
            return true
        end
    end,
}
