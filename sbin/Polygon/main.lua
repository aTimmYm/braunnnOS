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
    "One","Two","Three","Four", "Five", "Six"
}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.lightGray, "Polygon")

local buttonInfo = UI.New_Button(1, 1, 1, 1, "?", _, colors.white, colors.black)
window:addChild(buttonInfo)

local buttonError = UI.New_Button(buttonInfo.x + 1, 1, 5, 1, "Error", _, colors.white, colors.black)
window:addChild(buttonError)

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

local scrollBox = UI.New_ScrollBox(2, textfield.y + 3, list.x - 3, surface.h - 6, colors.brown)
surface:addChild(scrollBox)

-- local scrollbar2 = UI.New_Scrollbar(scrollBox)
-- scrollbar2.reSize = function (self)
--     self.pos = {x = self.obj.pos.x + self.obj.size.w, y = self.obj.pos.y}
--     self.size.h = self.obj.size.h
-- end
-- surface:addChild(scrollbar2)

local radioButton = UI.New_RadioButton(1, 1, _, {"CAT","DOG"}, scrollBox.color_bg)
scrollBox:addChild(radioButton)

local radioButton_horizontal = UI.New_RadioButton_horizontal(scrollBox.w - 9, radioButton.y, 10, scrollBox.color_bg)
scrollBox:addChild(radioButton_horizontal)

local radioLabel = UI.New_Label(radioButton_horizontal.x, radioButton_horizontal.y + 1, radioButton_horizontal.w, 1, tostring(radioButton_horizontal.item), _, colors.white, colors.black)
scrollBox:addChild(radioLabel)

local tumbler = UI.New_Tumbler(radioButton.x, radioButton.h + radioButton.y + 1, colors.white, colors.gray, colors.black, true)
scrollBox:addChild(tumbler)

local tumblerLabel = UI.New_Label(tumbler.x + tumbler.w + 1, tumbler.y, 3, 1, "ON", _, scrollBox.color_bg)
scrollBox:addChild(tumblerLabel)

local checkbox = UI.New_Checkbox(list.x - 7, tumbler.y, true, colors.black)
scrollBox:addChild(checkbox)

local checkboxLabel = UI.New_Label(checkbox.x + checkbox.w + 1, checkbox.y, 3, 1, "ON", _, scrollBox.color_bg)
scrollBox:addChild(checkboxLabel)

local dropdown = UI.New_Dropdown(tumbler.x, tumbler.y + 2, dropdown_array, _, _, _, colors.white, colors.black)
scrollBox:addChild(dropdown)

local running_label = UI.New_Running_Label(list.x - 7, dropdown.y, 5, 1, "Some text here ")
scrollBox:addChild(running_label)

local slider = UI.New_Slider(dropdown.x, dropdown.y + 2, list.x - 3, {1,2,3,4,5,6,7,8,9,10}, 5, colors.red, scrollBox.color_bg, colors.white)
scrollBox:addChild(slider)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------

-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonInfo.pressed = function (self)
    -- local infoWin = UI.New_MsgWin(root,"INFO")
    -- infoWin:callWin(" INFO ","This is a polygon. A test file that displays all interface elements except shortcuts, as they are represented on the desktop you accessed (most likely).")
    if surface:removeChild(list) then
        surface:onLayout()
    else
        surface:addChild(list)
    end

end

buttonError.pressed = function (self)
    if self.text == "-" then self:setText("+") else self:setText("-") end
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
    list.local_x, list.local_y, list.w, list.h = math.ceil(surface.w/2), 2, math.floor(surface.w/2) - 1, surface.h - 2
    label.w = list.local_x - label.local_x - 1
    clock.local_x, clock.local_y = list.local_x, 1
    textfield.w = list.local_x - textfield.local_x - 1
    scrollBox.w, scrollBox.h = list.local_x - 3, surface.h - 6
    scrollBox.win.reposition(2, textfield.y+2, list.local_x - 3, surface.h - 6)
    radioButton_horizontal.local_x, radioButton_horizontal.local_y = scrollBox.w - 9, radioButton.local_y
    radioLabel.local_x, radioLabel.local_y = radioButton_horizontal.local_x, radioButton_horizontal.local_y + 1
    checkbox.local_x, checkbox.local_y = scrollBox.w - 4, tumbler.local_y
    checkboxLabel.local_x, checkboxLabel.local_y = checkbox.local_x + checkbox.w + 1, checkbox.local_y
    running_label.local_x, running_label.local_y = scrollBox.w - 4, dropdown.local_y
    scrollbar.local_x, scrollbar.local_y, scrollbar.h = list.local_x + list.w, list.local_y, list.h
    slider.w = list.local_x - 3
end
-----------------------------------------------------