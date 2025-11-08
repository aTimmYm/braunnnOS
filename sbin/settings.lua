-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local pageBuffer
local settingsPath = "usr/settings.conf"
local conf = c.readConf(settingsPath)
local EVENTS = require("events")

local dropdownChooseArr = {}
for k, _ in pairs(EVENTS.PALETTE) do
    table.insert(dropdownChooseArr, k)
end
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(root,colors.white)
root:addChild(surface)

local label = UI.New_Label(root,"Settings",colors.white,colors.black)
label.reSize = function(self)
    self.pos.x = 2
    self.size.w = self.parent.size.w-self.pos.x
end
surface:addChild(label)

local buttonClose = UI.New_Button(root,"x",colors.white,colors.black)
buttonClose.reSize = function(self)
    self.pos.x = self.parent.size.w
end
surface:addChild(buttonClose)

local box = UI.New_Box(root,colors.black)
box.reSize = function(self)
    self.pos = {x=1,y=2}
    self.size = {w=11,h=self.parent.size.h-self.pos.y+1}
end
box.draw = function(self)
    c.drawFilledBox(self.pos.x,self.pos.y,self.size.w+self.pos.x-1,self.size.h+self.pos.y-1,self.bg)
    for i=self.pos.y,self.size.h+self.pos.y-1 do
        c.write("|",self.pos.x,i,self.bg,self.txtcol)
        c.write("|",self.size.w+self.pos.x-1,i,self.bg,self.txtcol)
    end
end
surface:addChild(box)

local label2 = UI.New_Label(root,"-DISPLAY-",colors.black,colors.lightGray)
label2.reSize = function(self)
    self.pos = {x=self.parent.pos.x+1,y=self.parent.pos.y+1}
    self.size.w = self.parent.size.w-self.pos.x
    self.size.h = 1
end
box:addChild(label2)

local buttonSCREEN = UI.New_Button(root,"SCREEN",colors.black,colors.white)
buttonSCREEN.reSize = function(self)
    self.pos = {x=self.parent.pos.x+1,y=label2.pos.y+1}
    self.size.w = self.parent.size.w-self.pos.x
end
box:addChild(buttonSCREEN)

local buttonTIME = UI.New_Button(root,"TIME&DATE",colors.black,colors.white)
buttonTIME.reSize = function(self)
    self.pos = {x=self.parent.pos.x+1,y=buttonSCREEN.pos.y+1}
    self.size.w = self.parent.size.w-self.pos.x
end
box:addChild(buttonTIME)

local buttonCOLORS = UI.New_Button(root, "COLORS", colors.black, colors.white)
buttonCOLORS.reSize = function(self)
    self.pos = {x=self.parent.pos.x+1,y=buttonTIME.pos.y+1}
    self.size.w = self.parent.size.w-self.pos.x
end
box:addChild(buttonCOLORS)

local page1 = UI.New_Box(root)
page1.reSize = function(self)
    self.pos = {x=box.size.w+box.pos.x,y=box.pos.y}
    self.size = {w=self.parent.size.w-self.pos.x+1,h=box.size.h}
end
surface:addChild(page1)

local tumblerLabel = UI.New_Label(root, "Monitor Mode")
tumblerLabel.reSize = function(self)
    self.pos = {x = self.parent.pos.x + 1, y = self.parent.pos.y + 1}
    self.size.w = #self.text
end
page1:addChild(tumblerLabel)

local monitorTumbler = UI.New_Tumbler(root,colors.white, colors.lightGray, colors.gray, conf["isMonitor"])
monitorTumbler.reSize = function(self)
    self.pos = {x = self.parent.size.w+self.parent.pos.x-3, y = tumblerLabel.pos.y}
end
page1:addChild(monitorTumbler)

local dropdownLabel = UI.New_Label(root, "Monitor Scale")
dropdownLabel.reSize = function(self)
    self.pos = {x = self.parent.pos.x + 1, y = tumblerLabel.pos.y + tumblerLabel.size.h+1}
    self.size.w = #self.text
end
page1:addChild(dropdownLabel)

local dropdown = UI.New_Dropdown(root, {"0.5","1","1.5","2","2.5","3","3.5","4","4.5","5"}, colors.white, colors.black, tostring(conf["monitorScale"]))
dropdown.reSize = function(self)
    self.pos = {x = self.parent.pos.x + self.parent.size.w - 1 - self.size.w, y = dropdownLabel.pos.y}
end
page1:addChild(dropdown)

local page2 = UI.New_Box(root)
page2.reSize = function(self)
    self.pos = {x=box.size.w+box.pos.x,y=box.pos.y}
    self.size = {w=self.parent.size.w-self.pos.x+1,h=box.size.h}
end

