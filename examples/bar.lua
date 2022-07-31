local awful = require("awful")
local wibox = require("wibox")

awful.wibar{
    position = "top",
    height = 32,
    widget = wibox.widget{
        text = "hello",
        widget = wibox.widget.textbox,
    },
    visible = true,
    screen = awful.screen.focused(),
}
