if bOS then error("System is already running!") end
_G.bOS = {}
bOS.start = bOS

local sysConf = {
    "Explorer sbin/explorer.lua sbin/ico/explorer.ico",
    "Shell sbin/shell.lua sbin/ico/shell.ico",
    "Settings sbin/settings.lua sbin/ico/settings.ico",
    "Calculator sbin/calculator.lua sbin/ico/calculator.ico",
    "MPlayer sbin/MPlayer.lua sbin/ico/player.ico",
    "Polygon sbin/polygon.lua sbin/ico/default.ico",
    "IMGBlittle utility/ImageBLITTLE.lua sbin/ico/default.ico",
    "Paint rom/programs/fun/advanced/paint.lua sbin/ico/default.ico",
    "converter sbin/shell.lua sbin/ico/default.ico",
    "Messenger sbin/messenger.lua sbin/ico/messenger.ico"
}

if not fs.exists("usr") then fs.makeDir("usr") end
if not fs.exists("home/Music") then fs.makeDir("home/Music") end
if not fs.exists("usr/settings.conf") then
    local file = fs.open("usr/settings.conf","w")
    file.write("isMonitor=false\npalette=Default\nmonitorScale=1\n24format=true\nshow_seconds=false")
    file.close()
end
if not fs.exists("usr/sys.conf") then
    local file = fs.open("usr/sys.conf","w")
    for _,v in pairs(sysConf) do
    file.write(v.."\n")
    end
    file.close()
end
local c = require("lib.cfunc")
local conf = c.readConf("usr/settings.conf")

if peripheral.find("speaker") then
    bOS.speaker = peripheral.find("speaker")
end

if peripheral.find("modem") then
    bOS.modem = peripheral.find("modem")
end

bOS.monitor = {}
if peripheral.find("monitor") then
    bOS.monitor[1] = peripheral.find("monitor")
    bOS.monitor[2] = conf["isMonitor"]
end

if mobile then mobile.openKeyboard(false) end
--pcall(mobile.openKeyboard,false)

if bOS.monitor[2] and bOS.monitor[1] then
    local scale = conf["monitorScale"]
    if scale then bOS.monitor[1].setTextScale(scale) end
    shell.run("monitor "..peripheral.getName(bOS.monitor[1]).." init.lua")
else
    shell.run("init.lua")
end
_G.bOS = nil