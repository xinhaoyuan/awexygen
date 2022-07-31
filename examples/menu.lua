local awful = require("awful")

local m = awful.menu(
    {
        {"item 1", function () print("item 1 chosen") end},
        {"item 2", function () print("item 2 chosen") end},
    })

m.wibox:connect_signal(
    "property::visible", function (self)
        if self.visible then return end require("awexygen").app.request_exit()
    end)
m:show()
