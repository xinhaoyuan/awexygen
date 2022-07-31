-- A hacky fix for g_spawn_async_with_pipes to allow STDOUT/STDERR_TO_DEV_NULL.
local lgi = require("lgi")
local glib = lgi.GLib
local lgi_core = require("lgi.core")
local lgi_ffi = require("lgi.ffi")
local lgi_ti = lgi_ffi.types
local lgi_record = require("lgi.record")
local lgi_component = require("lgi.component")

local wrapped_string = lgi_component.create(nil, lgi_record.struct_mt, "wrapped_string")
lgi_ffi.load_fields(wrapped_string, {{'v', lgi_ti.utf8}})

local wrapped_int = lgi_component.create(nil, lgi_record.struct_mt, "wrapped_int")
lgi_ffi.load_fields(wrapped_int, {{'v', lgi_ti.int}})

local method_info = {
    name = "GLib.spawn_async_with_pipes_raw",
    addr = lgi_core.gi.GLib.resolve["g_spawn_async_with_pipes"],
    throws = true, ret = {lgi_ti.void},
    -- working_directory
    lgi_ti.utf8,
    -- argv
    wrapped_string,
    -- envp
    wrapped_string,
    -- flags
    lgi_ti.int,
    -- child_setup
    lgi_ti.ptr,
    -- user_data
    lgi_ti.ptr,
    -- child_pid
    {lgi_ti.int, dir = "out"},
    -- standard_input
    {lgi_ti.int, dir = "out"},
    -- standard_output,
    wrapped_int,
    -- standard_error
    wrapped_int,
}
local spawn_raw = lgi_core.callable.new(method_info)

return function(wd, cmd, env, flags)
    local cmd_raw
    if cmd then
        cmd_raw = lgi_core.record.new(wrapped_string, nil, #cmd + 1)
        for i = 1, #cmd do
            lgi_core.record.fromarray(cmd_raw, i - 1).v = cmd[i]
        end
        lgi_core.record.fromarray(cmd_raw, #cmd).v = nil
    end
    local env_raw
    if env then
        env_raw = lgi_core.record.new(wrapped_string, nil, #env + 1)
        for i = 1, #env do
            lgi_core.record.fromarray(env_raw, i - 1).v = env[i]
        end
        lgi_core.record.fromarray(env_raw, #env).v = nil
    end
    local stdout_holder, stderr_holder
    if glib.SpawnFlags{flags, "STDOUT_TO_DEV_NULL"} ~= flags then
        stdout_holder = lgi_core.record.new(wrapped_int, nil, 1)
    end
    if glib.SpawnFlags{flags, "STDERR_TO_DEV_NULL"} ~= flags then
        stderr_holder = lgi_core.record.new(wrapped_int, nil, 1)
    end
    local child_pid, stdin_or_error = spawn_raw(wd, cmd_raw, env_raw, flags, nil, nil, stdout_holder, stderr_holder)
    local stdout, stderr
    if child_pid and stdout_holder then
        stdout = lgi_core.record.fromarray(stdout_holder, 0).v
    end
    if child_pid and stderr_holder then
        stderr = lgi_core.record.fromarray(stderr_holder, 0).v
    end
    return child_pid, stdin_or_error, stdout, stderr
end
