local sys = require "sys"
local UI = require "ui2"
local launchpad_pid = sys.getpid()

local SCREEN_WIDTH, SCREEN_HEIGHT = sys.screen_get_size()
local win = sys.register_window("Launchpad", 1, 1, SCREEN_WIDTH, SCREEN_HEIGHT, false)
win.maximize = true

local WIDTH_SHORT, HEIGHT_SHORT = 7, 5
local APPS_PATH = "sbin"
-- local APPS_LIST = fs.list(APPS_PATH)
local APPS_LIST = fs.list(APPS_PATH)
local pages = {}
local shortcuts = {}
local page_buffer
local def_ico = "sbin/Shell/icon3.ico"

local function Shortcut_pressed(self)
	sys.execute(self.filePath, self.text, _ENV)
	-- os.sleep(0.05)
	sys.process_end(launchpad_pid)
end

local root = UI.Root()

local launchpad = UI.Box(1, 1, root.w, root.h, colors.lightBlue, colors.white)
root:addChild(launchpad)

local search = UI.Textfield(math.floor((SCREEN_WIDTH - 10)/2)+1, 2, 10, 1, "search", false, colors.gray, colors.white)
launchpad:addChild(search)

local radio = UI.RadioButton_horizontal(math.floor((SCREEN_WIDTH -1)/2)+1, SCREEN_HEIGHT-2, 1, launchpad.color_bg, colors.white)
launchpad:addChild(radio)

for _, v in ipairs(APPS_LIST) do
	local path_ico
	if fs.exists("sbin/"..v.."/icon3.ico") then
		path_ico = "sbin/"..v.."/icon3.ico"
	else
		path_ico = def_ico
	end
	local shortcut = UI.Shortcut(1, 1, WIDTH_SHORT, HEIGHT_SHORT, v, "sbin/"..v.."/main.lua", path_ico, launchpad.color_bg, colors.white)
	shortcut.pressed = Shortcut_pressed
	table.insert(shortcuts, shortcut)
end

local function make_shortcut(page, start, _end)
	local temp = start
	for y = 1, page.h, HEIGHT_SHORT do
		for x = 1, page.w - WIDTH_SHORT + 1, WIDTH_SHORT + 1 do
			local shortcut = shortcuts[temp]

			shortcut.local_x, shortcut.local_y = x, y

			page:addChild(shortcut)
			temp = temp + 1
			if temp > _end then return end
		end
	end
end

local function build()
	-- for i = 3, #launchpad.children do
	pages = {}
	table.remove(launchpad.children, 3)
	-- end
	local app_count = #APPS_LIST
	-- desktops = get_desktops(ro)

	-- local maxCols = math.floor(SCREEN_WIDTH/(WIDTH_SHORT + 1 - 1))
	-- local maxRows = math.floor(SCREEN_HEIGHT/(HEIGHT_SHORT - 1))

	-- local num_pages = make_desktops(maxRows, maxCols)
	local page_width = math.floor((SCREEN_WIDTH - 9)/(WIDTH_SHORT + 1)) * (WIDTH_SHORT + 1) - 1
	local page_height = math.floor((SCREEN_HEIGHT - 6)/HEIGHT_SHORT) * HEIGHT_SHORT
	local max_rows = math.floor(page_height/HEIGHT_SHORT)
	local max_cols = math.floor(page_width/WIDTH_SHORT)
	local max_shorts = max_rows * max_cols
	local page_x = math.floor((SCREEN_WIDTH - page_width) / 2) + 1
	local page_y = math.floor((SCREEN_HEIGHT - page_height) / 2) + 1
	local num_pages = math.ceil(app_count / max_shorts)
	radio:changeCount(num_pages)
	radio.item = 1
	radio.local_x = math.floor((SCREEN_WIDTH - num_pages)/2)+1

	for i = 1, num_pages do
		local page = UI.Box(page_x, page_y, page_width, page_height, launchpad.color_bg, colors.white)

		make_shortcut(page, i * max_shorts - max_shorts + 1, math.min(app_count, max_shorts * i))

		table.insert(pages, page)
	end
	launchpad:addChild(pages[1])
	page_buffer = pages[1]
end

radio.pressed = function (self)
	if not page_buffer then return end
	local page = pages[self.item]
	launchpad:removeChild(page_buffer)
	launchpad:addChild(page)
	page_buffer = page
	page:onLayout()
end

launchpad.onResize = function (width, height)
	SCREEN_WIDTH, SCREEN_HEIGHT = width, height
	launchpad.w, launchpad.h = width, height
	search.local_x = math.floor((width - 10)/2)+1
	build()
	radio.local_y = height - 2
end

-- local root_onEvent = root.onEvent
-- root.onEvent = function (self, evt)
-- 	local event_name = evt[1]
-- 	local ret = root_onEvent(self, evt)
-- 	if not ret and event_name == "mouse_click" then
-- 		sys.process_end(launchpad_pid)
-- 		-- log("true")
-- 	end
-- end

build()

root:mainloop()