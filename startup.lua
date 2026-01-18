function _G.log(text)
	text = tostring(text)
	local file = fs.open("log.txt", "a")
	file.write(text.."\n")
	file.close()
end

function _G.run_log_func(func, ...)
	local args = {...}
	local status, ret = pcall(func, table.unpack(args))
	if not status then log("["..os.date("%d/%m/%Y %X").."] "..ret) end
end

local w, h = term.getSize()
local display = window.create(term.current(), 1, 1, w,h)
local native = term.native()
display.setVisible(true)
term.redirect(display)
local blit_black = colors.toBlit(colors.black)
local blit_white = colors.toBlit(colors.white)
local selected = 1
local counter = 5
local launch_target = nil
local items = {"BraunnnOS", "CraftOS", "_startup"}

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
		term.write(items[i]..string.rep(" ", w - 6 - #items[i]))
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
	term.blit(string.char(151)..string.rep(string.char(131), w - 6)..string.char(148), string.rep(blit_white, w - 5)..blit_black, string.rep(blit_black, w - 5)..blit_white)
	for i = 5, h_m - 1 do
		term.setCursorPos(3, i)
		term.blit(string.char(149)..string.rep(" ", w - 6)..string.char(149), string.rep(blit_white, w - 5)..blit_black, string.rep(blit_black, w - 5)..blit_white)
	end
	term.setCursorPos(3, h_m - 1)
	term.blit(string.rep(string.char(131), w - 4), string.rep(blit_white, w - 4), string.rep(blit_black, w - 4))
	term.setCursorPos(3, h_m)
	term.write("Use the "..string.char(24).." and "..string.char(25).." keys to select.")
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
	os.cancelTimer(timer)
end

draw()
while true do
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
	draw()
	display.setVisible(true)
end
os.cancelTimer(timer)

display_destroy()

if launch_target == "/rom/programs/shell.lua" then
	term.setCursorPos(1, 1)
end

-- os.queueEvent("start_system")
local program = loadfile(launch_target, _ENV)
local ok, ret = pcall(program)
native_clear()


if not ok then -- BSOD:
	term.setCursorPos(1, 1)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.lightGray)
	term.clear()
	term.setCursorPos(1, 2)
	print(" Your PC has been crushed.")
	print(" Please, report to developers that error:")
	term.setTextColor(colors.yellow)
	print(" [" .. tostring(ret) .. "]")
	term.setTextColor(colors.white)
	read()
	os.reboot()
end

-- os.run(_ENV, launch_target)
-- native_clear()