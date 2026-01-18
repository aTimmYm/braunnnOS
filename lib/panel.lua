local sys = require "sys"
local UI = require "ui2"
local panel_pid = sys.getpid()

local SCREEN_WIDTH, SCREEN_HEIGHT = sys.screen_get_size()

sys.register_window("panel", 1, 1, SCREEN_WIDTH, 1, false, 0)

local root = UI.Root()

local panel = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
root:addChild(panel)

local button_menu = UI.Button(1, 1, 3, 1, string.char(223), _, colors.lightGray, panel.color_bg, panel.color_txt)
panel:addChild(button_menu)

local clock = UI.Clock(panel.w - 7, 1, true, true, panel.color_bg, panel.color_txt)
panel:addChild(clock)

panel.onResize = function (width, height)
    SCREEN_WIDTH, SCREEN_HEIGHT = width, height
    panel.w = width
    clock.local_x = panel.w - 7
    os.queueEvent("wm_reposition", panel_pid, 1, 1, width, 1)
end

root:mainloop()