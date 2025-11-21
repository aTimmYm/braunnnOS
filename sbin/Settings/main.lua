------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_rep = string.rep
local string_sub = string.sub
local string_char = string.char
local string_gmatch = string.gmatch
local table_insert = table.insert
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local c = require("cfunc")
local UI = require("ui")
local system = require("braunnnsys")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local pageBuffer
local settingsPath = "usr/settings.conf"
local conf = c.readConf(settingsPath)
local PALETTE = require("palette")
local version = "0.1"
local files_to_update = {}

local dropdownChooseArr = {}
for k, _ in pairs(PALETTE) do
    table_insert(dropdownChooseArr, k)
end
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "Settings")

local box = UI.New_Box(1, 1, 11, surface.h, colors.black)
box.draw = function (self)
    c.drawFilledBox(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1, self.color_bg)
    for i = self.y, self.h + self.y - 1 do
        c.write("|", self.x, i, self.color_bg, self.color_txt)
        c.write("|", self.w + self.x - 1, i, self.color_bg, self.color_txt)
    end
end
surface:addChild(box)

local displayLabel = UI.New_Label(2, 1, box.w - 2, 1, "-DISPLAY-", _, colors.black, colors.lightGray)
box:addChild(displayLabel)

local buttonSCREEN = UI.New_Button(2, displayLabel.y + 1, displayLabel.w, 1, "SCREEN", _, box.color_bg, colors.white)
box:addChild(buttonSCREEN)

local buttonTIME = UI.New_Button(2, buttonSCREEN.y + 1, buttonSCREEN.w, 1, "TIME&DATE",_, box.color_bg,colors.white)
box:addChild(buttonTIME)

local buttonCOLORS = UI.New_Button(2, buttonTIME.y + 1, buttonTIME.w, 1, "COLORS", _, box.color_bg, colors.white)
box:addChild(buttonCOLORS)

local systemLabel = UI.New_Label(2, buttonTIME.y + 1, box.w - 2, 1, "-SYSTEM--", _, box.color_bg, colors.lightGray)
box:addChild(systemLabel)

local buttonAbout = UI.New_Button(2, systemLabel.y + 1, systemLabel.w, 1, "ABOUT", _, box.color_bg, colors.white)
box:addChild(buttonAbout)

local page1 = UI.New_Box(box.w + 1, 1, surface.w - box.w, surface.h, colors.black)

local tumblerLabel = UI.New_Label(2, 2, 12, 1, "Monitor Mode", "left", page1.color_bg, colors.white)
page1:addChild(tumblerLabel)

local monitorTumbler = UI.New_Tumbler(page1.w - 2, tumblerLabel.y, colors.white, colors.lightGray, colors.gray, conf["isMonitor"])
page1:addChild(monitorTumbler)

local dropdownLabel = UI.New_Label(tumblerLabel.x, tumblerLabel.y + 2, 13, 1, "Monitor Scale", "left", page1.color_bg, colors.white)
page1:addChild(dropdownLabel)

local dropdown = UI.New_Dropdown(page1.w - 4, dropdownLabel.y, {"0.5","1","1.5","2","2.5","3","3.5","4","4.5","5"}, tostring(conf["monitorScale"]), _, _, colors.white, colors.black)
page1:addChild(dropdown)

local page2 = UI.New_Box(box.w + 1, 1, surface.w - box.w, surface.h, colors.black)

local time24FormatLabel = UI.New_Label(2,2, 17, 1, "Enable 24h format", "left", page2.color_bg, colors.white)
page2:addChild(time24FormatLabel)

local time24FormatTumbler = UI.New_Tumbler(page2.w - 2, time24FormatLabel.y, colors.lightGray, colors.gray, _, conf["24format"])
page2:addChild(time24FormatTumbler)

local showSecondsLabel = UI.New_Label(2, time24FormatLabel.y + 2, 12, 1, "Show seconds", "left", page2.color_bg, colors.white)
page2:addChild(showSecondsLabel)

local showSecondsTumbler = UI.New_Tumbler(page2.w - 2, showSecondsLabel.y, colors.lightGray, colors.gray, _, conf["show_seconds"])
page2:addChild(showSecondsTumbler)

local page3 = UI.New_Box(box.w + 1, 1, surface.w - box.w, surface.h, colors.black)

local labelCurrCols = UI.New_Label(2, 2, 16, 1, "Current colors: ", "left", colors.white, colors.black)
page3:addChild(labelCurrCols)

local currCols = UI.New_Label(labelCurrCols.x + labelCurrCols.w + 1, labelCurrCols.y, 4, 1)
currCols.draw = function (self)
    c.write(" ", self.x, self.y, colors.black)
    c.write(" ", self.x + 1, self.y, colors.white)
    c.write(" ", self.x + 2, self.y, colors.lightGray)
    c.write(" ", self.x + 3, self.y, colors.gray)

    c.write(string_char(149), self.x - 1, self.y, colors.red, colors.black)
    c.write(string_char(149), self.x + 4, self.y, colors.black, colors.red)
    c.write(string_char(144), self.x + 4, self.y - 1, colors.black, colors.red)
    c.write(string_char(129), self.x + 4, self.y + 1, colors.black, colors.red)
    c.write(string_char(159), self.x - 1, self.y - 1, colors.red, colors.black)
    c.write(string_char(130), self.x - 1, self.y + 1, colors.black, colors.red)
    c.write(string_rep(string_char(143), 4), self.x, self.y - 1, colors.red, colors.black)
    c.write(string_rep(string_char(131), 4), self.x, self.y + 1, colors.black, colors.red)
