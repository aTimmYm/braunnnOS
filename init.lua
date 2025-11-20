-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
if bOS.init then error("bOS is already running!") end
bOS.init = true
package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local c = require("cfunc")
local system = require("braunnnsys")
local UI = require("ui")
local PALETTE = require("palette")
local conf = c.readConf("usr/settings.conf")
local dM = require("deskManager")
os.loadAPI("lib/blittle")
dbg = c.DEBUG()
local root = UI.New_Root()
system.set_root(root)
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------

-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(1, 1, root.w, root.h, colors.green)
root:addChild(surface)

local polyButton = UI.New_Button(2, 2, 7, 1, "POLYGON", _, colors.yellow, colors.black)
surface:addChild(polyButton)
--[[
local radioButton_horizontal = UI.New_RadioButton_horizontal(root,1,colors.black,colors.white)
radioButton_horizontal.reSize = function (self)
    self.pos = {x = math.floor((self.parent.size.w-self.size.w)/2)+1,y = self.parent.size.h}
end
surface:addChild(radioButton_horizontal)

local btnReboot = UI.New_Button(root,"Reboot",colors.black,colors.lightGray)
btnReboot.reSize = function(self)
    self.pos = {x = self.parent.size.w - self.size.w, y = 1}
end
surface:addChild(btnReboot)

local btnExit = UI.New_Button(root,"Shutdown",colors.black,colors.lightGray)
btnExit.reSize = function(self)
    self.pos = {x = btnReboot.pos.x - self.size.w - 1, y = btnReboot.size.h}
end
surface:addChild(btnExit)

local btnSpeaker = UI.New_Button(root,"SPEAKER",colors.black,colors.lightGray)
btnSpeaker.reSize = function(self)
    self.pos = {x = btnExit.pos.x - self.size.w - 1, y = btnExit.size.h}
end
surface:addChild(btnSpeaker)

local btnDebug = UI.New_Button(root,"DEBUGGER",colors.black,colors.lightGray)
btnDebug.reSize = function(self)
    self.pos = {x = btnSpeaker.pos.x - self.size.w - 1, y = btnExit.size.h}
end
surface:addChild(btnDebug)

local btnModem = UI.New_Button(root,"MODEM",colors.black,colors.lightGray)
btnModem.reSize = function(self)
    self.pos = {x = btnDebug.pos.x - self.size.w - 1, y = btnDebug.size.h}
end
surface:addChild(btnModem)]]
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
-- root:layoutChild()
-- dM.readShortcuts()
-- dM.makeDesktops(surface)
-- dM.makeShortcuts()
-- dM.setRadio(radioButton_horizontal)
-- radioButton_horizontal:changeCount(dM.updateNumDesks())

-- if PALETTE[conf["palette"]] then
--     PALETTE[conf["palette"]]()
-- end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
polyButton.pressed = function (self)
    local func, load_err = loadfile("sbin/Polygon/main.lua", _ENV)  -- "t" для text, или "bt" если нужно
    if not func then
        error(load_err)
    else
        -- M.termClear()
        local ret, exec_err = pcall(func)
        if not ret then
            error(exec_err)
        end
    end
    root:onLayout()
end
--[[
radioButton_horizontal.pressed = function(self)
    dM.selectDesk(self.item,self)
    self.parent:onLayout()
end

btnReboot.pressed = function(self)
    c.termClear()
    print("Rebooting...")
    os.sleep(0.1)
    c.termClear()
    os.reboot()
end

btnExit.pressed = function(self)
    root.running_program = false
end

btnSpeaker.pressed = function(self)
    if periphemu then periphemu.create("right", "speaker") end
    bOS.speaker = peripheral.find("speaker")
end

btnDebug.pressed = function(self)
    if periphemu then periphemu.create("left", "debugger") end
end

btnModem.pressed = function(self)
    if periphemu then periphemu.create("top", "modem") end
end

root.tResize = function(self)
    c.termClear(self.bg)
    self.size.w, self.size.h = term.getSize()
    dM.tResize()
    self:onLayout()
end]]
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
bOS.init = nil
-----------------------------------------------------
