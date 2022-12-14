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
