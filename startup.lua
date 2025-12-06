local screen = require("lib.Screen")
_G.window = {
	create = function (parent_term, x, y, w, h, visible)
		local window = {}
		local cursorX, cursorY = 1, 1
		local textColor = colors.white
		local bgColor = colors.black
		local cursorBlink = false

		-- Вспомогательная: Применить offset и клиппинг
		local function withClip(fn)
			screen.clip_set(x, y, w, h)
			fn()
			screen.clip_remove()
		end

		window.write = function(str)
			withClip(function()
				screen.write(tostring(str), x + cursorX - 1, y + cursorY - 1, bgColor, textColor)
			end)
			cursorX = cursorX + #str
		end

		window.blit = function(text, fg, bg)
			withClip(function()
				-- Поскольку blit ожидает hex-строки, используйте их напрямую (как в blittle_draw)
				local y_eff = y + cursorY - 1
				if y_eff >= 1 and y_eff <= root.h then  -- Простая проверка
					local frame = screen.get_buffer  -- Доступ к screenFrame (сделайте публичным или через getter, если нужно)
					local start = x + cursorX - 1
					local len = #text
					-- Патчинг как в write
					frame.text = string.sub(frame.text, 1, start - 1) .. text .. string.sub(frame.text, start + len)
					frame.color_txt = string.sub(frame.color_txt, 1, start - 1) .. fg .. string.sub(frame.color_txt, start + len)
					frame.color_bg = string.sub(frame.color_bg, 1, start - 1) .. bg .. string.sub(frame.color_bg, start + len)
				end
			end)
			cursorX = cursorX + #text
		end

		window.clear = function()
			withClip(function()
				screen.draw_rectangle(x, y, w, h, bgColor)
			end)
		end

		window.clearLine = function()
			withClip(function()
				screen.draw_rectangle(x, y + cursorY - 1, w, 1, bgColor)
			end)
		end

		window.setCursorPos = function(newX, newY)
			cursorX, cursorY = newX, newY
		end

		window.getCursorPos = function()
			return cursorX, cursorY
		end

		window.setTextColor = function(col) textColor = col end
		window.setTextColour = window.setTextColor
		window.setBackgroundColor = function(col) bgColor = col end
		window.setBackgroundColour = window.setBackgroundColor

		window.setCursorBlink = function(blink) cursorBlink = blink end
		window.getCursorBlink = function() return cursorBlink end

		window.getSize = function() return w, h end

		window.scroll = function(n)
			-- Реализуйте сдвиг буфера строк в области окна (сложно, но возможно: копировать строки в screenFrame с offset)
			-- Для простоты: если shell не использует scroll часто, можно пропустить или эмулировать clear + redraw
		end

		window.redraw = function()
			-- Не нужно, т.к. screen.draw() вызывается в root:mainloop
		end

		window.reposition = function(newX, newY, newW, newH)
			x, y, w, h = newX, newY, newW, newH
		end

		-- Добавьте другие методы term по необходимости (isColor, etc.)
		window.isColor = function() return true end
		window.isColour = window.isColor

		return window
	end
}

if bOS then error("System is already running!") end
_G.bOS = {}
bOS.start = bOS

if not fs.exists("usr") then fs.makeDir("usr") end
if not fs.exists("home/Music") then fs.makeDir("home/Music") end
if not fs.exists("usr/settings.conf") then
	local file = fs.open("usr/settings.conf","w")
	file.write("isMonitor=false\npalette=Default\nmonitorScale=1\n24format=true\nshow_seconds=false")
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

if bOS.monitor[2] and bOS.monitor[1] then
	local scale = conf["monitorScale"]
	if scale then bOS.monitor[1].setTextScale(scale) end
	shell.run("monitor "..peripheral.getName(bOS.monitor[1]).." init.lua")
else
	shell.run("init.lua")
end
_G.bOS = nil