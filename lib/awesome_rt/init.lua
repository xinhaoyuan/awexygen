require(... .. ".globals")
local lgi = require("lgi")
local awesome = require(... .. ".awesome")
local gtimer = require("gears.timer")
local original_delayed_call = gtimer.delayed_call
function gtimer.delayed_call(...)
    awesome.emit_refresh_when_idle()
    original_delayed_call(...)
end

local wibox = require("wibox")
local original_drawable_new = wibox.drawable.new
function wibox.drawable.new(d, ...)
    local ret = original_drawable_new(d, ...)
    local original_do_redraw = ret._do_redraw
    function ret:_do_redraw()
        local saved_dirty_area = ret._dirty_area
        original_do_redraw(self)
        d:invalidate_region(saved_dirty_area)
    end
    function d.draw_cb(draw_region)
        local saved_dirty_area = ret._dirty_area
        saved_dirty_area:union(draw_region)
        original_do_redraw(ret)
        saved_dirty_area:subtract(draw_region)
        d:invalidate_region(saved_dirty_area)
    end
    local function relayout()
        ret._need_relayout = true
        ret:draw()
    end
    d:connect_signal("property::width", relayout)
    d:connect_signal("property::height", relayout)
    return ret
end

if string.wlen == nil then
    local glib = lgi.GLib
    function string.wlen(s)
        return glib.utf8_strlen(s, s:len())
    end
end

local gsurface = require("gears.surface")
local original_load_silently = gsurface.load_silently
function gsurface.load_silently(s, ...)
    if type(s) == "table" and s.fake_surface then return s end
    return original_load_silently(s, ...)
end

local cairo = lgi.cairo
local original_context = cairo.Context
cairo.Context = setmetatable(
    {}, {
        __index = original_context, __call = function (_self, s, ...)
            if type(s) == "table" and s.fake_surface then
                local cr = s.cr
                assert(cr ~= nil, "Cario context can be retrieved only once in fake surface")
                s.cr = nil
                return cr
            end
            return original_context(s, ...)
        end
    })

local original_type = type
function type(o)
    local t = original_type(o)
    if t == "table" then
        local mt = getmetatable(o)
        if mt and mt.__type then return mt.__type end
    end
    return t
end
