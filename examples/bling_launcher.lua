-- Requires AwesomeWM 4.3-git and Bling: https://github.com/BlingCorp/bling/
local awexygen = require("awexygen")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local gfs = require("gears.filesystem")

beautiful.init(gfs.get_themes_dir().."gtk/theme.lua")
local launcher = require("bling.widget.app_launcher"){
    prompt_icon = "🚀️",
    -- Avoid glitch when moved to unfocused screens.
    show_on_focused_screen = false,
    screen = awful.screen.focused(),
    app_width = dpi(80),
    app_height = dpi(80),
    apps_per_column = 3,
    apps_per_row = 3,
    type = "dialog"
}
local function reposition_popup(self)
    self.widget:emit_signal("widget::layout_changed")
end
launcher._private.widget:connect_signal(
    "property::x", reposition_popup)
launcher._private.widget:connect_signal(
    "property::y", reposition_popup)
launcher._private.widget:connect_signal(
    "property::visible", function (self)
        if not self.visible then awexygen.app.request_exit() end
    end)
launcher:show()
