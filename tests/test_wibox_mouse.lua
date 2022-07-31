local helper = require("helper")
local wibox = require("wibox")

local b
local signals

require("_runner").run_steps{
    function ()
        os.execute("xdotool mousemove 20 20")
        b = wibox {
            x = 50,
            y = 50,
            width = 200,
            height = 200,
        }
        signals = helper.monitor_signals(
            b, {"mouse::enter", "mouse::leave", "mouse::move"})
        b.visible = true
        return true
    end,
    -- No false signals sent.
    function ()
        local geo = helper.get_x11_geometry(b.window)
        if geo.x == 50 and geo.y == 50 and
            geo.width == 200 and geo.height == 200 and
            signals.logs["mouse::enter"] == nil and
            signals.logs["mouse::leave"] == nil and
            signals.logs["mouse::move"] == nil then
            return true
        end
    end,
    -- Expected signals are sent.
    function ()
        os.execute("xdotool mousemove 100 100")
        return true
    end,
    function ()
        if signals.logs["mouse::enter"] and
            signals.logs["mouse::leave"] == nil and
            signals.logs["mouse::move"] then
            return true
        end
    end,
    function ()
        os.execute("xdotool mousemove 20 20")
        return true
    end,
    function ()
        if signals.logs["mouse::leave"] then
            return true
        end
    end,
}
