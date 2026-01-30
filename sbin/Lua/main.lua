local sys = require "syscalls"
sys.register_window("Lua", 1, 1, 39, 14, true)
local func, err = loadfile("/rom/programs/lua.lua", _ENV)
if func then func() end