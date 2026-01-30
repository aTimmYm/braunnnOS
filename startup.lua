function _G.log(...)
	local texts = {...}
	local file = fs.open("log.txt", "a")
	for i, v in ipairs(texts) do
		if type(v) == "table" then
			v = textutils.serialise(v)
		else
			v = tostring(v)
		end
		file.write(v.."; ")
	end
	file.write("\n")
	file.close()
end

function _G.run_log_func(func, ...)
	local args = {...}
	local status, ret = pcall(func, table.unpack(args))
	if not status then log("["..os.date("%d/%m/%Y %X").."] "..ret) end
end

local w, h = term.getSize()
local display = window.create(term.current(), 1, 1, w, h, false)
local native = term.native()
-- display.setVisible(true)
term.redirect(display)
local blit_black = colors.toBlit(colors.black)
local blit_white = colors.toBlit(colors.white)
local selected = 1
local counter = 5
local launch_target = nil
local items = {"BraunnnOS", "CraftOS"}

local function display_destroy()
	display.setVisible(true)
	display.clear()
	local W, H = term.native().getSize()
	display.setCursorPos(1, H)
	display = nil
	term.redirect(native)
end

local function native_clear()
	term.redirect(native)
	term.clear()
	term.setCursorPos(1,1)
end

local function select_draw()
	for i = 1, #items do
		local sel = (selected == i)
		term.setTextColor(sel and colors.black or colors.white)
		term.setBackgroundColor(sel and colors.white or colors.black)
		term.setCursorPos(4, i + 4)
		local da = sel and "\7" or " "
		term.write(da..items[i]..string.rep(" ", w - 7 - #items[i]))
	end
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
end

local function draw()
	local h_m = math.floor((h*0.86))
	local title = "SLoader version 1.0"
	term.clear()
	term.setCursorPos(math.floor((w - #title)/2), 2)
	term.setTextColor(colors.lightGray)
	term.write(title)
	term.setCursorPos(3, 4)
	term.blit("\151"..string.rep("\131", w - 6).."\148", string.rep(blit_white, w - 5)..blit_black, string.rep(blit_black, w - 5)..blit_white)
	for i = 5, h_m - 1 do
		term.setCursorPos(3, i)
		term.blit("\149"..string.rep(" ", w - 6).."\149", string.rep(blit_white, w - 5)..blit_black, string.rep(blit_black, w - 5)..blit_white)
	end
	term.setCursorPos(3, h_m - 1)
	term.blit(string.rep("\131", w - 4), string.rep(blit_white, w - 4), string.rep(blit_black, w - 4))
	term.setCursorPos(3, h_m)
	term.write("Use the ".."\24".." and ".."\25".." keys to select.")
	term.setCursorPos(3, h_m + 1)
	term.write("Press enter to boot the selected OS.")
	term.setCursorPos(3, h_m + 2)
	if counter then term.write("Selected booted after: "..counter.." seconds") end
	select_draw()
end

local timer = os.startTimer(1)

local function set_target()
	if selected == 1 then
		launch_target = "kernel.lua"
	elseif selected == 2 then
		launch_target = "/rom/programs/shell.lua"
	elseif selected == 3 then
		launch_target = "_startup.lua"
	end
end

while true do
	draw()
	display.setVisible(true)
	display.setVisible(false)
	local evt = {os.pullEventRaw()}
	if evt[1] == "terminate" then
		display_destroy()
		native_clear()
		return
	elseif evt[1] == "term_resize" then
		w, h = native.getSize()
		display.reposition(1,1,w,h)
	elseif evt[1] == "key" then
		os.cancelTimer(timer)
		counter = nil
		if evt[2] == keys.down then
			selected = math.min(#items, selected + 1)
		elseif evt[2] == keys.up then
			selected = math.max(1, selected - 1)
		elseif evt[2] == keys.enter then
			set_target()
			break
		end
	elseif evt[1] == "timer" and evt[2] == timer then
		counter = counter - 1
		if counter < 1 then
			set_target()
			break
		end
		timer = os.startTimer(1)
	end
end

display_destroy()

if launch_target == "/rom/programs/shell.lua" then
	term.setCursorPos(1, 1)
end

local program = loadfile(launch_target, _ENV)
local ok, ret = xpcall(program, debug.traceback)
native_clear()

local blittle = require("blittle_extended")

local function QR_draw(W, H)
	local padding_w = 16
	local padding_h = 11

	blittle.draw(blittle.load("QR_code.ico"), 2, 2)

	term.setCursorPos(1,1)
	term.setTextColor(colors.lightGray)
	term.setBackgroundColor(colors.white)
	term.write("\159")
	term.write(string.rep("\143", padding_w - 1))
	for i = 2, padding_h do
		term.setCursorPos(1, i)
		term.write("\149")
	end
end

local function BSOD_draw()
	local w, h = term.getSize()
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.lightGray)
	term.clear()
	if w > 30 and h > 25 then QR_draw(w, h) end
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.lightGray)
	term.setCursorPos(1, 13)
	term.setCursorPos(1, 14)
	print(" Your PC has been crushed.")
	print(" Please, report to developers that error:")
	term.setTextColor(colors.yellow)
	print(" [" .. tostring(ret) .. "]")
	term.setTextColor(colors.white)
	print(" Press any key to reboot.")
end

if not ok then
	BSOD_draw()
	while true do
		local e = os.pullEventRaw()
		if e == "key" or e == "terminate" then break end
		if e == "term_resize" then BSOD_draw() end
	end
	os.reboot()
end

-- os.run(_ENV, launch_target)
-- native_clear()