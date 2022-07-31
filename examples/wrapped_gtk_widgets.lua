local awexygen = require("awexygen")
local wgw = awexygen.wrapped_gtk_widget
local wibox = require("wibox")
local lgi = require("lgi")
local gtk = lgi.Gtk

local w_1 = wibox.widget{
    gtk_widget = gtk.Entry{expand = true, text = "Directly wrapped"},
    widget = wgw.direct,
}

local w_2 = wibox.widget{
    gtk_widget = gtk.Entry{expand = true, text = "Wrapped in offsreen"},
    widget = wgw.offscreen,
}

wibox{
    widget = {
        {
            {
                w_1,
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

w_2:connect_signal("mouse::enter", function (self) self:grab_focus(true) end)
w_2:connect_signal("mouse::leave", function (self) self:grab_focus(false) end)
w_2:connect_signal("property::focus", function (self) self.active = self.focus end)
