local table = table
local helper = {}

function helper.get_x11_geometry(w)
    local h = io.popen("xdotool getwindowgeometry --shell "..tostring(w))
    local result = {}
    for k, v in h:read("*a"):gmatch("([^\n]*)=([^\n]*)") do
        result[k] = v
    end
    h:close()
    return {
        x = tonumber(result["X"]),
        y = tonumber(result["Y"]),
        width = tonumber(result["WIDTH"]),
        height = tonumber(result["HEIGHT"]),
    }
end

function helper.monitor_signals(obj, names)
    local signals = {
        logs = {},
        handler = {},
    }
    for _, n in ipairs(names) do
        local mon_func = function (...)
            if signals.logs[n] == nil then
                signals.logs[n] = {}
            end
            local log = {n, ...}
            table.insert(signals.logs, log)
            table.insert(signals.logs[n], log)
        end
        obj:connect_signal(n, mon_func)
        signals.handler[n] = mon_func
    end
    return signals
end

function helper.skip(c)
    return function ()
        if c > 0 then c = c - 1 else return true end
    end
end

return helper
