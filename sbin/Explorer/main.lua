------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_sub = string.sub
local string_find = string.find
local string_char = string.char
local string_lower = string.lower
local string_byte = string.byte
local table_insert = table.insert
local table_sort = table.sort
local fs = fs
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local sys = require "syscalls"
local c = require "cfunc"
local UI = require "ui2"
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
-- local fslist = fs.list("")
-- local fslist2 = {}
local mode = ""
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
-- local window, root = sys.add_window("Titled", colors.black, "Explorer")
sys.register_window("Explorer", 1, 1, 51, 18, true)

local root = UI.Root()

-- local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.black,
	fc = colors.white,
})
root:addChild(surface)

-- local treeview = UI.TreeView(1, 1, surface.w, surface.h, {bg = colors.black, bg2 = colors.gray, hover = colors.lightGray, txt = colors.white})
local treeview = UI.TreeView({
	x = 1, y = 1,
	w = surface.w, h = surface.h,
	bc = colors.black,
	fc = colors.white,
	bc_hv = colors.lightGray,
	bc_alt = colors.gray,
})
surface:addChild(treeview)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function strCmpIgnoreCase(a, b)
	-- Регистронезависимое лексикографическое сравнение (работает в Lua 5.1+ и 5.2+)
	a = string_lower(a or "")
	b = string_lower(b or "")
	local minlen = math.min(#a, #b)
	for i = 1, minlen do
		local ba = string_byte(a, i)
		local bb = string_byte(b, i)
		if ba ~= bb then
			return ba < bb
		end
	end
	return #a < #b
end

local function sort(arr, path)
	local dirs = {}
	local files = {}
	for _, v in pairs(arr) do
		if fs.isDir(path .. "/" .. v) then
			table_insert(dirs, v)
		else
			table_insert(files, v)
		end
	end
	arr = {}
	-- Сортируем папки регистронезависимо
	table_sort(dirs, function(a, b)
		return strCmpIgnoreCase(a, b)
	end)
	-- Сортируем файлы регистронезависимо
	table_sort(files, function(a, b)
		return strCmpIgnoreCase(a, b)
	end)
	for _, v in pairs(dirs) do
		table_insert(arr, v)
	end
	for _, v in pairs(files) do
		table_insert(arr, v)
	end
	return arr
end

local function list(path)
	local fslist = fs.list(path)
	fslist = sort(fslist, path)
	local fslist2 = {}
	for i, v in ipairs(fslist) do
		local txt = fs.isDir(path .. "/" .. v) and colors.blue or colors.white
		fslist2[i] = { name = v, canOpen = fs.isDir(path .. "/" .. v), arr = {}, isOpen = false, path = path .. "/" .. v, ico = {char = "\143", txt = txt} }
	end
	return fslist2
end
treeview.tree = list("")
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--

treeview.pressed = function(self, item)
	if item.canOpen then
		item.isOpen = not item.isOpen

		if item.isOpen then
			if #item.arr == 0 then
				item.arr = list(item.path)
			end
		else
			-- item.arr = {} -- ЕСЛИ НУЖНО ЗАБЫТЬ ЧТО ОТКРЫВАЛ
		end
	else

	end

	-- self.dirty = true
	surface:onLayout()
end

surface.onResize = function(width, height)
	surface.w, surface.h = width, height
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------
