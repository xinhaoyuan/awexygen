local gobject = require("gears.object")
local fake_capi = {}

function fake_capi.module(args)
    args = args or {}
    local base = args.base
    local str = args.name and string.format("fake_capi[%s]", args.name)
    local ret = {
        _module_name = args.name,
        _private = {valid = true}
    }
    -- Deprecated alias
    ret.data = ret._private
    function ret.set_index_miss_handler(handler)
        rawset(ret, "external_getter", handler)
    end
    function ret.set_newindex_miss_handler(handler)
        rawset(ret, "external_setter", handler)
    end
    local signal_object = gobject{}
    local wrapped_signal_cb = setmetatable({}, {__mode = "k"})
    function ret.connect_signal(signal_name, cb)
        if wrapped_signal_cb[cb] == nil then
            wrapped_signal_cb[cb] = function (_module, ...)
                return cb(...)
            end
        end
        return signal_object:connect_signal(signal_name, wrapped_signal_cb[cb])
    end
    function ret.emit_signal(maybe_self, ...)
        -- XXX can we avoid this? This happens when setting custom class properties
        if maybe_self == ret then return end
        return signal_object:emit_signal(maybe_self, ...)
    end
    function ret.disconnect_signal(signal_name, cb)
        return signal_object:disconnect_signal(signal_name, wrapped_signal_cb[cb])
    end
    function ret:get_valid() return self._private.valid end
    local mt = {
        __tostring = str and function ()
            return str
        end,
        __type = "fake_capi",
        __index = function (self, key)
            local v = base and base.getter and base.getter(self, key)
            if v ~= nil then return v end
            local getter = rawget(self, "external_getter")
            return getter and getter(self, key)
        end,
        __newindex = function(self, key, value)
            if base and base.setter and base.setter(self, key, value) then return end
            local setter = rawget(self, "external_setter")
            if setter then
                setter(self, key, value)
            else
                rawset(self, key, value)
            end
        end,
        __call = function (self, ...)
            assert(base and base.call, "module is uncallable")
            return base.call(self, ...)
        end,
    }
    return setmetatable(ret, mt)
end

function fake_capi.object(args)
    args = args or {}
    local class = args.class or nil
    local ret = gobject{enable_properties = false}
    ret._private = {valid = true}
    -- Deprecated alias
    ret.data = ret._private
    local rawstr = string.format("%s [%s]", tostring(ret), tostring(class))
    setmetatable(
        ret, {
            __tostring = function () return rawstr end,
            __type = class and class._module_name,
            __index = function (self, key)
                if not class then return nil end
                local v = rawget(class, key)
                if v then return v end
                v = class["get_"..key]
                if v then return v(self) end
                v = rawget(class, "external_getter")
                if v then return v(self, key) end
                return nil
            end,
            __newindex = function (self, key, value)
                if class then
                    local setter = class["set_"..key]
                    if not setter and class["get_"..key] then
                        print("Ignoring setting read-only property", key, value)
                        return
                    end
                    if setter then setter(self, value) return end
                    setter = rawget(class, "external_setter")
                    if setter then setter(self, key, value) return end
                end
                rawset(self, key, value)
            end,
        })
    ret:_connect_everything(
        function (...)
            class.emit_signal(...)
        end
    )
    return ret
end

local original_type = type
function type(o)
    local t = original_type(o)
    if t == "table" then
        local mt = getmetatable(o)
        if mt and mt.__type then return mt.__type end
    end
    return t
end

return fake_capi
