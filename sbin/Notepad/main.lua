------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local sys = require("sys")
local UI = require("ui2")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local opened_file = nil
local args = {...}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
-- local window, root = sys.add_window("Titled", colors.black, "Notepad")
local global_menu = UI.Menu()

sys.register_window("Notepad", 1, 1, 39, 14, true)

local root = UI.Root()

local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
root:addChild(surface)

-- local menu = UI.Menu(1, 1, "File", {"New", "Open", "Save", "Save as"}, colors.white, colors.black)
-- window:addChild(menu)

local textbox = UI.TextBox(1, 1, surface.w - 1, surface.h - 1, surface.color_bg, colors.white)
surface:addChild(textbox)
if args[1] then
	local i = 1
	for line in io.lines(args[1]) do
		textbox:setLine(line, i)
		i = i + 1
	end
end

local scrollbar_v = UI.Scrollbar(textbox)
surface:addChild(scrollbar_v)

local scrollbar_h = UI.Scrollbar_Horizontal(textbox)
surface:addChild(scrollbar_h)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
-- menu.pressed = function (self, id)
-- 	if id == "New" then
-- 		opened_file = nil
-- 		textbox:clear()
-- 		root.focus = textbox
-- 	elseif id == "Open" then
-- 		local path = UI.DialWin(" Open ", "Enter path to file:")
-- 		if not path then
-- 			-- window:onLayout()
-- 			return
-- 		end
-- 		if not fs.exists(path) then
-- 			UI.MsgWin("INFO", " Error ", "File not found")
-- 			-- window:onLayout()
-- 			return
-- 		end
-- 		textbox:clear()
-- 		local i = 1
-- 		for line in io.lines(path) do
-- 			textbox:setLine(line, i)
-- 			i = i + 1
-- 		end
-- 		opened_file = path
-- 		-- window:onLayout()
-- 		root.focus = textbox
-- 	elseif id == "Save" then
-- 		if opened_file then
-- 			local file = fs.open(opened_file, "w")
-- 			for _, v in pairs(textbox.lines) do
-- 				file.writeLine(v)
-- 			end
-- 			file.close()
-- 		end
-- 	elseif id == "Save as" then
-- 		local path = UI.DialWin(" Save as ", "Enter path to save:")
-- 		if not path then
-- 			window:onLayout()
-- 			return
-- 		end
-- 		if fs.exists(path) then
-- 			local answ = UI.MsgWin("YES,NO", " Message ", "File is already exists. Do you want to override it?")
-- 			window:onLayout()
-- 			if not answ then return end
-- 		end
-- 		local file = fs.open(path, "w")
-- 		for _, v in pairs(textbox.lines) do
-- 			file.writeLine(v)
-- 		end
-- 		file.close()
-- 		if not opened_file then opened_file = path end
-- 	end
-- end

local file = global_menu:add_context("File")
file:add_item("New").pressed = function (self)
	opened_file = nil
	textbox:clear()
	root.focus = textbox
end
file:add_item("Open").pressed = function (self)
	local path = UI.DialWin(" Open ", "Enter path to file:")
	if not path then
		-- window:onLayout()
		return
	end
	if not fs.exists(path) then
		UI.MsgWin("INFO", " Error ", "File not found")
		-- window:onLayout()
		return
	end
	textbox:clear()
	local i = 1
	for line in io.lines(path) do
		textbox:setLine(line, i)
		i = i + 1
	end
	opened_file = path
	-- window:onLayout()
	root.focus = textbox
end
file:add_item("Save").pressed = function (self)
	if opened_file then
		local file = fs.open(opened_file, "w")
		for _, v in pairs(textbox.lines) do
			file.writeLine(v)
		end
		file.close()
	end
end
file:add_item("Save as").pressed = function (self)
	local path = UI.DialWin(" Save as ", "Enter path to save:")
	if not path then
		-- window:onLayout()
		return
	end
	if fs.exists(path) then
		local answ = UI.MsgWin("YES,NO", " Message ", "File is already exists. Do you want to override it?")
		-- window:onLayout()
		if not answ then return end
	end
	local file = fs.open(path, "w")
	for _, v in pairs(textbox.lines) do
		file.writeLine(v)
	end
	file.close()
	if not opened_file then opened_file = path end
end

surface.onResize = function (width, height)
	textbox.w = width - 1
	textbox.h = height - 1
	textbox.scrollbar_v.h = height - 1
	textbox.scrollbar_v.local_x = width
	textbox.scrollbar_h.w = width - 1
	textbox.scrollbar_h.local_y = height
end
-----------------------------------------------------
root.focus = textbox
root:mainloop()