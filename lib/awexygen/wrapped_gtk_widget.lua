local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local lgi = require("lgi")
local gtk = lgi.Gtk
local gdk = lgi.Gdk
local gobject = lgi.GObject
local base = require("wibox.widget.base")
local gtable = require("gears.table")

local offscreen_widget = gtk.Bin:derive("OffscreenWidget")

function offscreen_widget:do_realize()
    self.realized = true

    -- Create Gdk.Window and bind it with the widget.
    local events = self.events
    events.EXPOSURE_MASK = true
    events.POINTER_MOTION_MASK = true
    events.BUTTON_PRESS_MASK = true
    events.BUTTON_RELEASE_MASK = true
    events.SCROLL_MASK = true
    events.ENTER_NOTIFY_MASK = true
    events.LEAVE_NOTIFY_MASK = true
    -- local events = gdk.EventMask{"ALL_EVENTS_MASK"}

    local attributes = gdk.WindowAttr {
        x = self.allocation.x,
        y = self.allocation.y,
        width = self.allocation.width,
        height = self.allocation.height,
        window_type = 'CHILD',
        event_mask = gdk.EventMask(events),
        visual = self:get_visual(),
        wclass = 'INPUT_OUTPUT',
    }

    local window = gdk.Window.new(self:get_parent_window(), attributes, { 'X', 'Y', 'VISUAL' })
    self:set_window(window)
    window.widget = self

    local bin = self
    function window.on_pick_embedded_child(_self, _x, _y)
        if bin.priv.child and bin.priv.child.visible then
            return bin.priv.offscreen_window
        end
    end

    -- Create and hook up the offscreen window.
    attributes.window_type = 'OFFSCREEN'
    if self.priv.child and self.priv.child.visible then
        local child_allocation = self.priv.child.allocation
        attributes.width = child_allocation.width
        attributes.height = child_allocation.height
    end
    self.priv.offscreen_window = gdk.Window.new(self.root_window, attributes, { 'X', 'Y', 'VISUAL' })
    self.priv.offscreen_window.widget = self
    if self.priv.child then
        self.priv.child:set_parent_window(self.priv.offscreen_window)
    end
    gdk.offscreen_window_set_embedder(self.priv.offscreen_window, window)
    function self.priv.offscreen_window.on_to_embedder(_self, offscreen_x, offscreen_y)
        return offscreen_x, offscreen_y
    end
    function self.priv.offscreen_window.on_from_embedder(_self, parent_x, parent_y)
        return parent_x, parent_y
    end

    -- Set background of the windows according to current context.
    self.style_context:set_background(window)
    self.style_context:set_background(self.priv.offscreen_window)
    self.priv.offscreen_window:show()

    if self.visible then
        window:show()
    end
end

function offscreen_widget:on_map()
    if self.realized then
        self.window:show()
    end
end

function offscreen_widget:do_unrealize()
    -- Destroy offscreen window.
    self.priv.offscreen_window.widget = nil
    self.priv.offscreen_window:destroy()
    self.priv.offscreen_window = nil

    -- Chain to parent.
    offscreen_widget._parent.do_unrealize(self)
end

function offscreen_widget:do_child_type()
    return self.priv.child and gobject.Type.NONE or gtk.Widget
end

function offscreen_widget:do_add(widget)
    if not self.priv.child then
        if self.priv.offscreen_window then
            widget:set_parent_window(self.priv.offscreen_window)
        end
        widget:set_parent(self)
        self.priv.child = widget
    else
        common.log_warning("offscreen_widget cannot have more than one child")
    end
end

function offscreen_widget:do_remove(widget)
    local was_visible = widget.visible
    if self.priv.child == widget then
        widget:unparent()
        self.priv.child = nil
        if was_visible and self.visible then
            self:queue_resize()
        end
    end
end

function offscreen_widget:do_forall(_include_internals, callback)
    if self.priv.child then
        callback(self.priv.child, callback.user_data)
    end
end

function offscreen_widget:do_get_preferred_width()
    if self.priv.child and self.priv.child.visible then
        return self.priv.child:get_preferred_width()
    end
    return 0, 0
end

function offscreen_widget:do_get_preferred_height()
    if self.priv.child and self.priv.child.visible then
        return self.priv.child:get_preferred_height()
    end
    return 0, 0
end

