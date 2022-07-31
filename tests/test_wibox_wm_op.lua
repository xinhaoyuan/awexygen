local wibox = require("wibox")
local helper = require("helper")

local b
local signals

require("_runner").run_steps{
    function ()
        b = wibox {
            x = 10,
            y = 20,
            width = 23,
            height = 32,
            visible = true,
        }
        signals = helper.monitor_signals(
            b, {"property::x", "property::y",
                "property::width", "property::height",
                "property::geometry"})
        return b.window ~= nil
    end,
    -- Shows up with the desired geometry with clean event histroy.
    function ()
        local geo = helper.get_x11_geometry(b.window)
        if geo.x == 10 and
            geo.y == 20 and
            geo.width == 23 and
            geo.height == 32 and
            signals.logs["property::x"] == nil and
            signals.logs["property::y"] == nil and
            signals.logs["property::geometry"] == nil and
            signals.logs["property::width"] == nil and
            signals.logs["property::height"] == nil then
            return true
        end
    end,
    -- Responds to move.
    function ()
        signals.logs = {}
        os.execute("xdotool windowmove "..tostring(b.window).." 50, 60")
        return true
    end,
    function ()
        local geo = helper.get_x11_geometry(b.window)
        if geo.x == 50 and
            geo.y == 60 and
            geo.width == 23 and
            geo.height == 32 and
            signals.logs["property::x"] and
            signals.logs["property::y"] and
            signals.logs["property::geometry"] and
            signals.logs["property::width"] == nil and
            signals.logs["property::height"] == nil then
            return true
        end
    end,
    -- Responds to resize (even if the wibox is not resizable).
    function ()
        signals.logs = {}
        os.execute("xdotool windowsize "..tostring(b.window).." 150, 160")
        return true
    end,
    function ()
        local geo = helper.get_x11_geometry(b.window)
        if geo.x == 50 and
            geo.y == 60 and
            geo.width == 150 and
            geo.height == 160 and
            signals.logs["property::x"] == nil and
            signals.logs["property::y"] == nil and
            signals.logs["property::geometry"] and
            signals.logs["property::width"] and
            signals.logs["property::height"] then
            return true
        end
    end
}
