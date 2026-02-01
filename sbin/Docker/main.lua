-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local sys = require "syscalls"
local UI = require "ui2"
local blittle = require "blittle_extended"
local S_WIDTH, S_HEIGHT = sys.screen_get_size()
sys.register_window("docker", 1, 1, 1, 2, false, 3)
local root = UI.Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local self_pid = sys.getpid()
local PINS_FILE = "sbin/Docker/Data/dock_pins"
local dock_items = {
	{	path = _,
		name = "Launchpad",
		pid = nil,
		pinned = true,
		icon = "sbin/Docker/Data/launch.ico" -- Тут нужна логика поиска иконки по пути
	}
}
local hidden = false
local popup = {}
local APPS_PATH = "sbin"
local DEF_ICO = "sbin/Shell/icon3.ico"
local pages = {}
local page_buffer
local APPS_LIST
local WIDTH_SHORT, HEIGHT_SHORT = 7, 5
local shortcuts = {}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local launchpad

-- local docker = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
local docker = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.gray,
	fc = colors.white,
})
root:addChild(docker)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
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

local function build_launchpad(radio)
	-- for i = 3, #launchpad.children do
	pages = {}
	table.remove(launchpad.children, 3)
	-- end
	local app_count = #APPS_LIST
	-- desktops = get_desktops(ro)

	-- local maxCols = math.floor(S_WIDTH/(WIDTH_SHORT + 1 - 1))
	-- local maxRows = math.floor(S_HEIGHT/(HEIGHT_SHORT - 1))

	-- local num_pages = make_desktops(maxRows, maxCols)
	local page_width = math.floor((S_WIDTH - 9)/(WIDTH_SHORT + 1)) * (WIDTH_SHORT + 1) - 1
	local page_height = math.floor((S_HEIGHT - 6)/HEIGHT_SHORT) * HEIGHT_SHORT
	local max_rows = math.floor(page_height/HEIGHT_SHORT)
	local max_cols = math.floor(page_width/WIDTH_SHORT)
	local max_shorts = max_rows * max_cols
	local page_x = math.floor((S_WIDTH - page_width) / 2) + 1
	local page_y = math.floor((S_HEIGHT - page_height) / 2) + 1
	local num_pages = math.ceil(app_count / max_shorts)
	radio:changeCount(num_pages)
	radio.item = 1
	radio.local_x = math.floor((S_WIDTH - num_pages)/2)+1

	for i = 1, num_pages do
		-- local page = UI.Box(page_x, page_y, page_width, page_height, launchpad.color_bg, colors.white)
		local page = UI.Box({
			x = page_x, y = page_y,
			w = page_width, h = page_height,
			bc = launchpad.bc,
			fc = colors.white,
		})

		make_shortcut(page, i * max_shorts - max_shorts + 1, math.min(app_count, max_shorts * i))

		table.insert(pages, page)
	end
	launchpad:addChild(pages[1])
	page_buffer = pages[1]
end

local function launchpad_remove()
	pages = {}
	page_buffer = nil
	APPS_LIST = nil
	shortcuts = {}
	root:removeChild(launchpad)
	launchpad = nil
	local count = #dock_items
	local dock_w = count * 3
	local x = math.floor((S_WIDTH - dock_w)/2) + 1

	os.queueEvent("wm_reposition", self_pid, x, S_HEIGHT - 1, docker.w, docker.h)
end

local function app_pressed(self)
	if launchpad then launchpad_remove() end
	if self.text == "Docker" then return end
	sys.execute(self.filePath, self.text, _ENV)
end

