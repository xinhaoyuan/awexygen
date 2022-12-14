local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local fake_capi = require(prefix.."fake_capi")
local lgi = require("lgi")
local gdk = lgi.Gdk

local key = fake_capi.module{
    name = "key",
    base = {
        call = function (self, ...) return self.new(...) end,
    },
}

function key.get_keysym()
    -- TODO
end

function key:set_modifiers(modifiers)
    self._private.modifiers = modifiers
    self._private.gdk_modifiers = common.awesome_modifiers_to_gdk_modifiers(modifiers)
    self:emit_signal("property::modifiers")
end

function key:get_gdk_modifers()
    return self._private.gdk_modifiers
end

function key:get_modifiers()
    return self._private.modifiers
end

function key:set_key(k)
    -- 35 is "#" in ASCII.
    if k:byte(1) == 35 then
        self._private.key = nil
        self._private.keycode = tonumber(k:sub(2))
    else
        local keyval = gdk.keyval_from_name(k)
        k = gdk.keyval_name(keyval)
        self._private.key = common.key_name_translation[k] or k
        self._private.keycode = nil
    end
    self:emit_signal("property::key")
end

function key:get_key()
    if self._private.keycode then
        return "#"..tostring(self._private.keycode)
    end
    return self._private.key
end

function key.new(args)
    local ret = fake_capi.object{class = key}
    rawset(ret, "_is_capi_key", true)
    ret.modifiers = args.modifiers or {}
    ret.key = args.key
    return ret
end

return key
