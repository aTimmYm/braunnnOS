------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_rep = string.rep
local table_insert = table.insert
local _max = math.max
local _min = math.min
local _floor = math.floor
local _ceil = math.ceil
-----------------------------------------------------
local dM = {} --deskManager

local UI = require "ui2"
local sys = require "sys"
-- local blittle = require "blittle_extended"

local root = UI.Root()
local global_menu

local context_menu = UI.ContextMenu(1, 1, colors.white, colors.black)
context_menu:add_item("New")
context_menu:add_item("Open")
context_menu:add_separator()
-- context_menu:add_chtoto("NEXT >")

local desktop = UI.Box(1, 2, root.w, root.h - 1, colors.lightBlue, colors.white)
root:addChild(desktop)

function dM.resize(width, height)
	desktop.w, desktop.h = width, height
end

function dM.draw()
	root:onLayout()
	root:redraw()
end

function dM.set_global_menu(menu)
	if not menu then
		root:removeChild(global_menu)
		global_menu = nil
		return
	end
	menu.x = 4
	menu.y = 1
	menu.color_bg = panel.color_bg
	menu.color_txt = panel.color_txt
	global_menu = menu
	root:addChild(global_menu)
end

function dM.event_handler(evt)
	if evt[1] == "mouse_click" and evt[2] == 2 then
		context_menu.x = evt[3]
		context_menu.y = evt[4]
		-- context_menu.visible = true
		root:addChild(context_menu)
		root.focus = context_menu
	-- else
	-- 	if not context_menu.visible then
	-- 		root:removeChild(context_menu)
	-- 		context_menu.visible = false
	-- 	end
	end
	root:onEvent(evt)
end

return dM