end
page3:addChild(currCols)

local chooseLabel = UI.New_Label(2, currCols.y + 2, 21, 1, "Choose your palette: ", _, page3.color_bg, colors.white)
page3:addChild(chooseLabel)

local dropdownChoose = UI.New_Dropdown(page3.w - 13, chooseLabel.y, dropdownChooseArr, conf["palette"], _, _, colors.white, colors.black)
page3:addChild(dropdownChoose)

local page4 = UI.New_Box(box.w + 1, 1, surface.w - box.w, surface.h, colors.black)
surface:addChild(page4)
pageBuffer = page4

local braunnnOS = UI.New_Label(2, 2, 9, 1, string_char(223).."raunnnOS", _, page4.color_bg, colors.white)
page4:addChild(braunnnOS)

local versionLabel = UI.New_Label(2, braunnnOS.y + 1, 12, 1, "Version "..version, _, page4.color_bg, colors.lightGray)
page4:addChild(versionLabel)

local buttonCheckUpdate = UI.New_Button(2, versionLabel.y + 1, 19, 1, "(CHECK FOR UPDATES)", _, page4.color_bg, colors.white)
-- buttonCheckUpdate.reSize = function (self)
--     if self.root.size.w <= 30 then
--         self.pos.x = self.parent.pos.x
--         self.pos.y = versionLabel.pos.y + 1
--         return
--     end
--     self.pos = {x=versionLabel.pos.x+versionLabel.size.w+1,y=versionLabel.pos.y}
-- end
page4:addChild(buttonCheckUpdate)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function setPage(page)
    if pageBuffer ~= page then
        surface:removeChild(pageBuffer)
        surface:addChild(page)
        pageBuffer = page
        surface:onLayout()
    end
end

local function write_file(path,data)
    local file = fs.open(path,"w")
    file.write(data)
    file.close()
end

local function translateServerManifest(manifest)
    local arr = {}
    for line in string_gmatch(manifest, "([^\n]+)\n?") do
        local key = string_sub(line, 1, 32)
        local value = string_sub(line, 36)
        arr[value] = key
    end
    return arr
end

local function checkUpdates(manifest)
    local ret = false
    local server_manifest, err = translateServerManifest(manifest)
    if server_manifest then
        local manifest_old = {}
        for line in io.lines("manifest.txt") do
            local key = string_sub(line, 1, 32)
            local value = string_sub(line, 36)
            manifest_old[value] = key
        end
        for file,_ in pairs(manifest_old) do
            if not server_manifest[file] then
                fs.delete(file)
                ret = true
            end
        end
        for file,hash in pairs(server_manifest) do
            if not manifest_old[file] or manifest_old[file] ~= hash then
                table_insert(files_to_update,file)
                ret = true
            end
        end
        return ret
    end
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonSCREEN.pressed = function (self)
    setPage(page1)
end

buttonTIME.pressed = function (self)
    setPage(page2)
end

buttonCOLORS.pressed = function (self)
    setPage(page3)
end

buttonAbout.pressed = function (self)
    setPage(page4)
end

monitorTumbler.pressed = function (self)
    conf["isMonitor"] = not self.on
    c.saveConf(settingsPath, conf)
    c.playSound("minecraft:block.lever.click",3)
end

time24FormatTumbler.pressed = function (self)
    conf["24format"] = not self.on
    c.saveConf(settingsPath, conf)
end

showSecondsTumbler.pressed = function (self)
    conf["show_seconds"] = not self.on
    c.saveConf(settingsPath, conf)
end

dropdown.pressed = function (self)
    local val = tonumber(self.array[self.item_index])
    conf["monitorScale"] = val
    if bOS.monitor[1] then
        bOS.monitor[1].setTextScale(val) os.queueEvent("term_resize")
    end
    c.saveConf(settingsPath, conf)
    c.playSound("minecraft:block.lever.click",3)
end

dropdownChoose.pressed = function (self)
    if PALETTE[self.array[self.item_index]] then
        PALETTE[self.array[self.item_index]]()
        conf["palette"] = self.array[self.item_index]
        c.saveConf(settingsPath, conf)
    end
end

buttonCheckUpdate.pressed = function (self)
    self:setText("(CHECKING)")
    self.w = #self.text
    local response, err = http.get("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/manifest.txt")
    local manifest = response.readAll()
    response.close()
    if response then
        if checkUpdates(manifest) then
            for _,v in pairs(files_to_update) do
                local request = http.get("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/"..v)
                if request then
                    write_file(v,request.readAll())
                    request.close()
                end
            end
            local file = fs.open("manifest.txt","w")
            file.write(manifest)
            file.close()
            self:setText("(SUCCESS INSTALLED)")
        else
            self:setText("(NO UPDATES)")
        end
        self.w = #self.text
        surface:onLayout()
    end
end
-----------------------------------------------------
surface:onLayout()