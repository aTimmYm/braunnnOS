local sys = require "sys"
local blittle = require "blittle_extended"

sys.register_window("Blittle", 1, 2, 39, 14, true)

term.setBackgroundColor(colors.green)
term.setTextColor(colors.black)
term.clear()
term.setCursorPos(6,1)
term.setBackgroundColor(colors.blue)
term.write(" ")
term.setCursorPos(6,2)
term.setBackgroundColor(colors.red)
term.write(" ")
term.setCursorPos(6,3)
term.setBackgroundColor(colors.orange)
term.write(" ")

-- blittle.save(blittle.shrink(paintutils.loadImage("sbin/Shell/icon3.nfp"), colors.lightBlue), "sbin/Shell/icon5.ico")
local img = blittle.load("sbin/Shell/icon3.ico")

blittle.draw(img, 1, 1)

while true do
    os.pullEvent()
end