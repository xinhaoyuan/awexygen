local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local lgi = require("lgi")
local cairo = lgi.cairo
local gdk = lgi.Gdk
local ok, gdkx11 = pcall(lgi.require, "GdkX11")
if not ok then gdkx11 = nil end
local gtk = lgi.Gtk
local screen = require(prefix.."screen")
local drawable = require(prefix.."drawable")
local keygrabber = require(prefix.."keygrabber")
local mousegrabber = require(prefix.."mousegrabber")
local awexygen = require("awexygen")

local drawin = common.fake_capi_module{
    name = "drawin",
    call = function (self, ...)
        return self.new(...)
    end,
    signal_type = "object",
}

local function resize_drawin(d, w, h)
    d._window:set_size_request(w, h)
end

function drawin:get_visible()
    return self._window.visible
end

function drawin:set_visible(v)
    self._window.visible = v
end

function drawin:get_x()
    return self._geometry.x
end

function drawin:set_x(x)
    x = math.max(x, 0)
    if self._geometry.x ~= x then
        self._geometry.x = x
        self._window:move(x, self._geometry.y)
        self:emit_signal("property::x", x)
        self:emit_signal("property::geometry")
    end
end

function drawin:get_y()
    return self._geometry.y
end

function drawin:set_y(y)
    y = math.max(y, 0)
    if self._geometry.y ~= y then
        self._geometry.y = y
        self._window:move(self._geometry.x, y)
        self:emit_signal("property::y", y)
        self:emit_signal("property::geometry")
    end
end

function drawin:get_width()
    return self._geometry.width
end

function drawin:set_width(w)
    w = math.max(w, 1)
    if self._geometry.width ~= w then
        self._geometry.width = w
        resize_drawin(self, w, self._geometry.height)
        self:emit_signal("property::width", w)
        self:emit_signal("property::geometry")
    end
end

function drawin:get_height()
    return self._geometry.height
end

function drawin:set_height(h)
    h = math.max(h, 1)
    if self._geometry.height ~= h then
        self._geometry.height = h
        resize_drawin(self, self._geometry.width, h)
        self:emit_signal("property::height", h)
        self:emit_signal("property::geometry")
    end
end

function drawin:geometry(geo)
    if geo == nil then
        geo = self._geometry
        return {x = geo.x, y = geo.y, width = geo.width, height = geo.height}
    else
        geo.x = math.max(geo.x, 0)
        geo.y = math.max(geo.y, 0)
        geo.width = math.max(geo.width, 1)
        geo.height = math.max(geo.height, 1)
        self._window:move(geo.x, geo.y)
        resize_drawin(self, geo.width, geo.height)
        self:_set_geometry(geo)
    end
end

function drawin:get_window()
    -- TODO check why gdkx11.X11Window.is_type_of doesn't work.
    if gdkx11 and self._window.window._type == gdkx11.X11Window then
        return self._window.window:get_xid()
    else
        return nil
    end
end

local geometry_keys = {"x", "y", "width", "height"}
function drawin:_set_geometry(geo)
    local changed = false
    for _, key in ipairs(geometry_keys) do
        if geo[key] and self._geometry[key] ~= geo[key] then
            changed = true
            self:emit_signal("property::"..key, geo[key])
            self._geometry[key] = geo[key]
        end
    end
    if changed then
        self:emit_signal("property::geometry")
    end
end

function drawin:get_resizable()
    return self._window.resizable
end

function drawin:set_resizable(r)
    self._window.resizable = r
end

function drawin.get__border_width()
    return 0
end

function drawin.set__border_width()
    -- Ignore
end

function drawin.get__border_color()
    return "#000000"
end

function drawin.set__border_color()
    -- Ignore
end

function drawin.get__opacity_width()
    return 1
end

function drawin.set__opacity_width()
    -- Ignore
end

function drawin:get_shape_clip()
    return self._shape_clip
end

function drawin:set_shape_clip(native_img_surface)
    self._shape_clip_region = native_img_surface and
        gdk.cairo_region_create_from_surface(cairo.Surface(native_img_surface))
    self._shape_clip = native_img_surface
    self:update_shape()
end

function drawin:get_shape_bounding()
    return self._shape_bounding
end

function drawin:set_shape_bounding(native_img_surface)
    self._shape_bounding_region = native_img_surface and
        gdk.cairo_region_create_from_surface(cairo.Surface(native_img_surface))
    self._shape_bounding = native_img_surface
    self:update_shape()
end

function drawin:update_shape()
    if self._shape_bounding_region == nil then
        self._window:shape_combine_region(self._shape_clip_region)
    elseif self._shape_clip_region == nil then
        self._window:shape_combine_region(self._shape_bounding_region)
    else
        local region = self._shape_bounding_region:copy()
        region:intersect(self._shape_clip_region)
        self._window:shape_combine_region(region)
    end
