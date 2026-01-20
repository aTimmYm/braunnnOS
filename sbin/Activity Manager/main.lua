local sys = require "sys"
local UI = require "ui2"

sys.register_window("Activity Manager", 1, 1, 51, 18, true)

local root = UI.Root()

local surface = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
root:addChild(surface)

local processes = sys.get_processes_info()

local surface2 = UI.Box(1, 2, surface.w, surface.h - 1, colors.black)
surface:addChild(surface2)

local CPU = UI.Button(14,1, 7, 1, "| CPU |", _, _, colors.lightGray, colors.white)
surface:addChild(CPU)
local MEM = UI.Button(CPU.x+CPU.w,1, 6, 1, " MEM |", _, _, colors.lightGray, colors.white)
surface:addChild(MEM)
local NETWORK = UI.Button(MEM.x+MEM.w,1, 10, 1, " NETWORK |", _, _, colors.lightGray, colors.white)
surface:addChild(NETWORK)

for i, v in ipairs(processes) do
	local color_bg = i % 2 == 0 and colors.gray or colors.black
	local pid = UI.Label(1, i, 5, 1, tostring(v.pid), "right", color_bg, colors.white)
	surface2:addChild(pid)
	local title = UI.Label(6, i, surface2.w - 5, 1, "|"..v.title, "left", color_bg, colors.white)
	surface2:addChild(title)
end

root:mainloop()