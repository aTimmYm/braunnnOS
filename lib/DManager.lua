local sys = require "syscalls"
local self_pid = sys.getpid()
local S_WIDTH, S_HEIGHT = sys.screen_get_size()
sys.register_window("Desktop", 1, 1, S_WIDTH, S_HEIGHT, false, 0)
local UI = require "ui2"

local items = {
	{ text = "New",  onClick = function() log("New!") end },
	{ text = "Open", onClick = function() log("Open!") end },
	{
		text = "PODMENU",
		submenu = {
			{ text = "DA", onClick = function() log("PIZDA") end }
		}
	},
}

local Context = UI.ContextMenu({
	x = 5, y = 5,
	w = 5,
	bc = colors.black,
	fc = colors.white,
})

Context:add_element("TEST").pressed = function ()
	log("TEST")
end
Context:add_element("TEST2").pressed = function ()
	log("TEST2")
end
Context:add_element("TEST3").pressed = function ()
	log("TEST3")
end

local root = UI.Root()

-- local desktop = UI.Box(1, 1, root.w, root.h, colors.lightBlue, colors.white)
local desktop = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.lightBlue,
	fc = colors.white
})
root:addChild(desktop)

desktop.onMouseDown = function(self, btn, x, y)
	if btn == 2 then
		sys.create_popup(items, x + 1, y + 1)
		-- Context.x, Context.y = x + 1, y + 1
		-- sys.create_popup(Context)
	end
end

desktop.onResize = function(width, height)
	S_WIDTH, S_HEIGHT = width, height
	desktop.w, desktop.h = width, height
	os.queueEvent("wm_reposition", self_pid, 1, 1, width, height)
end

root:mainloop()
