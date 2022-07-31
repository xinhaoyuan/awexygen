local prefix = (...):match("(.-)[^%.]+$")
local common = require(prefix.."common")

local root = common.fake_capi_module{name = "root"}

function root.cursor()
    -- Ignore
end
function root._buttons(buttons)
    if buttons == nil then
        return {}
    end
end
function root._keys(new_keys)
    if new_keys == nil then
        return {}
    end
end
-- TODO calculate sizes using display information?
function root.size()
    return 0, 0
end
function root.size_mm()
    return 0, 0
end

return root
