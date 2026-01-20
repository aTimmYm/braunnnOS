-- local expect = require "cc.expect"

local function create_file(path, text)
	local f = fs.open(path, "w")
	if text then f.writeLine(text) end
	f.close()
end

local function file_exists(path, text)
	if not fs.exists(path) then
		create_file(path, text)
	end
end

if not fs.exists("usr") then fs.makeDir("usr") end
if not fs.exists("home/Music") then fs.makeDir("home/Music") end
file_exists("usr/settings.conf", "isMonitor=false\npalette=Default\nmonitorScale=1\n24format=true\nshow_seconds=false\nDesktopMode=true")

local _system = {}

function _system.create_popup(items, x, y)
    
end

return _system