end

function drawin:get_shape_input()
    return self._shape_input
end

function drawin:set_shape_input(native_img_surface)
    self._shape_input = native_img_surface
    self._window:input_shape_combine_region(
        native_img_surface and
        gdk.cairo_region_create_from_surface(cairo.Surface(native_img_surface)))
end

local _awful
function drawin:update_window_properties_by_struts()
    local xid = self:get_window()
    if xid then
        -- The current approximation could go wrong in multi-monitor settings.
        -- We could do better but the fundamental limitation is still there.
        local s = self._struts
        -- local dgeo = {
        --     width = screen._display:get_default_screen().width(),
        --     height = screen._display:get_default_screen().height(),
        -- }
        local mgeo = screen._display:get_monitor_at_point(self._geometry.x, self._geometry.y).geometry
        -- I saw other bars doing the commented way, but only no adjustment can work in AwesomeWM.
        local ms = {
            left = 0, --mgeo.x,
            right = 0, --dgeo.width - mgeo.x - mgeo.width,
            top = 0, -- mgeo.y,
            bottom = 0, --dgeo.height - mgeo.y - mgeo.height,
        }
        -- This is a very hacky way of setting the STRUT x properties
        -- since there is no LGI binding for it.
        if _awful == nil then
            _awful = require("awful")
        end
        _awful.spawn.easy_async(
            {
                "xprop", "-id", tostring(xid),
                "-f", "_NET_WM_STRUT_PARTIAL", "32c",
                "-set", "_NET_WM_STRUT_PARTIAL",
                string.format(
                    "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",
                    s.left > 0 and ms.left + s.left or 0,
                    s.right > 0 and ms.right + s.right or 0,
                    s.top > 0 and ms.top + s.top or 0,
                    s.bottom > 0 and ms.bottom + s.bottom or 0,
                    s.left_start_y or (s.left > 0 and mgeo.y or 0),
                    s.left_end_y or (s.left > 0 and mgeo.y + mgeo.height - 1 or 0),
                    s.right_start_y or (s.right > 0 and mgeo.y or 0),
                    s.right_end_y or (s.right > 0 and mgeo.y + mgeo.height - 1 or 0),
                    s.top_start_x or (s.top > 0 and mgeo.x or 0),
                    s.top_end_x or (s.top > 0 and mgeo.x + mgeo.width - 1 or 0),
                    s.bottom_start_x or (s.bottom > 0 and mgeo.x or 0),
                    s.bottom_end_x or (s.bottom > 0 and mgeo.x + mgeo.width - 1 or 0)
                ),
            },
            function (stdout, stderr, reason, code)
                if reason ~= "exit" or code ~= 0 then
                    awexygen.log_error("Failure setting _NET_WM_STRUT_PARTIAL xproperty:", stdout, stderr, reason, code)
                end
            end
        )
        _awful.spawn.easy_async(
            {
                "xprop", "-id", tostring(xid),
                "-f", "_NET_WM_STRUT", "32c",
                "-set", "_NET_WM_STRUT",
                string.format(
                    "%d,%d,%d,%d",
                    s.left > 0 and ms.left + s.left or 0,
                    s.right > 0 and ms.right + s.right or 0,
                    s.top > 0 and ms.top + s.top or 0,
                    s.bottom > 0 and ms.bottom + s.bottom or 0),
            },
            function (stdout, stderr, reason, code)
                if reason ~= "exit" or code ~= 0 then
                    awexygen.log_error("Failure setting _NET_WM_STRUT xproperty:", stdout, stderr, reason, code)
                end
            end
        )
    end
end

function drawin:struts(s)
    if s  then
        self._struts = s
        self:update_window_properties_by_struts()
        self:emit_signal("property::struts")
    end
    return self._struts
end

function drawin:_buttons(b)
    if b then
        self._private.drawin_buttons = b
        self:emit_signal("property::buttons")
    end
    return self._private.drawin_buttons
end

function drawin:process_buttons(event, x, y, button, mods, gdk_mods)
    for k, _v in pairs(gdk_mods) do
        if common.mod_mask_to_awesome_mod[k] == nil then
            gdk_mods[k] = nil
        end
    end
    local mods_mask = gdk.ModifierType(gdk_mods)
    if self._private.drawin_buttons == nil then return end
    for _, b in ipairs(self._private.drawin_buttons) do
        if (b.button == nil or b.button == button) and
            (b.gdk_modifiers == nil or b.gdk_modifiers == mods_mask) then
            b:emit_signal(event, x, y, button, mods)
        end
    end
end

local gdk_window_to_drawin = setmetatable({}, {__mode = "kv"})
function drawin.find_drawin_by_gdk_window(gdk_window)
    return gdk_window_to_drawin[gdk_window]
