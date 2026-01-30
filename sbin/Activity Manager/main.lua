local sys = require "syscalls"
local UI = require "ui2"

sys.register_window("Activity Manager", 1, 1, 39, 14, true)

local root = UI.Root()

-- local surface = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.gray,
	fc = colors.white
})
root:addChild(surface)

local processes = sys.get_processes_info()

-- local surface2 = UI.Box(1, 2, surface.w, surface.h - 1, colors.black)
local surface2 = UI.Box({
	x = 1, y = 2,
	w = surface.w, h = surface.h - 1,
	bc = colors.black,
	fc = colors.white,
})
surface:addChild(surface2)

-- local CPU = UI.Button(14,1, 7, 1, "| CPU |", _, _, colors.lightGray, colors.white)
local CPU = UI.Button({
	x = 14, y = 1,
	w = 7, h = 1,
	text = "| CPU |",
	bc = colors.lightGray,
	fc = colors.white,
})
surface:addChild(CPU)
-- local MEM = UI.Button(CPU.x+CPU.w,1, 6, 1, " MEM |", _, _, colors.lightGray, colors.white)
local MEM = UI.Button({
	x = CPU.x + CPU.w, y = 1,
	w = 6, h = 1,
	text = " MEM |",
	bc = colors.lightGray,
	fc = colors.white,
})
surface:addChild(MEM)
-- local NETWORK = UI.Button(MEM.x+MEM.w,1, 10, 1, " NETWORK |", _, _, colors.lightGray, colors.white)
local NETWORK = UI.Button({
	x = MEM.x + MEM.w, y = 1,
	w = 10, h = 1,
	text = " NETWORK |",
	bc = colors.lightGray,
	fc = colors.white,
})
surface:addChild(NETWORK)

for i, v in ipairs(processes) do
	local bc = i % 2 == 0 and colors.gray or colors.black
	-- local pid = UI.Label(1, i, 5, 1, tostring(v.pid), "right", bc, colors.white)
	local pid = UI.Label({
		x = 1, y = i,
		w = 5, h = 1,
		text = tostring(v.pid),
		align = "right",
		bc = bc,
		fc = colors.white,
	})
	surface2:addChild(pid)
	-- local title = UI.Label(6, i, surface2.w - 5, 1, "|"..v.title, "left", bc, colors.white)
	local title = UI.Label({
		x = 6, y = i,
		w = surface2.w, h = 1,
		text = "|"..v.title,
		align = "left",
		bc = bc,
		fc = colors.white,
	})
	surface2:addChild(title)
end

root:mainloop()