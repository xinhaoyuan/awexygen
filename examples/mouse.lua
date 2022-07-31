local awful = require("awful")
local wibox = require("wibox")

local fg = "#ffffff"
local bg = "#000000"

local widget = wibox.widget{
    {
        id = "top",
        {
            text = "hello",
            font = "monospace 14",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        },
        widget = wibox.container.background,
    },
    {
        id = "middle",
        {
            text = "awesome",
            font = "monospace 20",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        },
        widget = wibox.container.background,
    },
    {
        id = "bottom",
        {
            text = "world",
            font = "monospace 14",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        },
        widget = wibox.container.background,
    },
    layout = wibox.layout.align.vertical,
}

local b = wibox{
    width = 400,
    height = 400,
    widget = widget,
    bg = bg,
    fg = fg,
    visible = true,
}
b:connect_signal("property::visible", function ()
                     require("awexygen").app.request_exit() end)
local buttons = require("gears.table").join(
    awful.button({"Any"}, 1, function () print("press 1") end, function () print("release 1") end),
    awful.button({}, 3, function () print("press 3") end, function () print("release 3") end)
)
b:buttons(buttons)
for _, id in ipairs{"top", "middle", "bottom"} do
    widget:get_children_by_id(id)[1]:connect_signal(
        "button::press", function (w)
            w.widget.text = w.widget.text.."!"
        end)
    widget:get_children_by_id(id)[1]:connect_signal(
        "mouse::enter", function (w)
            w.bg = fg
            w.fg = bg
        end)
    widget:get_children_by_id(id)[1]:connect_signal(
        "mouse::leave", function (w)
            w.bg = nil
            w.fg = nil
        end)
end