function offscreen_widget:do_size_allocate(allocation)
    self:set_allocation(allocation)

    if self.realized then
        self.window:move_resize(allocation.x, allocation.y, allocation.width, allocation.height)
    end

    if self.priv.child and self.priv.child.visible then
        local child_allocation = gtk.Allocation {
            width = allocation.width,
            height = allocation.height,
        }

        if self.realized then
            self.priv.offscreen_window:resize(allocation.width,
                                              allocation.height)
        end
        self.priv.child:size_allocate(child_allocation)
    end
end

function offscreen_widget:do_damage(event)
    local area = gdk.Rectangle{
        x = event.area.x + self.allocation.x,
        y = event.area.x + self.allocation.y,
        width = event.area.width,
        height = event.area.height,
    }
    self:get_parent_window():invalidate_rect(area, false)
    return true
end

function offscreen_widget._class_init()
    gobject.signal_override_class_closure(
        gobject.signal_lookup('damage-event', gtk.Widget),
        offscreen_widget,
        gobject.Closure(offscreen_widget.do_damage,
                        gtk.Widget.on_damage_event))
end

function offscreen_widget:do_draw(cr)
    if cr:should_draw_window(self.window) then
        -- Skip painting here.
    elseif cr:should_draw_window(self.priv.offscreen_window) then
        gtk.render_background(self.style_context, cr, 0, 0,
                              self.priv.offscreen_window:get_width(),
                              self.priv.offscreen_window:get_height())
        if self.priv.child then
            self:propagate_draw(self.priv.child, cr)
        end
    end

    return false
end

local gtk_widget = {}

function gtk_widget:fit(_context, width, height)
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

function gtk_widget:draw(context, cr, width, height)
    if self._private.embedder ~= context.wibox then
        if self._private.embedder then
            self._private.embedder._drawing_area:remove(self._private.container)
        end
        self._private.embedder = context.wibox
        self._private.embedder._drawing_area:add(self._private.container)
    end
    local x, y, _w, _h = base.rect_to_device_geometry(cr, 0, 0, width, height)
    self._private.container:size_allocate(
        gtk.Allocation{x = x, y = y, width = width, height = height})
    if common.is_compositing then
        cr:set_source_window(self._private.container.window, 0, 0)
        cr:set_operator("OVER")
        cr:paint()
    else
        cr:set_source_window(self._private.container.priv.offscreen_window, 0, 0)
        cr:set_operator("OVER")
        cr:paint()
    end
end

function gtk_widget:set_wrapped(widget)
    self._private.container.child = widget
    if widget then widget:show() end
end

function gtk_widget:set_fill_horizontal(fill)
    if self._private.fill_horizontal ~= fill then
        self._private.fill_horizontal = fill
        self:emit_signal("widget::layout_changed")
    end
end

function gtk_widget:set_fill_vertical(fill)
    if self._private.fill_vertical ~= fill then
        self._private.fill_vertical = fill
        self:emit_signal("widget::layout_changed")
    end
end

function gtk_widget:set_use_natural(use)
    if self._private.use_natural ~= use then
        self._private.use_natural = use
        self:emit_signal("widget::layout_changed")
    end
end

function gtk_widget:unplug()
    if not self._private.embedder then return end
    self._private.embedder._drawing_area:remove(self._private.container)
    self._private.embedder = nil
end

function gtk_widget.new()
    local ret = base.make_widget(nil, nil, {enable_properties = true})
    gtable.crush(ret, gtk_widget, true)

    local weak_widget = setmetatable({ret}, {__mode="v"})
    if common.is_compositing then
        ret._private.container = gtk.EventBox{
            on_size_allocate = function (_self, _allocation)
                local widget = weak_widget[1]
                if not widget then return end
                widget:emit_signal("widget::layout_changed")
            end,
            can_focus = true,
        }
        ret._private.container:set_visual(gdk.Screen.get_default():get_rgba_visual())
        ret._private.container:override_background_color(
            0, gdk.RGBA{red = 0, green = 0, blue = 0, alpha = 0})
    else
        ret._private.container = offscreen_widget{
            on_size_allocate = function (_self, _allocation)
                local widget = weak_widget[1]
                if not widget then return end
                widget:emit_signal("widget::layout_changed")
            end,
            can_focus = true,
        }
    end
    ret._private.container:show()
    ret._private.use_natural = true
    ret._private.fill_horizontal = false
    ret._private.fill_vertical = false

    return ret
end

return setmetatable(gtk_widget, {__call = function (_self, ...) return gtk_widget.new(...) end})
