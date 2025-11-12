-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local c = require("cfunc")
local UI = require("ui")
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local fslist = {} for i=1,64 do fslist[i]="Item - "..i end
local conf = c.readConf("usr/settings.conf")
local dropdown_array = {
    "One","Two","Three","Four", "Five", "Six"
}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(root,colors.lightGray)
root:addChild(surface)

local buttonClose = UI.New_Button(root,"x")
surface:addChild(buttonClose)

local buttonInfo = UI.New_Button(root,"?",colors.blue,colors.white)
buttonInfo.reSize = function (self)
    self.pos.x = buttonClose.pos.x+1
end
surface:addChild(buttonInfo)

local buttonError = UI.New_Button(root,"Error",colors.red,colors.white)
buttonError.reSize = function (self)
    self.pos.x = buttonInfo.pos.x+1
end
surface:addChild(buttonError)

local clock = UI.New_Clock(root,surface.bg,colors.white, conf["show_seconds"], conf["24format"])
clock.reSize = function (self)
    self.pos.x = self.parent.size.w + self.parent.pos.x - self.size.w
end
surface:addChild(clock)

local list = UI.New_List(root,fslist,colors.black,colors.white)
list.reSize = function (self)
    self.pos.x = math.ceil(self.parent.size.w/2)
    self.pos.y = self.parent.pos.y + 1
    self.size.w = math.floor(self.parent.size.w/2)-1
    self.size.h = self.parent.size.h-self.pos.y
end
surface:addChild(list)

local scrollbar = UI.New_Scrollbar(list)
scrollbar.reSize = function (self)
    self.pos.x = self.obj.pos.x + self.obj.size.w
    self.pos.y = self.obj.pos.y
    self.size.h = self.obj.size.h
end
surface:addChild(scrollbar)

local label = UI.New_Label(root,"Label",colors.white,colors.black)
label.reSize = function (self)
    self.pos.x = self.parent.pos.x + 1
    self.pos.y = self.parent.pos.y + 1
    self.size.w = list.pos.x - self.pos.x-1
end
surface:addChild(label)

local textfield = UI.New_Textfield(root,colors.white,colors.black)
textfield.reSize = function (self)
    self.pos.x = label.pos.x
    self.pos.y = label.pos.y + label.size.h+1
    self.size.w = label.size.w
end
surface:addChild(textfield)

local scrollBox = UI.New_ScrollBox(root,colors.brown)
scrollBox.reSize = function (self)
    self.pos = {x = 2, y = textfield.pos.y+2}
    self.size = {w = list.pos.x-self.pos.x-2, h = self.parent.size.h-self.pos.y}
    self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
end
surface:addChild(scrollBox)

local scrollbar2 = UI.New_Scrollbar(scrollBox)
scrollbar2.reSize = function (self)
    self.pos = {x = self.obj.pos.x + self.obj.size.w, y = self.obj.pos.y}
    self.size.h = self.obj.size.h
end
surface:addChild(scrollbar2)

local radioButton = UI.New_RadioButton(root,_,{"CAT","DOG"},scrollBox.bg)
radioButton.reSize = function (self)
    self.pos.x = self.parent.pos.x
    self.pos.y = self.parent.pos.y
end
scrollBox:addChild(radioButton)

local radioButton_horizontal = UI.New_RadioButton_horizontal(root,10,scrollBox.bg)
radioButton_horizontal.reSize = function (self)
    self.pos.x = scrollBox.size.w+scrollBox.pos.x-1 - self.size.w
    self.pos.y = textfield.pos.y + textfield.size.h+1
end
scrollBox:addChild(radioButton_horizontal)

local radioLabel = UI.New_Label(root, tostring(radioButton_horizontal.item), colors.white, colors.black)
radioLabel.reSize = function (self)
    self.pos = {x = radioButton_horizontal.pos.x, y = radioButton_horizontal.pos.y + 1}
    self.size = radioButton_horizontal.size
end
scrollBox:addChild(radioLabel)

local tumbler = UI.New_Tumbler(root, colors.white, colors.gray, colors.black, true)
tumbler.reSize = function (self)
    self.pos.x = self.parent.pos.x
    self.pos.y = radioButton.pos.y + radioButton.size.h+1
end
scrollBox:addChild(tumbler)

local tumblerLabel = UI.New_Label(root, "ON", scrollBox.bg, colors.white)
tumblerLabel.reSize = function (self)
    self.pos = {x = tumbler.pos.x + tumbler.size.w + 1, y = tumbler.pos.y}
    self.size.w = 3
end
scrollBox:addChild(tumblerLabel)

local checkbox = UI.New_Checkbox(root,_,_,true)
checkbox.reSize = function (self)
    self.pos = {x = self.parent.pos.x, y = tumbler.pos.y + tumbler.size.h + 1}
end
scrollBox:addChild(checkbox)

local checkboxLabel = UI.New_Label(root, "ON", scrollBox.bg, colors.white)
checkboxLabel.reSize = function (self)
    self.pos = {x = checkbox.pos.x + checkbox.size.w + 1, y = checkbox.pos.y}
    self.size.w = 3
end
scrollBox:addChild(checkboxLabel)

local dropdown = UI.New_Dropdown(root, dropdown_array, colors.white, colors.black)
dropdown.reSize = function (self)
    self.pos.x = self.parent.pos.x
    self.pos.y = checkbox.pos.y + checkbox.size.h + 1
end
scrollBox:addChild(dropdown)

local running_label = UI.New_Running_Label(root, "Some text here ")
running_label.reSize = function (self)
    self.pos = {x = tumblerLabel.pos.x + tumblerLabel.size.w + 1, y = tumblerLabel.pos.y}
    self.size = {w = 5, h = 1}
end
scrollBox:addChild(running_label)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------

-----------------------------------------------------
-----| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function (self)
    self.root.running_program = false
end

buttonInfo.pressed = function (self)
    local infoWin = UI.New_MsgWin(root,"INFO")
    infoWin:callWin(" INFO ","This is a polygon. A test file that displays all interface elements except shortcuts, as they are represented on the desktop you accessed (most likely).")
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
    self:onFocus(false)
    self.root.focus = nil
end

radioButton.pressed = function (self)
    label:setText(self.text[self.item])
end

radioButton_horizontal.pressed = function (self)
    radioLabel:setText(tostring(self.item))
end

tumbler.pressed = function (self)
    if self.on then
        tumblerLabel:setText("OFF")
    else
        tumblerLabel:setText("ON")
    end
end

checkbox.pressed = function (self)
    if self.on then
        checkboxLabel:setText("OFF")
    else
        checkboxLabel:setText("ON")
    end
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------