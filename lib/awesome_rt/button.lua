local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")
local fake_capi = require(prefix.."fake_capi")

local button = fake_capi.module{
    name = "button",
    base = {
        call = function (self, ...) return self.new(...) end,
    }
}

function button:set_modifiers(modifiers)
    self._private.modifiers = modifiers
    self._private.gdk_modifiers = common.awesome_modifiers_to_gdk_modifiers(modifiers)
    self:emit_signal("property::modifiers")
end

function button:get_gdk_modifers()
    return self._private.gdk_modifiers
end

function button:get_modifiers()
    return self._private.modifiers
end

function button:set_button(b)
    self._private.button = b
    self:emit_signal("property::button")
end

function button:get_button()
    return self._private.button
end

function button.new(args)
    local ret = fake_capi.object{
        class = button
    }
    rawset(ret, "_is_capi_button", true)
    ret.modifiers = args.modifiers or {}
    ret.button = args.button
    return ret
end

return button