end

function drawin.new(args)
    args = args or {}
    local width = args.width and math.max(1, args.width) or 400
    local height = args.height and math.max(1, args.height) or 400
    local type_hint = gdk.WindowTypeHint[string.upper(args.type or "normal")]
    local ret = common.fake_capi_object{class = drawin}
    ret._geometry = {x = args.x or 0, y = args.y or 0, width = width, height = height}
    local icon_pixbuf = args.icon_name == nil and (args.icon_pixbuf or awexygen.get_icon_pixbuf()) or nil
    local weak_drawin = setmetatable({ret}, {__mode = "v"})
    ret._window = gtk.Window{
        title = args.title or "Awexygen",
        icon_name = args.icon_name,
        icon = icon_pixbuf,
        resizable = args.resizable ~= nil and args.resizable or false,
        type_hint = type_hint,
        decorated = args.decorated ~= nil and args.decorated or false,
        on_configure_event = function (_self, event)
            local d = weak_drawin[1]
            if not d then return end
            local c = event.configure
            -- We cannot set the size in `c` because the actual size
            -- is in size allocation. But allocation may not be
            -- updated yet.
            d:_set_geometry{x = c.x, y = c.y}
        end,
        on_delete_event = function (self, _event)
            self:hide()
            return true
        end,
        on_hide = function (_self)
            local d = weak_drawin[1]
            if not d then return end
            -- AwesomeWM drawin does not emit the value.
            d:emit_signal("property::visible")
        end,
        on_show = function (_self)
            local d = weak_drawin[1]
            if not d then return end
            -- Ditto
            d:emit_signal("property::visible")
        end,
    }
    ret._window:set_visual(ret._window.screen:get_rgba_visual())
    ret._window:override_background_color(0, gdk.RGBA{red = 0, green = 0, blue = 0, alpha = 0})
    if args.ontop ~= nil then
        ret._window:set_keep_above(args.ontop)
    end

    ret._drawing_area = gtk[args.gtk_layout and "Layout" or "DrawingArea"]{
        on_size_allocate = function (_self, alloc)
            local d = weak_drawin[1]
            if not d then return end
            d:_set_geometry{width = alloc.width, height = alloc.height}
        end,
        on_draw = function (_self, cr)
            local d = weak_drawin[1]
            if not d then return end
            d.drawable:draw(cr)
        end,
        on_button_press_event = function (_self, event)
            if event.type ~= "BUTTON_PRESS" then return end
            local d = weak_drawin[1]
            if not d then return end
            local state = event.state
            if mousegrabber.callback then
                mousegrabber.handle(
                    {
                        x = d._geometry.x + event.x,
                        y = d._geometry.y + event.y,
                        buttons = common.gdk_modifiers_to_awesome_buttons(state),
                    })
            else
                local mods = common.gdk_modifiers_to_awesome_modifiers(state)
                d:emit_signal("button::press", event.x, event.y, event.button, mods)
                d:process_buttons("press", event.x, event.y, event.button, mods, state)
            end
        end,
        on_button_release_event = function (_self, event)
            local d = weak_drawin[1]
            if not d then return end
            local state = event.state
            if mousegrabber.callback then
                mousegrabber.handle(
                    {
                        x = d._geometry.x + event.x,
                        y = d._geometry.y + event.y,
                        buttons = common.gdk_modifiers_to_awesome_buttons(state),
                    })
            else
                local mods = common.gdk_modifiers_to_awesome_modifiers(state)
                d:emit_signal("button::release", event.x, event.y, event.button, mods)
                d:process_buttons("release", event.x, event.y, event.button, mods, state)
            end
        end,
        on_scroll_event = function (_self, event)
            if event.device.input_source ~= "MOUSE" then
                return
            end
            local d = weak_drawin[1]
            if not d then return end
            local button
            if event.delta_y < 0 or event.direction == "UP" then
                button = 4
            elseif event.delta_y > 0 or event.direction == "DOWN" then
                button = 5
            else
                awexygen.log_error("Unrecognized scroll event", event.delta_x, event.delta_y, event.direction)
                return
            end
            local state = event.state
            local buttons = nil
            local mods = nil
            if mousegrabber.callback then
                if buttons == nil then buttons = common.gdk_modifiers_to_awesome_buttons(state) end
                buttons[button] = true
                mousegrabber.handle(
                    {
                        x = d._geometry.x + event.x,
                        y = d._geometry.y + event.y,
                        buttons = buttons,
                    })
            else
                if mods == nil then mods = common.gdk_modifiers_to_awesome_modifiers(state) end
                d:emit_signal("button::press", event.x, event.y, button, mods)
                d:process_buttons("press", event.x, event.y, event.button, mods, state)
            end
            if mousegrabber.callback then
                if buttons == nil then buttons = common.gdk_modifiers_to_awesome_buttons(state) end
                buttons[button] = false
                mousegrabber.handle(
                    {
                        x = d._geometry.x + event.x,
                        y = d._geometry.y + event.y,
                        buttons = buttons,
                    })
            else
                if mods == nil then mods = common.gdk_modifiers_to_awesome_modifiers(state) end
                d:emit_signal("button::release", event.x, event.y, button, mods)
                d:process_buttons("release", event.x, event.y, event.button, mods, state)
            end
        end,
        on_motion_notify_event = function (_self, event)
            -- Use updated position to avoid lagging.
            local _, x, y, state = event.window:get_device_position(event.device)
            local d = weak_drawin[1]
            if not d then return end
            if mousegrabber.callback then
                mousegrabber.handle(
                    {
                        x = d._geometry.x + event.x,
                        y = d._geometry.y + event.y,
                        buttons = common.gdk_modifiers_to_awesome_buttons(state),
                    })
            else
                d:emit_signal("mouse::move", x, y)
            end
        end,
        on_enter_notify_event = function (_self, event)
            -- Filter out events related to embedded children.
            if event.detail ~= "ANCESTOR" then return end
            local d = weak_drawin[1]
            if not d then return end
            if not mousegrabber.callback then
                d:emit_signal("mouse::enter")
                d:emit_signal("mouse::move", event.x, event.y)
            end
        end,
        on_leave_notify_event = function (_self, event)
            -- Ditto
            if event.detail ~= "ANCESTOR" then return end
            local d = weak_drawin[1]
            if not d then return end
            if not mousegrabber.callback then
                d:emit_signal("mouse::leave")
            end
        end,
        on_key_press_event = function (_self, event)
            local _keyval, _code, state = event.keyval, event.hardware_keycode, event.state
            if keygrabber.callback then
                keygrabber.callback(
                    common.gdk_modifiers_to_awesome_modifiers(state), common.get_key_name(event), "press")
                return true
            end
            local d = weak_drawin[1]
            local widget = d and d._focused_child[1] and d._focused_child[1].gtk_widget
            if not widget then return false end
            return widget:event(event)
        end,
        on_key_release_event = function (_self, event)
            local _keyval, _code, state = event.keyval, event.hardware_keycode, event.state
            if keygrabber.callback then
                keygrabber.callback(
                    common.gdk_modifiers_to_awesome_modifiers(state), common.get_key_name(event), "release")
                return true
            end
            local d = weak_drawin[1]
            local widget = d and d._focused_child[1] and d._focused_child[1].gtk_widget
            if not widget then return false end
            return widget:event(event)
        end,
        events = gdk.EventMask{
            "ENTER_NOTIFY_MASK",
            "LEAVE_NOTIFY_MASK",
            "POINTER_MOTION_MASK",
            "BUTTON_PRESS_MASK",
            "BUTTON_RELEASE_MASK",
            "KEY_PRESS_MASK",
            "KEY_RELEASE_MASK",
            "SCROLL_MASK",
        },
        can_focus = true,
    }
    ret._drawing_area:show()
    ret._window.child = ret._drawing_area
    ret._window.gravity = "STATIC"
    resize_drawin(ret, width, height)
    if args.x or args.y then
        ret._window:move(args.x or 0, args.y or 0)
    end
    ret.drawable = drawable(ret)

    ret.valid = true
    ret.__gc_guard = awexygen.gc_guard(
        function ()
            ret.valid = false
            ret.drawable.valid = false
            ret._window:destroy()
        end)

    ret._drawing_area:realize()
    ret.gtk_layout = args.gtk_layout
    ret._canvas_gdk_window = args.gtk_layout and
        ret._drawing_area:get_bin_window() or
        ret._drawing_area.window
    if args.gtk_layout then
        if gdk.Display:get_default():supports_composite() then
            ret._drawing_area.window:set_composited(true)
            ret.is_compositing = true
        end
        local gdk_events = ret._canvas_gdk_window:get_events()
        gdk_events["SMOOTH_SCROLL_MASK"] = nil
        ret._canvas_gdk_window:set_events(
            gdk.EventMask(gdk_events))
    end
    ret._active_children = setmetatable({}, {__mode = "k"})
    ret._focused_child = setmetatable({}, {__mode = "k"})
    function ret._canvas_gdk_window.on_pick_embedded_child(_self, x, y)
        local d = weak_drawin[1]
        local ec = d and d._active_children
        local result
        for c, info in pairs(ec) do
            if info.x <= x and x < info.x + info.width and
                info.y <= y and y < info.y + info.height then
                result = c
                break
            end
        end
        return result and result.gdk_window
    end
    ret._window:realize()
    gdk_window_to_drawin[ret._window.window] = ret
    ret._window.visible = args.visible

    return ret
end

return drawin
