local prefix = (...):match("(.-)[^%.]+$")
local fake_capi = require(prefix.."fake_capi")

local lgi = require("lgi")
local gdk = lgi.Gdk
local gtable = require("gears.table")
local awesome = require(prefix.."awesome")

local screen_module
local current_screens = {}
local display = gdk.Display.get_default()
screen_module = fake_capi.module{
    name = "screen",
    base = {
        getter = function (_self, key)
            if key == "_display" then
                return display
            end
            if key == "primary" then
                return current_screens[current_screens.primary_index]
            end
            if type(key) == "screen" then return key end
            if type(key) == "number" then return current_screens[key] end
        end,
        -- Make `for s in screen` work.
        call = function (_self, _, e)
            return current_screens[(e and e.index or 0) + 1]
        end
    },
}
function screen_module.get_screen_at_point(x, y)
    local monitor = display:get_monitor_at_point(x, y)
    for _, s in ipairs(current_screens) do
        if s.monitor == monitor then return s end
    end
end

local default_dpi = tonumber(awesome.xrdb_get_value("", "Xft.dpi"))
function screen_module:get_bounding_geometry(args)
    if args.honor_workarea then
        return self.workarea
    else
        return self.geometry
    end
end
local function update_screens()
    local primary_monitor = display:get_primary_monitor()
    for _, s in ipairs(current_screens) do
        s._private.valid = false
    end
    current_screens = {}
    for m = 0, display:get_n_monitors() - 1 do
        local monitor = display:get_monitor(m)
        local geometry = monitor:get_geometry()
        local workarea = monitor:get_workarea()
        local index = #current_screens + 1
        if primary_monitor == monitor then
            current_screens.primary_index = index
        end
        local screen_object = fake_capi.object{class = screen_module}
        gtable.crush(
            screen_object, {
                -- Used by us.
                monitor = monitor,
                index = index,
                -- Accessed by AWM widgets.
                geometry = {
                    x = geometry.x, y = geometry.y,
                    width = geometry.width, height = geometry.height,
                },
                workarea = {
                    x = workarea.x, y = workarea.y,
                    width = workarea.width, height = workarea.height,
                },
                -- TODO better DPI detection?
                dpi = default_dpi,
            })
        current_screens[index] = screen_object
    end
    screen_module.emit_signal("list")
end

update_screens()
function display.on_monitor_added()
    update_screens()
end
function display.on_monitor_removed()
    update_screens()
end

return screen_module
