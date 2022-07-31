local awexygen = {
    common = require(... .. ".common"),
    app = require(... .. ".app"),
    spawn = require(... .. ".spawn"),
    wrapped_gtk_widget = require(... .. ".wrapped_gtk_widget"),
}

for k, v in pairs(awexygen.common) do
    if type(v) == "function" then
        awexygen[k] = v
    end
end

return awexygen
