-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
if bOS.init then error("bOS is already running!") end
bOS.init = true
package.path = package.path .. ";/lib/?" .. ";/lib/?.lua"
local c = require("cfunc")
local UI = require("ui")
local PALETTE = require("palette")
local conf = c.readConf("usr/settings.conf")
local dM = require("deskManager")
local screen = require("Screen")
local system = require("braunnnsys")

dbg = c.DEBUG()
local root = UI.New_Root()
system.set_root(root)

local keyboard = UI.New_Keyboard(root.w, root.h)
system.set_keyboard(keyboard)
root.keyboard = keyboard

system.dekstop_manager()

---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
while root.running_program do
    local ret, run_err = pcall(root.mainloop, root)
    if not ret then
        UI.New_MsgWin("INFO", "Error", run_err)
    end
end
bOS.init = nil
-----------------------------------------------------
