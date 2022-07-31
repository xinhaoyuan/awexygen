local awexygen = require("awexygen")
local wibox = require("wibox")

local message = [[Hello from Awexygen!

You see this message because you have not created your awexygen_rc module.]]

wibox{
    width = 400,
    height = 400,
    widget = wibox.widget{
        wibox.container.background(),
        {
            {
                image = awexygen.get_icon_svg_path(),
                widget = wibox.widget.imagebox,
            },
            widget = wibox.container.place,
        },
        {
            text = message,
            align = "center",
            valign = "top",
            widget = wibox.widget.textbox,
        },
        spacing = 20,
        wibox.container.background(),
        layout = wibox.layout.flex.vertical,
    },
    bg = "#ffffffa0",
    fg = "#000000",
    visible = true,
}:connect_signal(
    "property::visible", function ()
        awexygen.app.request_exit()
    end)
