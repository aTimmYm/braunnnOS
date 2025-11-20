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

-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
-- root:layoutChild()
-- dM.readShortcuts()
-- dM.makeDesktops(surface)
-- dM.makeShortcuts()
-- dM.setRadio(radioButton_horizontal)
-- radioButton_horizontal:changeCount(dM.updateNumDesks())
system.dekstop_manager()
-- if PALETTE[conf["palette"]] then
--     PALETTE[conf["palette"]]()
-- end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
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
