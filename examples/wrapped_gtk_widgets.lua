local awexygen = require("awexygen")
local wgw = awexygen.wrapped_gtk_widget
local wibox = require("wibox")
local lgi = require("lgi")
local gtk = lgi.Gtk

local w_1 = wibox.widget{
    wrapped = gtk.Entry{expand = true, text = "Textbox 1"},
    widget = wgw,
}

local w_2 = wibox.widget{
    wrapped = gtk.Entry{expand = true, text = "Textbox 2"},
    widget = wgw,
}

wibox{
    widget = {
        {
            {
                w_1,
                opacity = 0.5,
                widget = wibox.container.place,
            },
            {
                w_2,
                widget = wibox.container.place,
            },
            layout = wibox.layout.flex.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
    },
    bg = "#000000",
    height = 300,
    width = 400,
    visible = true,
    gtk_layout = true,
}:connect_signal(
    "property::visible", function (self)
        if not self.visible then
            awexygen.app.request_exit()
        end
    end)
