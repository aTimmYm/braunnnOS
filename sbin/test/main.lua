local sys = require 'syscalls'
local UI = require 'ui2'
local S_WIDTH, S_HEIGHT = sys.screen_get_size()

sys.register_window('Test', math.floor((S_WIDTH - 34) / 2) + 1, math.floor((S_HEIGHT - 14) / 2) + 1, 34, 14, true)

local root = UI.Root()

local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.gray,
	fc = colors.white
})
root:addChild(surface)

local Context = UI.ContextMenu({
	x = 5, y = 5,
	w = 5,
	bc = colors.black,
	fc = colors.white,
})
surface:addChild(Context)

Context:add_element("TEST").pressed = function ()
	log("TEST")
end
Context:add_element("TEST2").pressed = function ()
	log("TEST2")
end
Context:add_element("TEST3").pressed = function ()
	log("TEST3")
end

surface.onResize = function(W, H)
	surface.w, surface.h = W, H
end

root:mainloop()
