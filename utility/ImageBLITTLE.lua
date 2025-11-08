package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local c = require("cfunc")
os.loadAPI("lib/blittle")
c.termClear()
print("Write filename/path without 'nfp'")
local a = read()..".nfp"
if a ~= "e.nfp" and a ~= "exit.nfp" then
    print("Write name of output file")
    local b = read()
    blittle.save(blittle.shrink(paintutils.loadImage(a)), b..".ico")
end