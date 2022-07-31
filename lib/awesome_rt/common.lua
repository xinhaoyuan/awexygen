local gobject = require("gears.object")
local gdk = require("lgi").Gdk
local common = {}

local mod_mask_to_button = {
    ["BUTTON1_MASK"] = 1,
    ["BUTTON2_MASK"] = 2,
    ["BUTTON3_MASK"] = 3,
    ["BUTTON4_MASK"] = 4,
    ["BUTTON5_MASK"] = 5,
}
function common.gdk_modifiers_to_awesome_buttons(mask)
    local ret = {}
    for k, v in pairs(mask) do
        if mod_mask_to_button[k] then
            ret[mod_mask_to_button[k]] = v
        else
            -- print("Ignore non-button", k)
        end
    end
    return ret
end

local mod_mask_to_awesome_mod = {
    ["MOD1_MASK"] = "Mod1",
    ["MOD2_MASK"] = "Mod2",
    ["MOD3_MASK"] = "Mod3",
    ["MOD4_MASK"] = "Mod4",
    ["MOD5_MASK"] = "Mod5",
    ["SHIFT_MASK"] = "Shift",
    ["LOCK_MASK"] = "Lock",
    ["CONTROL_MASK"] = "Control",
    ["SUPER_MASK"] = "Super",
    ["HYPER_MASK"] = "Hyper",
}
common.mod_mask_to_awesome_mod = mod_mask_to_awesome_mod
function common.gdk_modifiers_to_awesome_modifiers(gdk_mods)
    local ret = {}
    if type(gdk_mods) == "table" then
        for k, _v in pairs(gdk_mods) do
            if mod_mask_to_awesome_mod[k] then
                ret[#ret + 1] = mod_mask_to_awesome_mod[k]
            else
                -- print("Ignore non-modifier", k)
            end
        end
    else
        assert(type(gdk_mods) == "number")
        for k, _v in pairs(mod_mask_to_awesome_mod) do
            if gdk.ModifierType{gdk_mods, k} == gdk_mods then
                ret[#ret + 1] = mod_mask_to_awesome_mod[k]
            end
        end
    end
    return ret
end
function common.awesome_modifiers_to_gdk_modifiers(mods)
    local gdk_mods = {}
    for _, m in ipairs(mods) do
        if m == "Any" then
            if #mods == 1 then
                return nil
            else
                -- -1 should not match any regular masks.
                return -1
            end
        end
        local mod_name = m:upper().."_MASK"
        if common.mod_mask_to_awesome_mod[mod_name] then
            gdk_mods[#gdk_mods + 1] = mod_name
        end
    end
    return gdk_mods and gdk.ModifierType(gdk_mods)
end

function common.fake_capi_module(args)
    args = args or {}
    local base = args.base
    local call = args.call
    local str = args.name and string.format("fake_capi[%s]", args.name)
    local mt = {
        __tostring = str and function ()
            return str
        end,
        __index = function (self, key)
            local v = base and base[key]
            if v ~= nil then return v end
            local getter = rawget(self, "external_getter")
            return getter and getter(self, key)
        end,
        __newindex = function(self, key, value)
            local setter = rawget(self, "external_setter")
            if setter then
                setter(self, key, value)
            else
                rawset(self, key, value)
            end
        end,
        __call = function (self, ...)
            if call then return call(self, ...) end
            local base_mt = base and getmetatable(base)
            assert(base_mt, base_mt or debug.traceback())
            local base_call = base_mt["__call"]
            assert(base_call, base_call or debug.traceback())
            return base_call(self, ...)
        end,
    }
    local ret = setmetatable(
        {
            _module_name = args.name,
            _private = {}
        }, mt)
    function ret.set_index_miss_handler(handler)
        rawset(ret, "external_getter", handler)
    end
    function ret.set_newindex_miss_handler(handler)
        rawset(ret, "external_setter", handler)
    end
    local signal_object = gobject{}
    if args.signal_type == nil or args.signal_type == "module" then
        local wrapped_signal_cb = setmetatable({}, {__mode = "k"})
        function ret.connect_signal(signal_name, cb)
            if wrapped_signal_cb[cb] == nil then
                wrapped_signal_cb[cb] = function (_module, ...)
                    return cb(...)
                end
            end
            return signal_object:connect_signal(signal_name, wrapped_signal_cb[cb])
        end
        function ret.emit_signal(...)
            return signal_object:emit_signal(...)
        end
        function ret.disconnect_signal(signal_name, cb)
            return signal_object:disconnect_signal(signal_name, wrapped_signal_cb[cb])
        end
    elseif args.signal_type == "object" then
        function ret.emit_signal()
            -- Nothing to do since no one can connect to it.
        end
    end
    return ret
end

function common.fake_capi_object(args)
    args = args or {}
    local class = args.class or nil
    local ret = gobject{enable_properties = false}
    ret._private = {}
    local rawstr = string.format("%s [%s]", tostring(ret), tostring(class))
    setmetatable(
        ret, {
            __tostring = function () return rawstr end,
            __type = class and class._module_name,
            __index = function (self, key)
                if not class then return nil end
                local v = rawget(class, key)
                if v then return v end
                v = rawget(class, "get_"..key)
                if v then return v(self) end
                v = rawget(class, "external_getter")
                if v then return v(self, key) end
                return nil
            end,
            __newindex = function (self, key, value)
                if class then
                    local setter
                    if class["get_"..key] then
                        setter = class["set_"..key]
                        if not setter then
                            print("Trying to set read-only property", key, value)
                            return
                        end
                        return setter(self, value)
                    end
                    setter = rawget(class, "set_"..key)
                    if setter then return setter(self, value) end
                    setter = rawget(class, "external_setter")
                    if setter then return setter(self, key, value) end
                end
                rawset(self, key, value)
            end,
        })
    return ret
end

-- TODO Any more to translate? Figure out a way to generate this.
common.key_name_translation = {
    ["Page_Up"] = "Prior",
    ["Page_Down"] = "Next",
}
function common.get_key_name(gdk_key_event)
    if gdk_key_event.length > 0 then
        local s = gdk_key_event.string
        if s:byte(1) >= 32 and s:byte(1) <= 127 then
            return s
        end
    end
    local name = gdk.keyval_name(gdk_key_event.keyval)
    return common.key_name_translation[name] or name
end

return common
