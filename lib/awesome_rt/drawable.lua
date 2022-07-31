local lgi = require("lgi")
local lgi_core = require("lgi.core")
local cairo = lgi.cairo
local awexygen = require("awexygen")
local gobject = require("gears.object")
local gtimer = require("gears.timer")

local drawable = {}
local dummy_surface = cairo.ImageSurface(cairo.Format.ARGB32, 0, 0)

function drawable:geometry(v)
    if v == nil then
        return self.drawin:geometry()
    else
        awexygen.log_warning("Ignored drawable geometry set", debug.traceback())
    end
end

-- DESIGN NOTES
--
-- Drawing is done in two passes: First, draw internally on the
-- dummy_surface, which calculates the dirty area and invalidates the
-- GTK drawing area. Then draw externally using the the cario context
-- from the Gtk drawing area in its draw callback.
--
-- An alternative is to have an actual internal surface for the
-- internal drawing. Then directly paint the internal surface to on
-- the external cairo context when requested. However, I saw
-- excesessive delay when doing this - need to investigate
-- more. Current guess is unoptimized size/format or size mismatch.
--
-- Another alternative is to draw syncrhonously with external
-- requests. However, since layouting happens at the same time as
-- drawing. There might be extra relayouting and redrawing due to
-- internal changes, which may cause flickering from users'
-- perspective.

function drawable:draw(cr)
    if self.draw_cb == nil then return end
    local clip_rects = cr:copy_clip_rectangle_list()
    assert(clip_rects.status == "SUCCESS")
    local rect_ptr = clip_rects.rectangles
    local draw_region = cairo.Region.create()
    for i = 0, clip_rects.num_rectangles - 1  do
        local rect = lgi_core.record.fromarray(rect_ptr, i)
        draw_region:union_rectangle(
            cairo.RectangleInt{
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = rect.height,
            })
    end
    local saved_surface = self.surface
    self.surface = {fake_surface = true, cr = cr}
    self.draw_cb(draw_region)
    self.surface = saved_surface
end

-- Group invalidation requests to reduce the number of redraws.
function drawable:schedule_invalidate()
    if self.scheduled_invalidated then return end
    self.scheduled_invalidated = true
    gtimer.delayed_call(
        function ()
            self.scheduled_invalidated = false
            local region = self.invalidated_region
            for i = 0, region:num_rectangles() - 1 do
                local rect = region:get_rectangle(i)
                self.drawin._drawing_area:queue_draw_area(
                    rect.x, rect.y, rect.width, rect.height)
            end
            self.invalidated_region = cairo.Region.create()
        end)
end

function drawable:invalidate(x, y, w, h)
    self.invalidated_region:union_rectangle(
        cairo.RectangleInt{x = x, y = y, width = w, height = h})
    self:schedule_invalidate()
end

function drawable:invalidate_region(region)
    self.invalidated_region:union(region)
    self:schedule_invalidate()
end

function drawable.refresh(_self)
    -- Ignore
end

local properties_to_sync = {
    "x", "y", "width", "height",
}
local signals_to_sync = {
    "button::press", "butotn::release",
    "mouse::enter", "mouse::leave",
    "mouse::move",
}
function drawable.new(drawin)
    local ret = gobject{
        enable_properties = true,
    }

    ret.drawin = drawin

    for k, v in pairs(drawable) do
        if type(v) == "function" and k ~= "new" then
            ret[k] = v
        end
    end

    for _, prop in ipairs(properties_to_sync) do
        ret["set_"..prop] = function (self, value)
            self.drawin[prop] = value
        end
        ret["get_"..prop] = function (self)
            return self.drawin[prop]
        end
        local signal_name = "property::"..prop
        ret.drawin:connect_signal(
            signal_name,
            function (...)
                ret:emit_signal(signal_name, ...)
            end)
    end
    for _, signal in ipairs(signals_to_sync) do
        ret.drawin:connect_signal(
            signal,
            function(_self, ...)
                ret:emit_signal(signal, ...)
            end)
    end

    -- When not in the LGI redrawing, switch to a dummy surface to
    -- enable layout updating, so that widget code can calculate
    -- layout before presenting the drawable.
    ret.surface = dummy_surface
    ret.invalidated_region = cairo.Region.create()
    -- Accessed by AWM code.
    ret.valid = true

    return ret
end

return setmetatable(drawable, {__call = function (_, ...) return drawable.new(...) end})
