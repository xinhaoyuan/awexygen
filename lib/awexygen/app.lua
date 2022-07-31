local lgi = require("lgi")
local gtk = lgi.require("Gtk", "3.0")

local app = {}

function app.request_exit(code)
    if app.exit_requested then return end
    app.exit_requested = true
    app.exit_code = code
    gtk.main_quit()
end

return app
