package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local c = require("cfunc")
local blittle = require("/lib/blittle_extended")
term.setCursorPos(1,1)
term.clear()
print("Write filename/path without 'nfp'")
local a = read()..".nfp"
if a ~= "e.nfp" and a ~= "exit.nfp" then
	print("Write name of output file")
	local b = read()
	blittle.save(blittle.shrink(paintutils.loadImage(a)), b..".ico")
end