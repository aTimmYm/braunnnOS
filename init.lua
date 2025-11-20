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

dbg = c.DEBUG()
local root = UI.New_Root()
system.set_root(root)

system.dekstop_manager()

---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
bOS.init = nil
-----------------------------------------------------
