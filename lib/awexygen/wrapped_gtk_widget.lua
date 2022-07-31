local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local lgi = require("lgi")
local lgi_core = require("lgi.core")
local lgi_ffi = require("lgi.ffi")
local lgi_ti = lgi_ffi.types
local gtk = lgi.Gtk
local gdk = lgi.Gdk
local base = require("wibox.widget.base")
local gtable = require("gears.table")

local offscreen = {}

function offscreen:fit(_context, width, height)
    if self._private.fill_horizontal and self._private.fill_vertical then
        -- Use the available size
    elseif self._private.fill_horizontal then
        local min, natural = self._private.container:get_preferred_height_for_width(width)
        height = self._private.use_natural and natural or min
    elseif self._private.fill_vertical then
        local min, natural = self._private.container:get_preferred_width_for_height(height)
        width = self._private.use_natural and natural or min
    else
        local min, natural = self._private.container:get_preferred_size()
        local result = self._private.use_natural and natural or min
        width, height = result.width, result.height
    end
    return width, height
end

function offscreen:draw(context, cr, width, height)
    if self._private.embedder ~= context.wibox then
        if self._private.active and self._private.embedder then
            self._private.embedder._active_children[self] = nil
            if self._private.embedder._focused_child[1] == self then
                self._private.embedder._focused_child[1] = nil
            end
        end
        self._private.embedder = context.wibox
        gdk.offscreen_window_set_embedder(self._private.container.window, context.wibox._canvas_gdk_window)
    end
    local x, y, _w, _h = base.rect_to_device_geometry(cr, 0, 0, width, height)
    local embedded_geometry = {
        x = x, y = y, width = width, height = height
    }
    self._private.embedded_geometry = embedded_geometry
    if self._private.active then self._private.embedder._active_children[self] = embedded_geometry end
    self._private.container:size_allocate(gtk.Allocation{width = width, height = height})
    local surface = self._private.container:get_surface()
    cr:set_source_surface(surface, 0, 0)
    cr:paint()
end

function offscreen:set_gtk_widget(widget)
    self._private.container.child = widget
    if widget then widget:show() end
end

function offscreen:get_gtk_widget()
    return self._private.container.child[1]
end

function offscreen:get_gdk_window()
    return self._private.container.window
end

function offscreen:set_fill_horizontal(fill)
    if self._private.fill_horizontal ~= fill then
        self._private.fill_horizontal = fill
        self:emit_signal("widget::layout_changed")
    end
end

function offscreen:set_fill_vertical(fill)
    if self._private.fill_vertical ~= fill then
        self._private.fill_vertical = fill
        self:emit_signal("widget::layout_changed")
    end
end

function offscreen:set_use_natural(use)
    if self._private.use_natural ~= use then
        self._private.use_natural = use
        self:emit_signal("widget::layout_changed")
    end
end

function offscreen:get_focus()
    return self._private.focus
end

function offscreen:_set_focus(focus)
    if self._private.focus == focus then return end
    self._private.focus = focus
    local widget = self._private.container.child[1]
    if not widget then return end
    local event = gdk.Event('FOCUS_CHANGE')
    event.focus_change["in"] = focus and 1 or 0
    event.focus_change.window = self._private.container.window
    widget:send_focus_change(event)
    self:emit_signal("property::focus")
end

function offscreen:set_active(active)
    if self._private.active == active then return end
    self._private.active = active
    local widget = self._private.container.child[1]
    local embedder = self._private.embedder
    if not widget or not embedder then return end
    if not active then
        embedder._active_children[self] = nil
    else
        embedder._active_children[self] = self._private.embedded_geometry
    end
end

local gdk_offsceren_window_set_embedder_ptr = lgi_core.callable.new{
    addr = lgi_core.gi.Gdk.resolve["gdk_offscreen_window_set_embedder"],
    ret = {lgi_ti.void},
    lgi_ti.ptr, lgi_ti.ptr,
}
function offscreen:unplug()
    if not self._private.embedder then return end
    self:grab_focus(false)
    self:_set_focus(false)
    self:set_active(false)
    gdk_offsceren_window_set_embedder_ptr(self._private.container.window, nil)
    self._private.embedder = nil
    self:emit_signal("widget::redraw_needed")
end

function offscreen:grab_focus(focus)
    if self._private.focus == focus then return end
    local widget = self._private.container.child[1]
    local embedder = self._private.embedder
    if not widget or not embedder then return end
    if focus then
        -- Focus out any direct widgets.
        embedder._window:set_focus(embedder._drawing_area)
        if embedder._focused_child[1] and embedder._focused_child[1] ~= self then
            embedder._focused_child[1]:_set_focus(false)
        end
        embedder._focused_child[1] = self
    elseif embedder._focused_child[1] == self then
        embedder._focused_child[1] = nil
    end
    self:_set_focus(focus)