local time24FormatLabel = UI.New_Label(root, "Enable 24h format")
time24FormatLabel.reSize = function (self)
    self.pos = {x = self.parent.pos.x + 1, y = self.parent.pos.y + 1}
    self.size = {w = #self.text, h = 1}
end
page2:addChild(time24FormatLabel)

local time24FormatTumbler = UI.New_Tumbler(root, colors.lightGray, colors.gray, _, conf["24format"])
time24FormatTumbler.reSize = function (self)
    self.pos = {x = self.parent.pos.x + self.parent.size.w - 3, y = time24FormatLabel.pos.y}
end
page2:addChild(time24FormatTumbler)

local showSecondsLabel = UI.New_Label(root, "Show seconds")
showSecondsLabel.reSize = function (self)
    self.pos = {x = self.parent.pos.x + 1, y = self.parent.pos.y + 3}
    self.size = {w = #self.text, h = 1}
end
page2:addChild(showSecondsLabel)

local showSecondsTumbler = UI.New_Tumbler(root, colors.lightGray, colors.gray, _, conf["show_seconds"])
showSecondsTumbler.reSize = function (self)
    self.pos = {x = self.parent.pos.x + self.parent.size.w - 3, y = showSecondsLabel.pos.y}
end
page2:addChild(showSecondsTumbler)

local page3 = UI.New_Box(root)
page3.reSize = function(self)
    self.pos = {x=box.size.w+box.pos.x,y=box.pos.y}
    self.size = {w=self.parent.size.w-self.pos.x+1,h=box.size.h}
end

local labelCurrCols = UI.New_Label(root, "Current colors: ",colors.white,colors.black)
labelCurrCols.reSize = function(self)
    self.pos = {x = self.parent.pos.x+1, y = self.parent.pos.y + 1}
    self.size = {w = #self.text, h = 1}
end
page3:addChild(labelCurrCols)

local currCols = UI.New_Label(root)
currCols.reSize = function(self)
    self.pos = {x = labelCurrCols.pos.x + labelCurrCols.size.w + 1, y = labelCurrCols.pos.y}
    self.size = {w = #self.text, h = 1}
end
currCols.draw = function(self)
    c.write(" ", self.pos.x, self.pos.y, colors.black)
    c.write(" ", self.pos.x+1, self.pos.y, colors.white)
    c.write(" ", self.pos.x+2, self.pos.y, colors.lightGray)
    c.write(" ", self.pos.x+3, self.pos.y, colors.gray)

    c.write(string.char(149),self.pos.x-1,self.pos.y,colors.red,colors.black)
    c.write(string.char(149),self.pos.x+4,self.pos.y,colors.black,colors.red)
    c.write(string.char(144),self.pos.x+4,self.pos.y-1,colors.black,colors.red)
    c.write(string.char(129),self.pos.x+4,self.pos.y+1,colors.black,colors.red)
    c.write(string.char(159),self.pos.x-1,self.pos.y-1,colors.red,colors.black)
    c.write(string.char(130),self.pos.x-1,self.pos.y+1,colors.black,colors.red)
    c.write(string.rep(string.char(143),4),self.pos.x,self.pos.y-1,colors.red,colors.black)
    c.write(string.rep(string.char(131),4),self.pos.x,self.pos.y+1,colors.black,colors.red)
end
page3:addChild(currCols)

local chooseLabel = UI.New_Label(root, "Choose your palette: ")
chooseLabel.reSize = function(self)
    self.pos = {x = self.parent.pos.x+1, y = self.parent.pos.y + 3}
    self.size = {w = #self.text, h = 1}
end
page3:addChild(chooseLabel)

local dropdownChoose = UI.New_Dropdown(root, dropdownChooseArr, colors.white, colors.black, conf["palette"])
dropdownChoose.reSize = function(self)
    self.pos = {x = self.parent.pos.x + self.parent.size.w - 1 - self.size.w, y = self.parent.pos.y+3}
end
page3:addChild(dropdownChoose)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function setPage(page)
    surface:removeChild(pageBuffer)
    surface:addChild(page)
    pageBuffer = page
    surface:onLayout()
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function(self)
    self.root.running_program = false
end

buttonSCREEN.pressed = function(self)
    setPage(page1)
end

buttonTIME.pressed = function(self)
    setPage(page2)
end

buttonCOLORS.pressed = function(self)
    setPage(page3)
end

monitorTumbler.pressed = function(self)
    conf["isMonitor"] = not self.on
    c.saveConf(settingsPath, conf)
    c.playSound("minecraft:block.lever.click",3)
end

time24FormatTumbler.pressed = function(self)
    conf["24format"] = not self.on
    c.saveConf(settingsPath, conf)
end

showSecondsTumbler.pressed = function(self)
    conf["show_seconds"] = not self.on
    c.saveConf(settingsPath, conf)
end

dropdown.pressed = function(self)
    local val = tonumber(self.array[self.item_index])
    conf["monitorScale"] = val
    if bOS.monitor[1] then
        bOS.monitor[1].setTextScale(val) os.queueEvent("term_resize")
    end
    c.saveConf(settingsPath, conf)
    c.playSound("minecraft:block.lever.click",3)
end

dropdownChoose.pressed = function(self)
    if EVENTS.PALETTE[self.array[self.item_index]] then
        EVENTS.PALETTE[self.array[self.item_index]](conf,settingsPath)
        conf["palette"] = self.array[self.item_index]
        c.saveConf(settingsPath, conf)
    end
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------