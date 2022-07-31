local awexygen = require("awexygen")
local wibox = require("wibox")

local visible_wibox_collected
local invisible_wibox_collected

local ref_visible_wibox
local ref_visible_wibox_collected
local ref_invisible_wibox
local ref_invisible_wibox_collected

local changing_wibox
local changing_wibox_collected

require("_runner").run_steps{
    function ()
        wibox{visible = true}.gc_guard = awexygen.gc_guard(function () visible_wibox_collected = true end)
        wibox{visible = false}.gc_guard = awexygen.gc_guard(function () invisible_wibox_collected = true end)
        return true
    end,
    function ()
        collectgarbage("collect")
        return invisible_wibox_collected and not visible_wibox_collected
    end,
    -- Test with references
    function ()
        ref_visible_wibox = wibox{visible = true}
        ref_visible_wibox.gc_guard = awexygen.gc_guard(function () ref_visible_wibox_collected = true end)
        ref_invisible_wibox = wibox{visible = false}
        ref_invisible_wibox.gc_guard = awexygen.gc_guard(function () ref_invisible_wibox_collected = true end)
        return true
    end,
    function ()
        collectgarbage("collect")
        return not ref_invisible_wibox_collected and not ref_visible_wibox_collected
    end,
    function ()
        ref_visible_wibox = nil
        ref_invisible_wibox = nil
        return true
    end,
    function ()
        collectgarbage("collect")
        return ref_invisible_wibox_collected and not ref_visible_wibox_collected
    end,
    -- Test with changing visible
    function ()
        changing_wibox = wibox{visible = true}
        changing_wibox.gc_guard = awexygen.gc_guard(function () changing_wibox_collected = true end)
        return true
    end,
    function ()
        collectgarbage("collect")
        return not changing_wibox_collected
    end,
    function ()
        changing_wibox.visible = false
        changing_wibox = nil
        return true
    end,
    function ()
        collectgarbage("collect")
        return changing_wibox_collected
    end,
}