end

function offscreen:new()
    local ret = base.make_widget(nil, nil, {enable_properties = true})
    gtable.crush(ret, self, true)

    local weak_widget = setmetatable({ret}, {__mode="v"})
    ret._private.container = gtk.OffscreenWindow{
        on_damage_event = function (_self, _event)
            local widget = weak_widget[1]
            if not widget then return end
            -- TODO try to invalidate the damaged area? not sure the effort would be worth.
            widget:emit_signal("widget::redraw_needed")
        end,
        on_size_allocate = function (_self, _allocation)
            local widget = weak_widget[1]
            if not widget then return end
            widget:emit_signal("widget::layout_changed")
        end,
        can_focus = true,
    }
    ret._private.container:override_background_color(
        0, gdk.RGBA{red = 0, green = 0, blue = 0, alpha = 0})
    ret._private.container:realize()
    function ret._private.container.window.on_to_embedder(_self, x, y)
        local widget = weak_widget[1]
        if not widget then return end
        return x + widget._private.embedded_geometry.x, y + widget._private.embedded_geometry.y
    end
    function ret._private.container.window.on_from_embedder(_self, x, y)
        local widget = weak_widget[1]
        if not widget then return end
        return x - widget._private.embedded_geometry.x, y - widget._private.embedded_geometry.y
    end
    ret._private.container:show()
    ret._private.active = false
    ret._private.use_natural = true
    ret._private.fill_horizontal = false
    ret._private.fill_vertical = false
    ret.__gc_guard = common.gc_guard(
        function ()
            ret._private.container:destroy()
        end)

    return ret
end

setmetatable(offscreen, {__call = function (self, ...) return self:new(...) end})

local direct = {}

function direct:fit(_context, width, height)
    if self._private.fill_horizontal and self._private.fill_vertical then
        -- Use the available size
    elseif self._private.fill_horizontal then
        local min, natural = self._private.container:get_preferred_height_for_width(width)
        height = self._private.use_natural and natural or min
    elseif self._private.fill_vertical then
        local min, natural = self._private.container:get_preferred_width_for_height(height)
        width = self._private.use_natural and natural or min
    else
        local min, natural = self._private.container:get_preferred_size()
        local result = self._private.use_natural and natural or min
        width, height = result.width, result.height
    end
    return width, height
end

function direct:draw(context, cr, width, height)
    if self._private.embedder ~= context.wibox then
        if self._private.embedder then
            self._private.embedder._drawing_area:remove(self._private.container)
        end
        if not context.wibox.gtk_layout then
            common.log_error("wrapped_gtk_widget.direct requires the wibox to have gtk_layout set")
            self._private.embedder = nil
            return
        end
        self._private.embedder = context.wibox
        self._private.embedder._drawing_area:add(self._private.container)
    end
    local x, y, _w, _h = base.rect_to_device_geometry(cr, 0, 0, width, height)
    self._private.container:size_allocate(
        gtk.Allocation{x = x, y = y, width = width, height = height})
end

function direct:set_gtk_widget(widget)
    self._private.container.child = widget
    if widget then widget:show() end
end

function direct:set_fill_horizontal(fill)
    if self._private.fill_horizontal ~= fill then
        self._private.fill_horizontal = fill
        self:emit_signal("widget::layout_changed")
    end
end

function direct:set_fill_vertical(fill)
    if self._private.fill_vertical ~= fill then
        self._private.fill_vertical = fill
        self:emit_signal("widget::layout_changed")
    end
end

function direct:set_use_natural(use)
    if self._private.use_natural ~= use then
        self._private.use_natural = use
        self:emit_signal("widget::layout_changed")
    end
end

function direct:unplug()
    if not self._private.embedder then return end
    self._private.embedder._drawing_area:remove(self._private.container)
    self._private.embedder = nil
end

function direct:new()
    local ret = base.make_widget(nil, nil, {enable_properties = true})
    gtable.crush(ret, self, true)

    local weak_widget = setmetatable({ret}, {__mode="v"})
    ret._private.container = gtk.EventBox{
        on_size_allocate = function (_self, _allocation)
            local widget = weak_widget[1]
            if not widget then return end
            widget:emit_signal("widget::layout_changed")
        end,
        can_focus = true,
    }
    ret._private.container:override_background_color(
        0, gdk.RGBA{red = 0, green = 0, blue = 0, alpha = 0})
    ret._private.container:show()
    ret._private.use_natural = true
    ret._private.fill_horizontal = false
    ret._private.fill_vertical = false

    return ret
end

setmetatable(direct, {__call = function (self, ...) return self:new(...) end})

return {
    offscreen = offscreen,
    direct = direct,
}
