-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local c = require("cfunc")
local UI = require("ui")
local system = require("braunnnsys")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local fslist = {} for i=1,64 do fslist[i]="Item - "..i end
local conf = c.readConf("usr/settings.conf")
local dropdown_array = {
    "One","Two","Three","Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven"
}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.lightGray, "Polygon")

local buttonError = UI.New_Button(1, 1, 5, 1, "Error", _, colors.white, colors.red)
window:addChild(buttonError)

local buttonInfo = UI.New_Button(buttonError.x+buttonError.w+1, 1, 1, 1, "?", _, colors.white, colors.blue)
window:addChild(buttonInfo)

local list = UI.New_List(math.ceil(surface.w/2), 2, math.floor(surface.w/2) - 1, surface.h-2, fslist, colors.white, colors.black)
surface:addChild(list)

local clock = UI.New_Clock(list.x, 1, conf["show_seconds"], conf["24format"], surface.color_bg, colors.white)
surface:addChild(clock)

local scrollbar = UI.New_Scrollbar(list)
surface:addChild(scrollbar)

local label = UI.New_Label(2, 2, list.x - 1 - 2, 1, "Label", _, colors.white, colors.black)
surface:addChild(label)

local textfield = UI.New_Textfield(label.x, label.y + 2, label.w, 1, _, _,colors.white,colors.black)
surface:addChild(textfield)

local scrollBox = UI.New_ScrollBox(2, textfield.y + 2, list.x - 4, surface.h - 6, colors.brown)
surface:addChild(scrollBox)

local scrollbarBox = UI.New_Scrollbar(scrollBox)
surface:addChild(scrollbarBox)

local radioButton = UI.New_RadioButton(1, 1, _, {"CAT","DOG"}, scrollBox.color_bg)
scrollBox:addChild(radioButton)

local radioButton_horizontal = UI.New_RadioButton_horizontal(scrollBox.w - 9, 1, 10, scrollBox.color_bg)
scrollBox:addChild(radioButton_horizontal)

local radioLabel = UI.New_Label(radioButton_horizontal.x, radioButton_horizontal.y + 1, radioButton_horizontal.w, 1, tostring(radioButton_horizontal.item), _, colors.white, colors.black)
scrollBox:addChild(radioLabel)

local tumbler = UI.New_Tumbler(radioButton.x, radioButton.h + radioButton.y + 1, colors.white, colors.gray, colors.black, true)
scrollBox:addChild(tumbler)

local tumblerLabel = UI.New_Label(tumbler.x + tumbler.w + 1, tumbler.y, 3, 1, "ON", _, scrollBox.color_bg)
scrollBox:addChild(tumblerLabel)

local checkbox = UI.New_Checkbox(list.x - 7, radioLabel.y + 2, true, colors.black)
scrollBox:addChild(checkbox)

local checkboxLabel = UI.New_Label(checkbox.x + checkbox.w + 1, checkbox.y, 3, 1, "ON", _, scrollBox.color_bg)
scrollBox:addChild(checkboxLabel)

local running_label = UI.New_Running_Label(list.x - 7, checkbox.y + 2, 5, 1, "Some text here ")
scrollBox:addChild(running_label)

local slider = UI.New_Slider(1, running_label.y + 2, scrollBox.w, {1,2,3,4,5,6,7,8,9,10}, 5, colors.red, scrollBox.color_bg, colors.white)
scrollBox:addChild(slider)

local dropdown = UI.New_Dropdown(1, tumbler.y + 2, dropdown_array, _, _, _, colors.white, colors.black)
scrollBox:addChild(dropdown)

local textbox = UI.New_TextBox(2, slider.y + 2, scrollBox.w - 2, 5, colors.white, colors.black)
scrollBox:addChild(textbox)

textbox:setLine("Hello!", 1)
textbox:setLine("world", 2)
textbox:setLine("world", 4)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------

-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
local keyboard = false
buttonInfo.pressed = function (self)
    if not keyboard then
        system.call_keyboard()
        keyboard = true
    else
        system.remove_keyboard()
        keyboard = false
    end

    -- UI.New_MsgWin("INFO", " INFO ", "This is a polygon. A test file that displays all interface elements except shortcuts, as they are represented on the desktop you accessed (most likely).")
    -- window:onLayout()

end

buttonError.pressed = function (self)
    error("This is critical polygon error which closes it")
end

list.pressed = function (self)
    label:setText(list.item)
end

textfield.pressed = function (self)
    label:setText(textfield.text)
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

surface.onResize = function (width, height)
    list.local_x, list.local_y, list.w, list.h = math.ceil(width/2), 2, math.floor(width/2) - 1, height - 2
    label.w = list.local_x - label.local_x - 1
    clock.local_x, clock.local_y = list.local_x, 1
    textfield.w = list.local_x - textfield.local_x - 1
    scrollBox.w, scrollBox.h = list.local_x - 4, height - 6
    radioButton_horizontal.local_x, radioButton_horizontal.local_y = scrollBox.w - 9, radioButton.local_y
    radioLabel.local_x, radioLabel.local_y = radioButton_horizontal.local_x, radioButton_horizontal.local_y + 1
    checkbox.local_x, checkbox.local_y = scrollBox.w - 4, tumbler.local_y
    checkboxLabel.local_x, checkboxLabel.local_y = checkbox.local_x + checkbox.w + 1, checkbox.local_y
    running_label.local_x, running_label.local_y = scrollBox.w - 4, dropdown.local_y
    scrollbar.local_x, scrollbar.local_y, scrollbar.h = list.local_x + list.w, list.local_y, list.h
    slider.w = list.local_x - 3
    scrollbarBox.local_x, scrollbarBox.h = scrollBox.local_x + scrollBox.w, scrollBox.h
end
-----------------------------------------------------
surface:onLayout()