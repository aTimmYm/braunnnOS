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
local sys = require "lib.syscalls"
local c = require "cfunc"
local UI = require "ui2"
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local fslist = fs.list("")
local mode = ""
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
-- local window, root = sys.add_window("Titled", colors.black, "Explorer")
sys.register_window("Explorer", 1, 1, 51, 18, true)

local root = UI.Root()

local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
root:addChild(surface)

local lable = UI.Label(19, 1, 15, 1, shell.dir(), "center", colors.black, colors.white)
surface:addChild(lable)

-- local buttonAdd = UI.Button(1, 1, 1, 1, "+", _, colors.white, colors.black)
-- -- window:addChild(buttonAdd)

-- local buttonDelete = UI.Button(buttonAdd.x + 1, 1, 1, 1, "-", _, colors.white, colors.black)
-- -- window:addChild(buttonDelete)

-- local buttonMove = UI.Button(buttonDelete.x + 1, 1, 1, 1, string_char(187), _, colors.white, colors.black)
-- -- window:addChild(buttonMove)

-- local buttonRet = UI.Button(1, 1, surface.w, 1, "...", "left", _, surface.color_bg, colors.white)
-- surface:addChild(buttonRet)

-- local list = UI.List(1, buttonRet.y + 1, surface.w - 1, surface.h-1, {}, surface.color_bg, colors.white)
-- surface:addChild(list)

-- local scrollbar = UI.Scrollbar(list)
-- surface:addChild(scrollbar)

local W,H = term.getSize()

local list = UI.ExplorerElement(2, 2, 30, H + 1, fs.list(""), colors.black, colors.white, _)
surface:addChild(list)

local btn_prev = UI.Button(1, 1, 1, 1, "<", _, _, colors.gray, colors.white)
surface:addChild(btn_prev)
local btn_next = UI.Button(3, 1, 1, 1, ">", _, _, colors.gray, colors.white)
surface:addChild(btn_next)

-- local text = UI.Label(20, 1, 12, 1,"BI BASNIPE", "center", colors.lightGray, colors.gray)
-- surface:addChild(text)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local extensions = {
	[".txt"] = function (item, fullPath)
		local func, load_err = loadfile("sbin/Notepad/main.lua", _ENV)  -- "t" для text, или "bt" если нужно
		if not func then
			UI.MsgWin("INFO", "Error", load_err)
		else
			sys.process_run(func, {fullPath})
		end
		return true
	end,
	[".lua"] = function (item, fullPath)
		local protected_dirs = {"sbin", "lib"--[[, "usr"]]}
		local is_protected = false
		for _, dir in pairs(protected_dirs) do
			if string_find(fullPath, "^"..dir) then
				is_protected = true
				break
			end
		end
		if not is_protected then c.openFile(root,"sbin/Shell/main.lua", fullPath) end
		return true
	end,
	[".conf"] = function (item, fullPath)
		c.openFile(root, "sbin/Shell/main.lua","edit "..item)
		return true
	end,
	[".nfp"] = function (item, fullPath)
		c.openFile(root,shell.resolveProgram("paint"), item)
		return true
	end
}

local function strCmpIgnoreCase(a, b)

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

local function sort(arr)
	local dirs = {}
	local files = {}
	for _,v in pairs(fslist) do
		if fs.isDir(shell.resolve(v)) then
			table_insert(dirs, v)
		else
			table_insert(files, v)
		end
	end
	fslist = {}

	table_sort(dirs, function(a, b)
		return strCmpIgnoreCase(a, b)
	end)

	table_sort(files, function(a, b)
		return strCmpIgnoreCase(a, b)
	end)
	for _,v in pairs(dirs) do
		table_insert(fslist, v)
	end
	for _,v in pairs(files) do
		table_insert(fslist, v)
	end
end
sort()
list:updateList(fslist)
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
-- buttonAdd.pressed = function (self)
-- 	if mode == "delete" then return end
-- 	local text = UI.DialWin(" Creating directory ", "Enter the directory name")
-- 	window:onLayout()
-- 	if text and text == "" then
-- 		UI.MsgWin("INFO", " ERROR ","Invalid directory name")
-- 		window:onLayout()
-- 	elseif text and text ~= "" then
-- 		fs.makeDir(shell.resolve(text))
-- 		fslist = fs.list(shell.dir())
-- 		sort()
-- 		list:updateArr(fslist)
-- 	end
-- end

