local sys = require "sys"
sys.register_window("Shell", 1, 1, 39, 14, true)
local func, err = loadfile("/rom/programs/shell.lua", _ENV)
if func then func() end