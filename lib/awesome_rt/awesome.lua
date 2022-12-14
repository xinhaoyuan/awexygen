local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local fake_capi = require(prefix.."fake_capi")
local lgi = require("lgi")
local glib = lgi.GLib
local cairo = lgi.cairo
local gdk = lgi.Gdk
local gdk_pixbuf = lgi.GdkPixbuf
local awexygen = require("awexygen")
local gobject = require("gears.object")

local awesome_base = gobject{enable_properties = true}
local awesome = fake_capi.module{
    name = "awesome",
    base = {
        getter = function (_self, key)
            if key == "_active_modifiers" then
                return common.gdk_modifiers_to_awesome_modifiers(
                    gdk.Keymap.get_default():get_modifier_state())
            end
        end
    }
}

local to_emit_refresh = false
local function idle_callback()
    awesome.emit_signal("refresh")
    to_emit_refresh = false
    return glib.SOURCE_REMOVE
end

function awesome.emit_refresh_when_idle()
    if to_emit_refresh then return end
    glib.idle_add(glib.PRIORITY_DEFAULT, idle_callback)
    to_emit_refresh = true
end

function awesome.register_xproperty()
    -- Ignore
end

function awesome.spawn(cmd, _use_sn,
                       return_stdin, return_stdout, return_stderr,
                       exit_callback, env)
    if type(cmd) == "string" then
        local maybe_error
        cmd, maybe_error = glib.shell_parse_argv(cmd)
        if maybe_error ~= nil then
            return "spawn: "..maybe_error
        end
    end
    local child_pid, stdin_or_error, stdout, stderr = awexygen.spawn(
        nil, cmd, env, glib.SpawnFlags{
            "SEARCH_PATH", "CLOEXEC_PIPES",
            exit_callback and "DO_NOT_REAP_CHILD",
            (not return_stdout) and "STDOUT_TO_DEV_NULL" or nil,
            (not return_stderr) and "STDERR_TO_DEV_NULL" or nil,
        })
    if not child_pid then
        return tostring(stdin_or_error)
    end
    if not return_stdin then
        glib.close(stdin_or_error)
        stdin_or_error = nil
    end
    if exit_callback then
        glib.child_watch_add(
            0, child_pid, function (_pid, wait_status)
                local exit_type
                local typed_code
                if wait_status <= 128 then
                    exit_type = "exit"
                    typed_code = wait_status
                else
                    exit_type = "signal"
                    typed_code = wait_status - 128
                end
                exit_callback(exit_type, typed_code)
            end)
    end
    -- No SN
    return child_pid, nil, stdin_or_error, stdout, stderr
end

function awesome.pixbuf_to_surface(pixbuf)
    pixbuf = gdk_pixbuf.Pixbuf(pixbuf)
    local surf = cairo.ImageSurface.create(cairo.Format.ARGB32, pixbuf.width, pixbuf.height)
    local cr = cairo.Context(surf)
    cr:set_source_pixbuf(pixbuf, 0, 0)
    cr:paint()
    return surf
end

-- For AwesomeWM 4.3
awesome.api_level = 4
awesome.version = "4.3"

-- Disables fake transparency logic.
awesome.composite_manager_running = true

local xrdb = {}
for line in io.popen('xrdb -query'):lines() do
    local key, value = line:match("^[*.]*(.+):%s+(.+)$")
    if key and value then
        xrdb[key] = value
    end
end
function awesome.xrdb_get_value(class, name)
    -- TODO: Is this correct? Check the spec.
    if class == "" then
        return xrdb[name]
    else
        return xrdb[class.."*"..name] or xrdb[class.."."..name]
    end
end

function awesome.quit()
    local info = debug.getinfo(2, "Sl")
    awexygen.log_info(string.format("awesome.quit called at %s:%d", info.source, info.currentline))
    os.exit()
end

-- TODO Generate these accurately.
-- Currently LGI/Gdk APIs are not enough for this: It cannot enumerate keyvals/keycodes for modifiers
awesome._modifiers = {
    ["Mod1"] = {{keysym = "Alt_L"}, {keysym = "Alt_R"}},
    -- Mod2 can be numlock on X11 or Command on macOS. We ignore it here...
    -- Mod3 usually is empty
    ["Mod4"] = {{keysym = "Super_L"}, {keysym = "Super_R"}},
    ["Shift"] = {{keysym = "Shift_L"}, {keysym = "Shift_R"}},
    ["Control"] = {{keysym = "Control_L"}, {keysym = "Control_R"}},
    -- Alt, Meta, Super, and Hyper are ignored.
}

return awesome
