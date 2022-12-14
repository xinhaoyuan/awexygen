local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local fake_capi = require(prefix.."fake_capi")
local screen = require(prefix.."screen")
local drawin = require(prefix.."drawin")
local lgi = require("lgi")
local gdk = lgi.Gdk

local mouse = fake_capi.module{
    name = "mouse",
    base = {
        getter = function (_, key)
            if key == "screen" then
                local _screen, x, y, _mask = screen._display:get_pointer()
                return screen.get_screen_at_point(x, y)
            end
        end,
    },
}

function mouse.object_under_pointer()
    local w, _x, _y = gdk.Window.at_pointer()
    if w == nil then return nil end
    local tl = w:get_toplevel()
    return drawin.find_drawin_by_gdk_window(tl)
end

function mouse.coords(v)
    if v == nil then
        local _screen, x, y, mask = screen._display:get_pointer()
        return {x = x, y = y, buttons = common.gdk_modifiers_to_awesome_buttons(mask)}
    else
        -- print("Setting coords is ignored.")
    end
end

return mouse
