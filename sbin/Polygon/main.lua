-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local c = require("cfunc")
local UI = require("ui2")
local sys = require("syscalls")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local fslist = {} for i=1,64 do fslist[i]="Item - "..i end
local conf = c.readConf("usr/settings.conf")
local dropdown_array = {
	"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven"
}
local box_buffer = nil
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
sys.register_window("Polygon", 1, 1, 39, 14, true)

local function add_scrollbar(obj)
	obj.parent:addChild(UI.Scrollbar(obj))
end

local root = UI.Root()

-- local surface = UI.Box(1, 1, root.w, root.h, colors.lightGray, colors.white)
local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.lightGray,
	fc = colors.white,
})
root:addChild(surface)

-- local buttonError = UI.Button(1, 1, 5, 1, "Error", _, colors.white, colors.red)
local buttonError = UI.Button({x = 1, y = 1,
	w = 5, h = 1,
	text = "Error",
	bc = colors.white,
	fc = colors.red,
})
-- window:addChild(buttonError)

-- local buttonInfo = UI.Button(buttonError.x + buttonError.w + 1, 1, 1, 1, "?", _, colors.white, colors.blue)
local buttonInfo = UI.Button({
	x = buttonError.x + buttonError.w + 1, y = 1,
	w = 1, h = 1,
	text = "?",
	bc = colors.white,
	fc = colors.blue,
})
-- window:addChild(buttonInfo)

-- local list = UI.List(math.ceil(surface.w/2), 2, math.floor(surface.w/2) - 1, surface.h - 2, fslist, colors.white, colors.black)
local list = UI.List({
	x = math.ceil(surface.w/2), y = 2,
	w = math.floor(surface.w/2) - 1, h = surface.h - 2,
	array = fslist,
	bc = colors.white,
	fc = colors.black,
})
surface:addChild(list)

add_scrollbar(list)

local clock = UI.Clock({
	x = list.x, y = 1,
	show_seconds = conf["show_seconds"],
	is_24h = conf["24format"],
	bc = surface.bc,
	fc = colors.white,
})
surface:addChild(clock)

-- local label = UI.Label(2, 2, list.x - 1 - 2, 1, "Label", _, colors.white, colors.black)
local label = UI.Label({
	x = 2, y = 2,
	w = list.x - 1 - 2, h = 1,
	text = "Label",
	bc = colors.white,
	fc = colors.black,
})
surface:addChild(label)

-- local textfield = UI.Textfield(label.x, label.y + 2, label.w, 1, _, _,colors.white,colors.black)
local textfield = UI.Textfield({
	x = label.x, y = label.y + 2,
	w = label.w, h = 1,
	bc = colors.white,
	fc = colors.black
})
surface:addChild(textfield)

-- local tabbar = UI.TabBar(2, textfield.y + 2, textfield.w, 1, 1, {"ScrollBox", "SEST"}, colors.brown, colors.white)
local tabbar = UI.TabBar({
	x = 2, y = textfield.y + 2,
	w = textfield.w, h = 1,
	bc = colors.brown,
	fc = colors.white,
})
tabbar.tab_w = 11
surface:addChild(tabbar)

-- local scrollBox = UI.ScrollBox(2, tabbar.y + 1, list.x - 4, surface.h - 7, colors.brown)
local scrollBox = UI.ScrollBox({
	x = 2, y = tabbar.y + 1,
	w = list.x - 4, h = surface.h - 7,
	bc = colors.brown,
	fc = colors.white,
})
surface:addChild(scrollBox)
box_buffer = scrollBox

add_scrollbar(scrollBox)

-- local radioButton = UI.RadioButton(1, 1, _, {"CAT","DOG"}, scrollBox.color_bg)
local radioButton = UI.RadioButton({
	x = 1, y = 1,
	text = {"CAT","DOG"}, --???
	bc = scrollBox.bc,
	fc = colors.white,
})
scrollBox:addChild(radioButton)

