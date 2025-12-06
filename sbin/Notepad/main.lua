------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local system = require("braunnnsys")
local screen = require("Screen")
local UI = require("ui")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local opened_file = nil
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "Notepad")

local menu = UI.New_Menu(1, 1, "File", {"New","Open", "Save", "Save as"}, colors.white, colors.black)
window:addChild(menu)

local textbox = UI.New_TextBox(1, 1, surface.w - 1, surface.h - 1, colors.black, colors.white)
surface:addChild(textbox)

local scrollbar_v = UI.New_Scrollbar(textbox)
surface:addChild(scrollbar_v)

local scrollbar_h = UI.New_Scrollbar_Horizontal(textbox)
surface:addChild(scrollbar_h)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
menu.pressed = function (self, id)
	if id == "New" then
		opened_file = nil
		textbox:clear()
		textbox.root.focus = textbox
	elseif id == "Open" then
		local path = UI.New_DialWin(" Open ", "Enter path to file:")
		if not path then
			window:onLayout()
			return
		end
		if not fs.exists(path) then
			UI.New_MsgWin("INFO", " Error ", "File not found")
			window:onLayout()
			return
		end
		textbox:clear()
		local i = 1
		for line in io.lines(path) do
			textbox:setLine(line, i)
			i = i + 1
		end
		opened_file = path
		window:onLayout()
		textbox.root.focus = textbox
	elseif id == "Save" then
		if opened_file then
			local file = fs.open(opened_file, "w")
			for _, v in pairs(textbox.lines) do
				file.writeLine(v)
			end
			file.close()
		end
	elseif id == "Save as" then
		local path = UI.New_DialWin(" Save as ", "Enter path to save:")
		if not path then
			window:onLayout()
			return
		end
		if fs.exists(path) then
			local answ = UI.New_MsgWin("YES,NO", " Message ", "File is already exists. Do you want to override it?")
			window:onLayout()
			if not answ then return end
		end
		local file = fs.open(path, "w")
		for _, v in pairs(textbox.lines) do
			file.writeLine(v)
		end
		file.close()
		if not opened_file then opened_file = path end
	end
end

surface.onResize = function (width, height)
	textbox.w = width - 1
	textbox.h = height - 1
	textbox.scrollbar_v.h = height - 1
	textbox.scrollbar_v.local_x = width
	textbox.scrollbar_h.w = width - 6
	textbox.scrollbar_h.local_y = height
end
-----------------------------------------------------
textbox.root.focus = textbox
surface:onLayout()