local sys = require "sys"
sys.register_window("Paint", 1, 1, 51, 18, true)
local func, err = loadfile("/rom/programs/fun/advanced/paint.lua", _ENV)
if func then func("test.nfp") end