-- local radioButton_horizontal = UI.RadioButton_horizontal(scrollBox.w - 9, 1, 10, scrollBox.color_bg)
local radioButton_horizontal = UI.RadioButton_horizontal({
	x = scrollBox.w - 9, y = 1,
	count = 10,
	bc = scrollBox.bc,
	fc = colors.white,
})
scrollBox:addChild(radioButton_horizontal)

-- local radioLabel = UI.Label(radioButton_horizontal.x, radioButton_horizontal.y + 1, radioButton_horizontal.w, 1, tostring(radioButton_horizontal.item), _, colors.white, colors.black)
local radioLabel = UI.Label({
	x = radioButton_horizontal.x, y = radioButton_horizontal.y + 1,
	w = radioButton_horizontal.w, h = 1,
	text = tostring(radioButton_horizontal.item),
	bc = colors.white,
	fc = colors.black
})
scrollBox:addChild(radioLabel)

-- local tumbler = UI.Tumbler(radioButton.x, radioButton.h + radioButton.y + 1, colors.white, colors.gray, colors.black, true)
local tumbler = UI.Tumbler({
	x = radioButton.x, y = radioButton.h + radioButton.y + 1,
	fc = colors.white,
	on = true,
})
scrollBox:addChild(tumbler)

local tumblerLabel = UI.Label({
	x = tumbler.x + tumbler.w + 1, y = tumbler.y,
	w = 3, h = 1,
	text = "ON",
	bc = scrollBox.bc,
	fc = colors.white,
})
scrollBox:addChild(tumblerLabel)

-- local checkbox = UI.Checkbox(list.x - 7, radioLabel.y + 2, true, colors.black)
local checkbox = UI.Checkbox({
	x = list.x - 7, y = radioLabel.y + 2,
	on = true,
	bc = colors.black,
	fc = colors.white,
})
scrollBox:addChild(checkbox)

local checkboxLabel = UI.Label({
	x = checkbox.x + checkbox.w + 1, y = checkbox.y,
	w = 3, h = 1,
	text = "ON",
	bc = scrollBox.bc,
	fc = colors.white,
})
scrollBox:addChild(checkboxLabel)

-- local running_label = UI.Running_Label(list.x - 7, checkbox.y + 2, 5, 1, "Some text here ")
local running_label = UI.Running_Label({
	x = list.x - 7, y = checkbox.y + 2,
	w = 5, h = 1,
	text = "Some text here ",
	bc = colors.blue,
	fc = colors.white,
})
scrollBox:addChild(running_label)

-- local slider = UI.Slider(1, running_label.y + 2, scrollBox.w, {1,2,3,4,5,6,7,8,9,10}, 5, colors.red, scrollBox.color_bg, colors.white)
local slider = UI.Slider({
	x = 1, y = running_label.y + 2,
	w = scrollBox.w,
	arr = {1,2,3,4,5,6,7,8,9,10},
	slidePosition = 5,
	fc = colors.white,
	bc = scrollBox.bc,
	fc_alt = colors.red,
	fc_cl = colors.lightGray,
})
scrollBox:addChild(slider)

-- local dropdown = UI.Dropdown(1, tumbler.y + 2, dropdown_array, _, _, _, colors.white, colors.black)
local dropdown = UI.Dropdown({
	x = 1, y = tumbler.y + 2,
	array = dropdown_array,
	bc = colors.white,
	fc = colors.black,
})
scrollBox:addChild(dropdown)

-- local textbox = UI.TextBox(2, slider.y + 2, scrollBox.w - 2, 7, colors.gray, colors.white)
local textbox = UI.TextBox({
	x = 2, y = slider.y + 2,
	w = scrollBox.w - 2, h = 7,
	bc = colors.gray,
	fc = colors.white
})
scrollBox:addChild(textbox)

add_scrollbar(textbox)

local Xscrollbar = UI.Scrollbar_Horizontal(textbox)
scrollBox:addChild(Xscrollbar)

