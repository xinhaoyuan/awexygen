-- A toy `dmenu` alternative without text input or scrolling.

local awexygen = require("awexygen")
local wibox = require("wibox")
local awful = require("awful")

local container = wibox.widget{
    widget = wibox.layout.flex.vertical,
}

local fg = "#d0d0d0"
local bg = "#404040"

local function add_option(l)
    local widget = wibox.widget{
        {
            text = l,
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
            buttons = awful.util.table.join(
                awful.button({"Any"}, 1, function ()
                                 io.stdout:write(l)
                                 io.stdout:write("\n")
                                 awexygen.app.request_exit()
                             end)
            ),
        },
        widget = wibox.container.background,
    }
    widget:connect_signal("mouse::enter", function()
                              widget.bg = fg
                              widget.fg = bg
                          end)
    widget:connect_signal("mouse::leave", function()
                              widget.bg = nil
                              widget.fg = nil
                          end)
    container:add(widget)
end

for l in io.stdin:lines() do
    if #l > 0 then add_option(l) end
end

wibox{
    width = 400,
    height = 400,
    widget = wibox.widget{
        container,
        fg = fg,
        bg = bg,
        widget = wibox.container.background,
    },
    visible = true,
}:connect_signal("property::visible", function ()
                     require("awexygen").app.request_exit() end)
