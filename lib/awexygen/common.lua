local lgi = require("lgi")
local gdk = lgi.Gdk
local gdk_pixbuf = lgi.GdkPixbuf

local common = {}

function common.get_icon_svg_path()
    -- Assumes the repository structure.
    return string.gsub(debug.getinfo(1).source, "@(.*[\\/])lib[\\/]awexygen[\\/]common%.lua+$", "%1icon.svg")
end
local icon_pixbuf = nil
function common.get_icon_pixbuf()
    if icon_pixbuf then return icon_pixbuf end
    local svg_path = common.get_icon_svg_path()
    local ok, ret = pcall(gdk_pixbuf.Pixbuf.new_from_file, svg_path)
    if ok and ret then
        icon_pixbuf = ret
    else
        common.log_error("failed to load icon", svg_path)
    end
    return icon_pixbuf
end

function common.gc_guard(cb)
    if _VERSION <= "Lua 5.1" then
        local userdata = newproxy(true)
        getmetatable(userdata).__gc = cb
        return userdata
    end
    return setmetatable({}, {__gc = cb})
end

local log_output = io.stderr
local log_level = 1
function common.set_log_level(level)
    if type(level) == "string" then
        level = level:lower()
        if level == "error" then level = 0
        elseif level == "warning" then level = 1
        elseif level == "info" then level = 2
        end
    elseif type(level) ~= "number" then level = 0
    end
    log_level = level
end
function common.set_log_output(output)
    log_output = output
end

function common.log_info(...)
    if log_level < 2 then return end
    local args = {...}
    for i = 1, #args do args[i] = tostring(args[i]) end
    log_output:write("INFO\t", table.concat(args, "\t"), "\n")
end

function common.log_warning(...)
    if log_level < 1 then return end
    local args = {...}
    for i = 1, #args do args[i] = tostring(args[i]) end
    log_output:write("WARNING\t", table.concat(args, "\t"), "\n")
end

function common.log_error(...)
    if log_level < 0 then return end
    local args = {...}
    for i = 1, #args do args[i] = tostring(args[i]) end
    log_output:write("ERROR\t", table.concat(args, "\t"), "\n")
end

common.is_compositing = gdk.Display:get_default():supports_composite()

return common