local function launchpad_init()
	-- launchpad = UI.Box(1, 1, S_WIDTH, S_HEIGHT, colors.lightBlue, colors.white)
	launchpad = UI.Box({
		x = 1, y = 1,
		w = S_WIDTH, h = S_HEIGHT,
		bc = colors.lightBlue,
		fc = colors.white,
	})
	root:addChild(launchpad, 1)

	-- local search = UI.Textfield(math.floor((S_WIDTH - 10)/2) + 1, 2, 10, 1, "search", false, colors.gray, colors.white)
	local search = UI.Textfield({
		x = math.floor((S_WIDTH - 10)/2) + 1, y = 2,
		w = 10, h = 1,
		hint = "search",
		bc = colors.gray,
		fc = colors.white,
	})
	launchpad:addChild(search)

	-- local radio = UI.RadioButton_horizontal(math.floor((S_WIDTH - 1)/2) + 1, S_HEIGHT - 2, 1, launchpad.color_bg, colors.white)
	local radio = UI.RadioButton_horizontal({
		x = math.floor((S_WIDTH - 1)/2) + 1, y = S_HEIGHT - 2,
		count = 1,
		bc = launchpad.bc,
		fc = colors.white,
	})
	launchpad:addChild(radio)

	shortcuts = {}
	APPS_LIST = fs.list(APPS_PATH)

	for _, v in ipairs(APPS_LIST) do
		local path_ico = "sbin/"..v.."/icon3.ico"
		if not fs.exists(path_ico) then
			path_ico = DEF_ICO
		end

		-- local shortcut = UI.Shortcut(1, 1, WIDTH_SHORT, HEIGHT_SHORT, v, "sbin/"..v.."/main.lua", path_ico, launchpad.color_bg, colors.white)
		local shortcut = UI.Shortcut({
			x = 1, y = 1,
			w = WIDTH_SHORT, h = HEIGHT_SHORT,
			icoPath = path_ico,
			filePath = "sbin/"..v.."/main.lua",
			text = v,
			bc = launchpad.bc,
			fc = colors.white,
		})
		shortcut.pressed = app_pressed
		table.insert(shortcuts, shortcut)
	end

	build_launchpad(radio)

	radio.pressed = function (self)
		if not page_buffer then return end
		local page = pages[self.item]
		launchpad:removeChild(page_buffer)
		launchpad:addChild(page)
		page_buffer = page
		page:onLayout()
	end

	launchpad.onFocus = function (self, focused)
		if focused then
			if launchpad then launchpad_remove() end
		end
	end

	launchpad.onResize = function (width, height)
		launchpad.w, launchpad.h = width, height
		search.local_x = math.floor((width - search.w)/2) + 1
		build_launchpad(radio)
		radio.local_y = height - 2
		radio.local_x = math.floor((width - radio.count)/2)+1
	end

	-- local count = #dock_items
	-- local dock_w = count * 3
	-- local x = math.floor((S_WIDTH - dock_w)/2) + 1
	-- docker.local_y = S_HEIGHT - 1
	-- docker.local_x = x
	os.queueEvent("wm_reposition", self_pid, 1, 1, S_WIDTH, S_HEIGHT)
	-- root:onLayout()
end

local function Shortcut_draw(self)
	local text_color = root.focus == self and colors.white or colors.black
	blittle.draw(self.blittle_img, self.x, self.y)
	if self.icoPath ~= "usr/app_ico_small.ico" then return end
	term.setCursorPos(self.x + 1, self.y + 1)
	term.setBackgroundColor(colors.orange)
	term.setTextColor(text_color)
	term.write(self.name:sub(1,1))
end