-- list.pressed = function (self, item, index)
-- 	if mode == "delete" or mode == "move" then
-- 		if string_find(self.item, string_char(4)) then
-- 			self.item = " "..string_sub(self.item, 2, #self.item)
-- 		else
-- 			self.item = string_char(4)..string_sub(self.item, 2, #self.item)
-- 		end
-- 		self.array[self.item_index] = self.item
-- 		return
-- 	end
-- 	local fullPath = shell.resolve(item)
-- 	if fs.isDir(fullPath) then
-- 		shell.setDir(fullPath)
-- 		fslist = fs.list(shell.dir())
-- 		sort()
-- 		self.scrollpos = 1
-- 		self:updateArr(fslist)
-- 		-- window.label:setText(shell.dir())

-- 	elseif fs.exists(fullPath) then
-- 		local extension = item:match("^.+(%..+)$") or ""
-- 		if extensions[extension] then
-- 			extensions[extension](item, fullPath)
-- 		else
-- 			UI.MsgWin("INFO", " ERROR ", "Can't open current file extension.")
-- 			root:onLayout()
-- 		end
-- 	end
-- end

-- buttonRet.pressed = function (self)
-- 	if shell.dir() ~= "" then
-- 		shell.setDir(fs.getDir(shell.dir()))
-- 		fslist = fs.list(shell.dir())
-- 		sort()
-- 		list.scrollpos = 1
-- 		list:updateArr(fslist)
-- 		if shell.dir() == "" then
-- 			-- window.label:setText("Explorer")
-- 		else
-- 			-- window.label:setText(shell.dir())
-- 		end
-- 	end
-- end

-- buttonDelete.pressed = function (self)
-- 	local toDel = {}

-- 	if mode == "delete" then
-- 		for _,v in pairs(list.array) do
-- 			if string_find(v, string_char(4)) then table_insert(toDel, string_sub(v, 2, #v)) end
-- 		end
-- 		if toDel and #toDel > 0 then
-- 			local bool = UI.MsgWin("YES,NO", " DELETE ", "Are you sure?")
-- 			window:onLayout()
-- 			if bool then
-- 				for _, v in pairs(toDel) do
-- 					fs.delete(shell.resolve(v))
-- 				end
-- 				fslist = fs.list(shell.dir())
-- 				sort()
-- 				list:updateArr(fslist)
-- 				window.label:setText("Explorer")
-- 				mode = ""
-- 				goto finish
-- 			end
-- 		end
-- 		fslist = fs.list(shell.dir())
-- 		sort()
-- 		list:updateArr(fslist)
-- 		window.label:setText("Explorer")
-- 		mode = ""
-- 	elseif mode == "" then
-- 		mode = "delete"
-- 		window.label:setText("DELETE MODE")
-- 		--window.label.w =
-- 		for i,_ in pairs(list.array) do
-- 			list.array[i] = " "..list.array[i]
-- 		end
-- 		list.dirty = true
-- 	end
-- 	::finish::
-- end

-- buttonMove.pressed = function (self)
-- 	local moveBuffer = {}

-- 	if mode == "move" then
-- 		for _,v in pairs(list.array) do
-- 			if string_find(v, string_char(4)) then table_insert(moveBuffer, string_sub(v, 2, #v)) end
-- 		end
-- 		if moveBuffer and #moveBuffer > 0 then
-- 			local text = UI.DialWin(" MOVE ", "Write a path to move")
-- 			window:onLayout()
-- 			if text then
-- 				for _,v in pairs(moveBuffer) do
-- 					fs.move(shell.resolve(v),text.."/"..v)
-- 				end
-- 				fslist = fs.list(shell.dir())
-- 				sort()
-- 				list:updateArr(fslist)
-- 				window.label:setText("Explorer")
-- 				mode = ""
-- 				goto finish
-- 			end
-- 		end
-- 		fslist = fs.list(shell.dir())
-- 		sort()
-- 		list:updateArr(fslist)
-- 		window.label:setText("Explorer")
-- 		mode = ""
-- 	elseif mode == "" then
-- 		mode = "move"
-- 		window.label:setText("MOVE MODE")
-- 		for i,_ in pairs(list.array) do
-- 			list.array[i] = " "..list.array[i]
-- 		end
-- 		list.dirty = true
-- 	end
-- 	::finish::
-- end

surface.onResize = function (width, height)
	surface.w, surface.h = width, height
	list.w, list.h = width - 1, height - 1
end

btn_prev.pressed = function (self)
	local path = fs.getDir(shell.dir())
	if shell.dir() == "" then return end
	lable:setText(path)
	shell.setDir(path)
	fslist = fs.list(path)
	sort()
	list:updateList(fslist)
	surface:onLayout()
end

btn_next.pressed = function (self)
	
end

list.pressed = function(self, btn, x, y)
	local item = self.path[y - self.y]
	if not item then return end
	local fullPath = shell.resolve(item)
	if fs.isDir(fullPath) then
		shell.setDir(fullPath)
		fslist = fs.list(fullPath)
		sort()
		self:updateList(fslist)
		lable:setText(item)
	end
	surface:onLayout()
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------