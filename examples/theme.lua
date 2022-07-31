local wibox = require("wibox")
local beautiful = require("beautiful")
local gfs = require("gears.filesystem")
beautiful.init(gfs.get_themes_dir().."gtk/theme.lua")

local widget = wibox.widget{
    {
        text = "This text should be drawn with fg/bg colors from the GTK theme",
        font = "monospace 14",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    },
    widget = wibox.container.background,
}

wibox{
    width = 400,
    height = 400,
    widget = widget,
    visible = true,
}:connect_signal("property::visible", function ()
                     require("awexygen").app.request_exit() end)