-- local btnReadFile = UI.Button(textbox.x, textbox.y + textbox.h + 2, 4, 1, "Read", "center", colors.black, colors.yellow)
local btnReadFile = UI.Button({
	x = textbox.x, y = textbox.y + textbox.h + 2,
	w = 4, h = 1,
	text = "Read",
	align = "center",
	bc = colors.black,
	fc = colors.yellow,
	fc_hv = colors.yellow,
	bc_hv = colors.red,
})
scrollBox:addChild(btnReadFile)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------

-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonInfo.pressed = function (self)
	UI.MsgWin("INFO", " INFO ", "This is a polygon. A test file that displays all interface elements except shortcuts, as they are represented on the desktop you accessed (most likely).")
	window:onLayout()
end

buttonError.pressed = function (self)
	error("This is critical polygon error which closes it")
end

list.pressed = function (self, item)
	label:setText(item)
end

textfield.pressed = function (self)
	label:setText(textfield.text)
end

tabbar.pressed = function (self, name, index)
	--if self.item_index == index then return end
	if name == "ScrollBox" then
		surface:removeChild(box_buffer)
		surface:addChild(scrollBox)
		surface:addChild(scrollBox.scrollbar_v)
		rosurfaceot:onLayout()
	elseif name == "SEST" then
		surface:removeChild(box_buffer)
		surface:removeChild(box_buffer.scrollbar_v)
		surface:onLayout()
	end
end

radioButton.pressed = function (self)
	label:setText(self.text[self.item])
end

radioButton_horizontal.pressed = function (self)
	radioLabel:setText(tostring(self.item))
end

tumbler.pressed = function (self)
	tumblerLabel:setText(self.on and "OFF" or "ON")
end

checkbox.pressed = function (self)
	checkboxLabel:setText(self.on and "OFF" or "ON")
end

btnReadFile.pressed = function (self)
	local path = "manifest.txt"
	local i = 1
	for line in io.lines(path) do
	   textbox:setLine(line, i)
	   i = i + 1
	end
end

surface.onResize = function (width, height)
	surface.w, surface.h = width, height
	list.local_x, list.local_y, list.w, list.h = math.ceil(width/2), 2, math.floor(width/2) - 1, height - 2
	if list.scrollbar_v then
		local scrollbar = list.scrollbar_v
		scrollbar.local_x, scrollbar.local_y, scrollbar.h = list.local_x + list.w, list.local_y, list.h
	end
	label.w = list.local_x - label.local_x - 1
	clock.local_x, clock.local_y = list.local_x, 1
	textfield.w = list.local_x - textfield.local_x - 1
	scrollBox.w, scrollBox.h = list.local_x - 4, height - 7
	if scrollBox.scrollbar_v then
		local scrollbar = scrollBox.scrollbar_v
		scrollbar.local_x, scrollbar.local_y, scrollbar.h = scrollBox.local_x + scrollBox.w, scrollBox.local_y, scrollBox.h
	end
	radioButton_horizontal.local_x, radioButton_horizontal.local_y = scrollBox.w - 9, radioButton.local_y
	radioLabel.local_x, radioLabel.local_y = radioButton_horizontal.local_x, radioButton_horizontal.local_y + 1
	checkbox.local_x, checkbox.local_y = scrollBox.w - 4, tumbler.local_y
	checkboxLabel.local_x, checkboxLabel.local_y = checkbox.local_x + checkbox.w + 1, checkbox.local_y
	running_label.local_x, running_label.local_y = scrollBox.w - 4, dropdown.local_y
	slider.w = list.local_x - 3
	textbox.w = scrollBox.w - 2
	if textbox.scrollbar_v then
		local scrollbar = textbox.scrollbar_v
		scrollbar.local_x, scrollbar.local_y, scrollbar.h = textbox.local_x + textbox.w, textbox.local_y, textbox.h
	end
end
-----------------------------------------------------
root:mainloop()