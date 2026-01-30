local PE = require "PixelEngine"
local sys = require "syscalls"
-- local mon = peripheral.wrap("top")
sys.register_window("PixelEngine", 1, 2, 39, 14, true)
--we make basic adjustments to color and size
term.setBackgroundColor(colors.black)
term.setTextColor(colors.black)
-- mon.setTextScale(.5)
local w, h = term.getSize()

local buffer = PE.new(w, h)

--add test pixels
buffer:setPixel(1, 1, colors.red)
buffer:setPixel(2, 2, colors.green)
buffer:setPixel(3, 3, colors.blue)
buffer:setPixel(4, 4, colors.pink)
buffer:setPixel(5, 5, colors.purple)
buffer:setPixel(6, 6, colors.brown)
buffer:setPixel(7, 7, colors.yellow)
buffer:setPixel(8, 8, colors.orange)

--and draw
buffer:draw(term)

while true do
    os.pullEvent()
end