local wibox = require("wibox")
local watch = require("awful.widget.watch")

wibox{
    width = 400,
    height = 400,
    widget = watch('date', 1, nil, wibox.widget{
                       align = "center",
                       valign = "center",
                       widget = wibox.widget.textbox,
                   }),
    visible = true,
}:connect_signal("property::visible", function ()
                     require("awexygen").app.request_exit() end)