local function Shortcut_pressed(self, btn, x, y)
	if self.name == "Launchpad" then
		if launchpad then launchpad_remove() return end
		if btn == 1 then launchpad_init() end
		return
	end
	if btn == 1 then
		if self.pid then
			if sys.get_proc_name(self.pid) == "Launchpad" then sys.process_end(self.pid) return end
			os.queueEvent("wm_restore", self.pid)
		else
			self.pid = sys.execute(self.filePath, self.name, _ENV)
		end
	elseif btn == 2 then
		local win = term.current()
		local t_x, t_y = win.getPosition()
		sys.create_popup(popup, t_x + x - 1, t_y - #popup)
	end
	if launchpad then launchpad_remove() end
end

local function save_pins()
	local pins = {}
	for _, item in ipairs(dock_items) do
		if item.pinned and not (item.name == "Launchpad") then
			table.insert(pins, {item.path, item.name})
		end
	end
	local file = fs.open(PINS_FILE, "w")
	file.write("return "..textutils.serialize(pins))
	file.close()
end

local function rebuild_layout()
	docker.children = {}
	local count = #dock_items
	local dock_w = count * 3
	root.w = math.max(1, dock_w)
	docker.w = root.w
	local x = math.floor((S_WIDTH - dock_w)/2) + 1

	for i, item in ipairs(dock_items) do
		local dock_x = (i - 1) * 3 + 1

		-- local shortcut = UI.Shortcut(dock_x, 1, 3, 3, _, item.path, item.icon, docker.color_bg, docker.color_txt)
		local shortcut = UI.Shortcut({
			x = dock_x, y = 1,
			w = 3, h = 3,
			icoPath = item.icon,
			filePath = item.path,
			bc = docker.bc,
			fc = docker.fc,
		})

		shortcut.name = item.name
		shortcut.pid = item.pid
		shortcut.draw = Shortcut_draw

		shortcut.pressed = Shortcut_pressed

		docker:addChild(shortcut)
	end

	os.queueEvent("wm_reposition", self_pid, x, S_HEIGHT - 1, docker.w, 2)
end

popup = {
	{text = "Pin", onClick = function ()
		for i, v in ipairs(dock_items) do
			if v.pid == root.focus.pid and not v.pinned then
				v.pinned = true
				save_pins()
				return
			end
		end
	end},
	{text = "UnPin", onClick = function ()
		for i, v in ipairs(dock_items) do
			if v.name == root.focus.name and v.pinned then
				v.pinned = false
				save_pins()
				if not v.pid then
					table.remove(dock_items, i)
					rebuild_layout()
				end
				return
			end
		end
	end},
}

local function load_pins()
	local dock_pins = dofile(PINS_FILE)
	for _, pin in ipairs(dock_pins or {}) do
		local path_ico = pin[1]:match("(.*)/").."/icon2.ico"
		if not fs.exists(path_ico) then
			path_ico = "usr/app_ico_small.ico"
		end
		local item = {
			path = pin[1],
			name = pin[2],
			pid = nil,
			pinned = true,
			icon = path_ico -- Тут нужна логика поиска иконки по пути
		}
		table.insert(dock_items, item)
	end
	rebuild_layout()
end

local function hide(bool)
	if hidden == bool then return end
	hidden = bool
	if bool then
		root:removeChild(docker)
	else
		root:addChild(docker)
	end
end

function docker.custom_handlers.docker_add(pid)
	local path = sys.get_proc_path(pid)
	-- if sys.get_proc_name(pid) == "panel" then return end
	for _, item in ipairs(dock_items) do
		if item.path == path then
			item.pid = pid
			rebuild_layout()
			return
		end
	end

	local path_ico = path:match("(.*)/").."/icon2.ico"
	if not fs.exists(path_ico) then
		path_ico = "usr/app_ico_small.ico"
	end

	local new_item = {
		path = path,
		name = sys.get_proc_name(pid),
		pid = pid,
		pinned = false,
		icon = path_ico
	}
	table.insert(dock_items, new_item)
	rebuild_layout()
end

function docker.custom_handlers.docker_remove(pid)
	for i, item in ipairs(dock_items) do
		if item.pid == pid then
			item.pid = nil

			if not item.pinned then
				table.remove(dock_items, i)
			end

			rebuild_layout()
			return
		end
	end
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
docker.onResize = function (width, hight)
	S_WIDTH, S_HEIGHT = sys.screen_get_size()
	local count = #dock_items
	local dock_w = count * 3
	local x = math.floor((S_WIDTH - dock_w)/2) + 1
	local y = launchpad and 1 or S_HEIGHT - 1
	if launchpad then
		docker.local_y = S_HEIGHT - 1
		docker.local_x = x
		launchpad.onResize(width, hight)
		os.queueEvent("wm_reposition", self_pid, 1, 1, S_WIDTH, S_HEIGHT)
		-- launchpad:onLayout()
	else
		docker.local_y = 1
		docker.local_x = 1
		x = launchpad and 1 or x
		os.queueEvent("wm_reposition", self_pid, x, y)
	end
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
load_pins()
root:mainloop()
----------------------------------------------------