local sys = require "syscalls"
local UI = require "ui2"
local self_pid = sys.getpid()

local items = {
	{ text = "Reboot", onClick = function() os.reboot() end },
	{ text = "ShutDown", onClick = function() os.shutdown() end },
}

local globals = {}
local active_menu

local SCREEN_WIDTH, SCREEN_HEIGHT = sys.screen_get_size()

sys.register_window("panel", 1, 1, SCREEN_WIDTH, 1, false, 1)

local root = UI.Root()

-- local panel = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
local panel = UI.Box({
	x = 1,
	y = 1,
	w = root.w,
	h = root.h,
	bc = colors.gray,
	fc = colors.white,
})
root:addChild(panel)

-- local button_menu = UI.Button(1, 1, 3, 1, "\223", _, {font2 = colors.lightGray, bg = panel.color_bg, font = panel.color_txt})
local button_menu = UI.Button({
	x = 1,
	y = 1,
	w = 3,
	h = 1,
	text = "\223",
	bc = panel.bc,
	fc = panel.fc,
})
panel:addChild(button_menu)

-- local clock = UI.Clock(panel.w - 7, 1, true, true, panel.color_bg, panel.color_txt)
local clock = UI.Clock({
	x = panel.w - 7, y = 1,
	show_seconds = true,
	is_24h = true,
	bc = panel.bc,
	fc = panel.fc,
})
panel:addChild(clock)

button_menu.pressed = function(self)
	sys.create_popup(items, 1, 2)
end

panel.onResize = function(width, height)
	SCREEN_WIDTH, SCREEN_HEIGHT = width, height
	panel.w = width
	clock.local_x = panel.w - 7
	os.queueEvent("wm_reposition", self_pid, 1, 1, width, 1)
end

local panel_onEvent = panel.onEvent
function panel.onEvent(self, evt)
	local event_name = evt[1]
	if event_name == "menu_add" and evt[2] ~= self_pid then
		if _G.global_menu then
			-- local pid = evt[2]
			_G.global_menu.x = 4
			globals[evt[2]] = _G.global_menu
			panel:addChild(_G.global_menu)
			active_menu = _G.global_menu
			-- panel:onLayout()
			_G.global_menu = nil
		elseif globals[evt[2]] then
			local pid = evt[2]
			local menu = globals[pid]
			if active_menu then panel:removeChild(active_menu) end
			panel:addChild(menu)
			active_menu = menu
		else
			local pid = evt[2]
			local menu = globals[pid]
			if active_menu then panel:removeChild(active_menu) end
			if pid and menu then panel:addChild(menu) end
		end
		panel:onLayout()
		return true
	elseif event_name == "menu_remove" then
		globals[evt[2]] = nil
	end
	return panel_onEvent(self, evt)
end

root:mainloop()
