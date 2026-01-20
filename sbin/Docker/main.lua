-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local sys = require "sys"
local UI = require "ui2"
local blittle = require "blittle_extended"
local WIDTH, HEIGHT = sys.screen_get_size()
sys.register_window("docker", 1, 1, 1, 2, false, 3)
local root = UI.Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local docker_pid = sys.getpid()
local PINS_FILE = "sbin/Docker/Data/dock_pins"
local dock_items = {}
local hidden = false
local docker_functions = {}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local docker = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
root:addChild(docker)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function Shortcut_draw(self)
	local text_color = root.focus == self and colors.white or colors.black
	blittle.draw(self.blittle_img, self.x, self.y)
	term.setCursorPos(self.x + 1, self.y + 1)
	term.setBackgroundColor(colors.orange)
	term.setTextColor(text_color)
	term.write(self.name:sub(1,1))
end

local function Shortcut_pressed(self)
	if self.pid then
		if sys.get_proc_name(self.pid) == "Launchpad" then sys.process_end(self.pid) return end
		os.queueEvent("wm_restore", self.pid)
	else
		self.pid = sys.execute(self.filePath, self.name, _ENV)
	end
end

local function save_pins()
	local pins = {}
	for _, item in ipairs(dock_items) do
		if item.pinned then
			table.insert(pins, {item.path, item.name})
		end
	end
	local dock_pins = fs.open(PINS_FILE, "w")
	dock_pins.write("return "..textutils.serialize(pins))
	dock_pins.close()
end

local function rebuild_layout()
	docker.children = {}
	local count = #dock_items
	local dock_w = count * 3
	root.w = math.max(1, dock_w)
	docker.w = root.w
	local x = math.floor((WIDTH - dock_w)/2) + 1

	for i, item in ipairs(dock_items) do
		local dock_x = (i - 1) * 3 + 1

		local shortcut = UI.Shortcut(dock_x, 1, 3, 3, _, item.path, item.icon, docker.color_bg, docker.color_txt)

		shortcut.name = item.name
		shortcut.pid = item.pid
		shortcut.draw = Shortcut_draw

		shortcut.pressed = Shortcut_pressed

		-- Пример реализации контекстного меню для (Unpin/Pin)
		-- shortcut.onRightClick = function(self)
		-- 	-- Логика переключения pinned
		-- 	local item_ref = dock_items[i]
		-- 	item_ref.pinned = not item_ref.pinned
		-- 	save_pins()
		-- 	-- Если мы открепили и оно не запущено - удаляем из дока
		-- 	if not item_ref.pinned and not item_ref.pid then
		-- 		table.remove(dock_items, i)
		-- 		docker.rebuild_layout()
		-- 	end
		-- end

		docker:addChild(shortcut)
	end
	-- root:onLayout()
	os.queueEvent("wm_reposition", docker_pid, x, HEIGHT - 1, docker.w, 2)
end

local function load_pins()
	local dock_pins = dofile(PINS_FILE)
	for _, pin in ipairs(dock_pins or {}) do
		local item = {
			path = pin[1],
			name = pin[2],
			pid = nil,
			pinned = true,
			icon = "app_ico_small.ico" -- Тут нужна логика поиска иконки по пути
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

function docker_functions.docker_add(pid)
	local path = sys.get_proc_path(pid)
	if sys.get_proc_name(pid) == "panel" then return end
	for _, item in ipairs(dock_items) do
		if item.path == path then
			item.pid = pid
			rebuild_layout()
			return
		end
	end

	local new_item = {
		path = path,
		name = sys.get_proc_name(pid),
		pid = pid,
		pinned = false,
		icon = "app_ico_small.ico"
	}
	table.insert(dock_items, new_item)
	rebuild_layout()
end

function docker_functions.docker_remove(pid)
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
	WIDTH, HEIGHT = sys.screen_get_size()
	local count = #dock_items
	local dock_w = count * 3
	local x = math.floor((WIDTH - dock_w)/2) + 1
	os.queueEvent("wm_reposition", docker_pid, x, HEIGHT - 1)
end

local docker_onEvent = docker.onEvent
docker.onEvent = function (self, evt)
	local event_name = evt[1]
	if docker_functions[event_name] then
		docker_functions[event_name](evt[2])
		return true
	end
	return docker_onEvent(self, evt)
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
load_pins()
root:mainloop()
----------------------------------------------------