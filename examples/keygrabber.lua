local wibox = require("wibox")
local awful = require("awful")

local b = wibox{
    width = 400,
    height = 400,
    visible = true
}
b:connect_signal("property::visible",
                 function () require("awexygen").app.request_exit() end)

local kg
kg = awful.keygrabber{
    keybindings = {
        -- "#keycode" keys seem not working for keygrabber in AwesomeWM either.
        awful.key {
            modifiers = {},
            key       = "#65",
            on_press  = function ()
                print("space")
            end,
        },
        -- Ditto for the "Any" modifier.
        awful.key {
            modifiers = {"Any"},
            key       = "a",
            on_press  = function ()
                print("a")
            end,
        },
        awful.key {
            modifiers = {},
            key       = "b",
            on_press  = function ()
                print("b")
            end,
        },
        awful.key {
            modifiers = {},
            key       = "x",
            on_press  = function ()
                print("keygrabber exiting")
                kg:stop()
            end,
        },
    },
}
kg:start()
