local awful = require("awful")

local saved_stdout, saved_stderr, saved_exitreason, saved_exitcode
require("_runner").run_steps{
    function ()
        -- SN is not supported for now.
        local pid, snid = awful.spawn({"echo", "hello"})
        return type(pid) == "number" and snid == nil
    end,
    function ()
        local pid, snid = awful.spawn.easy_async(
            {"echo", "hello"}, function (stdout, stderr, exitreason, exitcode)
                saved_stdout = stdout
                saved_stderr = stderr
                saved_exitreason = exitreason
                saved_exitcode = exitcode
            end)
        return true
    end,
    function ()
        return saved_stdout == "hello\n" and
            saved_stderr == "" and
            saved_exitreason == "exit" and
            saved_exitcode == 0
    end,
}
