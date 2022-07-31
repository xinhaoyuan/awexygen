assert(arg ~= nil, "must run this file as a standalone lua program")
local lgi = require("lgi")
local glib = lgi.GLib
-- Has to do this before requiring Gtk.
glib.set_prgname("awexygen")
local gtk = lgi.require("Gtk", "3.0")
pcall(lgi.require, "GdkX11", "3.0")
local awexygen = require("awexygen")
local entry = arg[1] or "awexygen_rc"
local entry_is_path = entry:find("/") ~= nil

glib.idle_add(
    glib.PRIORITY_DEFAULT, function()
        local ok, maybe_error = xpcall(
            function ()
                require("awesome_rt")
                if entry_is_path then
                    local f = loadfile(entry)
                    assert(f, "failed to load "..entry)
                    f()
                else
                    require(entry)
                end
            end, debug.traceback)
        if not ok then
            awexygen.log_error(maybe_error)
            awexygen.app.request_exit(1)
        end
        return glib.SOURCE_REMOVE
    end
)

gtk.main()
os.exit(awexygen.app.exit_code)
