------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local _rep = string.rep
local string_sub = string.sub
local string_char = string.char
local string_gmatch = string.gmatch
local table_insert = table.insert
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local UI = require "ui2"
local sys = require "sys"
local c = require "cfunc"
local bf = require "bigfont"
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local page_buffer = nil
local settingsPath = "usr/settings.conf"
local conf = c.readConf(settingsPath)
local PALETTE = require("palette")
local version = "0.2 DEV"
local files_to_update = {}
local compact = 0
local box = {}
local menu_bar = nil

local dropdownChooseArr = {}
for k, _ in pairs(PALETTE) do
	table_insert(dropdownChooseArr, k)
end
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
-- local window, root = sys.add_window("Titled", colors.black, "Settings")
sys.register_window("Settings", 1, 1, 51, 18, true)

local root = UI.Root()

local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
root:addChild(surface)

local function get_compact_mode(width)
	if width < 21 then return 3
	elseif width < 33 then return 2
	elseif width < 47 then return 1
	else return 0 end
end

compact = get_compact_mode(surface.w)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function write_file(path, data)
	local file = fs.open(path, "w")
	file.write(data)
	file.close()
end

local function translateServerManifest(manifest)
	local arr = {}
	for line in string_gmatch(manifest, "([^\n]+)\n?") do
		local key = string_sub(line, 1, 32)
		local value = string_sub(line, 36)
		arr[value] = key
	end
	return arr
end

local function checkUpdates(manifest)
	local ret = false
	local server_manifest, err = translateServerManifest(manifest)
	if server_manifest then
		local manifest_old = {}
		for line in io.lines("manifest.txt") do
			local key = string_sub(line, 1, 32)
			local value = string_sub(line, 36)
			manifest_old[value] = key
		end
		for file,_ in pairs(manifest_old) do
			if not server_manifest[file] then
				fs.delete(file)
				ret = true
			end
		end
		for file,hash in pairs(server_manifest) do
			if not manifest_old[file] or manifest_old[file] ~= hash then
				table_insert(files_to_update,file)
				ret = true
			end
		end
		return ret
	end
end

local function create_page_1()
	local box_w =  box.w or 0
	local page = UI.Box(box_w + 1, 1, compact == 2 and root.w or root.w - box_w, root.h, root.color_bg)

	local tumblerLabel = UI.Label(2, 2, 12, 1, "Monitor Mode", "left", page.color_bg, colors.white)
	page:addChild(tumblerLabel)

	local monitorTumbler = UI.Tumbler(page.w - 2, tumblerLabel.y, colors.white, colors.lightGray, colors.gray, conf["isMonitor"])
	page:addChild(monitorTumbler)

	local dropdownLabel = UI.Label(tumblerLabel.x, tumblerLabel.y + 2, 13, 1, "Monitor Scale", "left", page.color_bg, colors.white)
	page:addChild(dropdownLabel)

	local dropdown = UI.Dropdown(page.w - 4, dropdownLabel.y, {"0.5","1","1.5","2","2.5","3","3.5","4","4.5","5"}, tostring(conf["monitorScale"]), _, _, colors.white, colors.black)
	page:addChild(dropdown)

	local label_desk_mode = UI.Label(dropdownLabel.x, dropdownLabel.y + 2, 12, 1, "Desktop Mode", "left", page.color_bg, colors.white)
	page:addChild(label_desk_mode)

	local tumbler_desk_mode = UI.Tumbler(page.w - 2, label_desk_mode.y, colors.white, colors.lightGray, colors.gray, conf["DesktopMode"])
	page:addChild(tumbler_desk_mode)

	monitorTumbler.pressed = function(self)
		conf["isMonitor"] = not self.on
		c.saveConf(settingsPath, conf)
	end

	dropdown.pressed = function(self)
		local val = tonumber(self.array[self.item_index])
		conf["monitorScale"] = val
		if bOS and bOS.monitor[1] then
			bOS.monitor[1].setTextScale(val)
			os.queueEvent("term_resize")
		end
		c.saveConf(settingsPath, conf)
	end

	tumbler_desk_mode.pressed = function(self)
		conf["DesktopMode"] = not self.on
		c.saveConf(settingsPath, conf)
	end

	page.onResize = function (width, height)
		local x = compact == 3 and 1 or 2
		tumblerLabel.local_x = x
		dropdownLabel.local_x = x
		monitorTumbler.local_x = width - x
		dropdown.local_x = width - 2 - x
		tumbler_desk_mode.local_x = width - x
	end

	page.onResize(page.w)

	return page
end

local function create_page_2()
	local box_w =  box.w or 0
	local page = UI.Box(box_w + 1, 1, compact == 2 and surface.w or surface.w - box_w, surface.h, surface.color_bg)

	local time24FormatLabel = UI.Label(2, 2, 17, 1, "Enable 24h format", "left", page.color_bg, colors.white)
	page:addChild(time24FormatLabel)

	local time24FormatTumbler = UI.Tumbler(page.w - 2, time24FormatLabel.y, colors.lightGray, colors.gray, _, conf["24format"])
	page:addChild(time24FormatTumbler)

	local showSecondsLabel = UI.Label(2, time24FormatLabel.y + 2, 12, 1, "Show seconds", "left", page.color_bg, colors.white)
	page:addChild(showSecondsLabel)

	local showSecondsTumbler = UI.Tumbler(page.w - 2, showSecondsLabel.y, colors.lightGray, colors.gray, _, conf["show_seconds"])
	page:addChild(showSecondsTumbler)

	time24FormatTumbler.pressed = function(self)
		conf["24format"] = not self.on
		c.saveConf(settingsPath, conf)
	end

	showSecondsTumbler.pressed = function(self)
		conf["show_seconds"] = not self.on
		c.saveConf(settingsPath, conf)
	end

	page.onResize = function (width, height)
		local x = compact == 3 and 1 or 2
		time24FormatLabel.local_x = x
		showSecondsLabel.local_x = x
		time24FormatTumbler.local_x = width - x
		showSecondsTumbler.local_x = width - x
	end

	page.onResize(page.w)

	return page
end

local function create_page_3()
	local box_w =  box.w or 0
	local page = UI.Box(box_w + 1, 1, compact == 2 and surface.w or surface.w - box_w, surface.h, surface.color_bg)

	local labelCurrCols = UI.Label(2, 2, 15, 1, "Current colors:", "left", colors.white, colors.black)
	page:addChild(labelCurrCols)

	local currCols = UI.Label(labelCurrCols.x + labelCurrCols.w + 1, labelCurrCols.y, 4, 1)
	currCols.draw = function(self)
		local test = string_char(149)
		local s_bg = colors.toBlit(surface.color_bg)
		term.setCursorPos(self.x - 1, self.y)
		term.blit(test.."    "..test, s_bg.."f087".."e", "e".."f087"..s_bg)

		term.setCursorPos(self.x - 1, self.y - 1)
		local test2 = string_char(159).._rep(string_char(143), 4)..string_char(144)
		term.blit(test2, _rep(s_bg, #test2 - 1).."e", _rep("e", #test2 - 1)..s_bg)

		term.setCursorPos(self.x - 1, self.y + 1)
		local test3 = string_char(130).._rep(string_char(131), 4)..string_char(129)
		term.blit(test3, _rep("e", #test3 - 1).."e", _rep(s_bg, #test3 - 1)..s_bg)
	end
	page:addChild(currCols)

	local chooseLabel = UI.Label(2, currCols.y + 2, 21, 1, "Choose your palette: ", _, page.color_bg, colors.white)
	page:addChild(chooseLabel)

	local dropdownChoose = UI.Dropdown(page.w - 13, chooseLabel.y, dropdownChooseArr, conf["palette"], _, _, colors.white, colors.black)
	page:addChild(dropdownChoose)

	dropdownChoose.pressed = function(self)
		if PALETTE[self.array[self.item_index]] then
			PALETTE[self.array[self.item_index]]()
			conf["palette"] = self.array[self.item_index]
			c.saveConf(settingsPath, conf)
		end
	end

	page.onResize = function (width, height)
		local x = compact == 3 and 1 or 2
		labelCurrCols.local_x = x
		currCols.local_x = labelCurrCols.local_x + labelCurrCols.w + 1
		chooseLabel.local_x = x
		if compact >= 1 then
			dropdownChoose.local_x = x
			dropdownChoose.local_y = chooseLabel.local_y + 2
		else
			dropdownChoose.local_x = width - 13
			dropdownChoose.local_y = chooseLabel.local_y
		end
	end

	page.onResize(page.w)

	return page
end

local function create_page_4()
	local box_w =  box.w or 0
	local page = UI.Box(box_w + 1, 1, compact == 2 and surface.w or surface.w - box_w, surface.h, surface.color_bg)

	local braunnnOS = UI.Label(2, 2, 9, 1, string_char(223).."raunnnOS", _, page.color_bg, colors.white)
	page:addChild(braunnnOS)

	local versionLabel = UI.Label(2, braunnnOS.y + 1, 19, 1, "Version "..version, "left", page.color_bg, colors.lightGray)
	page:addChild(versionLabel)

	local buttonCheckUpdate = UI.Button(2, versionLabel.y + 1, 19, 1, "(CHECK FOR UPDATES)", "center", _, page.color_bg, colors.white)
	page:addChild(buttonCheckUpdate)

	local loadingBar = UI.LoadingBar(buttonCheckUpdate.x, buttonCheckUpdate.y + 1, buttonCheckUpdate.w, page.color_bg, colors.blue, page.color_bg, "top", 0)
	page:addChild(loadingBar)

	buttonCheckUpdate.pressed = function(self)
		self:setText("(CHECKING)")
		local response, err = http.get("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/manifest.txt")
		local manifest = response.readAll()
		response.close()
		if response then
			if checkUpdates(manifest) then
				for i, v in pairs(files_to_update) do
					local request = http.get("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/"..v)
					if request then
						write_file(v,request.readAll())
						request.close()
						loadingBar:setValue(i/#files_to_update)
					end
				end
				local file = fs.open("manifest.txt","w")
				file.write(manifest)
				file.close()
				self:setText("(SUCCESS INSTALLED)")
			else
				self:setText("(NO UPDATES)")
			end
			root:onLayout()
		end
	end

	page.onResize = function (width, height)
		local x = compact == 3 and 1 or 2
		braunnnOS.local_x = x
		versionLabel.local_x = x
		buttonCheckUpdate.local_x = x
		loadingBar.local_x = x
	end

	page.onResize(page.w)

	return page
end

local function set_page(creator_func)
	if page_buffer and page_buffer.creator == creator_func then
		if not page_buffer.parent then surface:addChild(page_buffer) end
		return
	end

	if page_buffer then
		surface:removeChild(page_buffer)
	end

	local newPage = creator_func()
	newPage.creator = creator_func
	surface:addChild(newPage)
	page_buffer = newPage
	surface:onLayout()
end

local function create_sidebar()
	if box and box.parent then return end -- Уже есть

	box = UI.Box(1, 1, 11, surface.h, colors.gray, colors.white)
	box.draw = function (self)
		paintutils.drawFilledBox(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1, self.color_bg)
		-- for i = self.y, self.h + self.y - 1 do
		-- 	local bg, txt = colors.toBlit(self.color_bg), colors.toBlit(self.color_txt)
		-- 	term.setCursorPos(self.x, i)
		-- 	term.blit("|", txt, bg)
		-- 	term.setCursorPos(self.w + self.x - 1, i)
		-- 	term.blit("|", txt, bg)
		-- end
	end
	surface:addChild(box)

	local displayLabel = UI.Label(2, 1, box.w - 2, 1, "-DISPLAY-", _, box.color_bg, colors.lightGray)
	box:addChild(displayLabel)

	local buttonSCREEN = UI.Button(2, displayLabel.y + 1, displayLabel.w, 1, "SCREEN", _, _, box.color_bg, box.color_txt)
	box:addChild(buttonSCREEN)

	local buttonTIME = UI.Button(2, buttonSCREEN.y + 1, buttonSCREEN.w, 1, "TIME&DATE",_, _, box.color_bg, box.color_txt)
	box:addChild(buttonTIME)

	local buttonCOLORS = UI.Button(2, buttonTIME.y + 1, buttonTIME.w, 1, "COLORS", _, _, box.color_bg, box.color_txt)
	box:addChild(buttonCOLORS)

	local systemLabel = UI.Label(2, buttonCOLORS.y + 1, box.w - 2, 1, "-SYSTEM--", _, box.color_bg, colors.lightGray)
	box:addChild(systemLabel)

	local buttonAbout = UI.Button(2, systemLabel.y + 1, systemLabel.w, 1, "ABOUT", _, _, box.color_bg, box.color_txt)
	box:addChild(buttonAbout)

	buttonSCREEN.pressed  = function() set_page(create_page_1) end
	buttonTIME.pressed    = function() set_page(create_page_2) end
	buttonCOLORS.pressed  = function() set_page(create_page_3) end
	buttonAbout.pressed   = function() set_page(create_page_4) end
end

local function add_menu()
	-- if menu_bar and menu_bar.parent then return end

	-- menu_bar = UI.Menu(1, 1, "=", {"SCREEN", "TIME&DATE", "COLORS", "ABOUT"}, window.color_bg, colors.black)
	-- window:addChild(menu_bar)

	-- menu_bar.pressed = function (self, id)
	-- 	if      id == "SCREEN" then set_page(create_page_1)
	-- 	elseif  id == "TIME&DATE" then set_page(create_page_2)
	-- 	elseif  id == "COLORS" then set_page(create_page_3)
	-- 	elseif  id == "ABOUT" then set_page(create_page_4)
	-- 	end
	-- end
end

local function rebuild_interface(force)
	local new_compact = get_compact_mode(root.w)

	if new_compact == compact and not force then return end

	compact = new_compact

	if compact >= 2 then
		if box and box.parent then
			root:removeChild(box)
			box = {}
		end
		add_menu()
	else
		-- if menu_bar and menu_bar.parent then
		-- 	window:removeChild(menu_bar)
		-- 	menu_bar = nil
		-- end
		create_sidebar()
	end
end

-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
surface.onResize = function (width, height)
	rebuild_interface(false)

	if box and box.h then box.h = height end

	if page_buffer then
		local sidebar_w = (box and box.w) or 0

		local page_w = (compact == 2) and width or (width - sidebar_w)

		page_buffer.local_x = sidebar_w + 1
		page_buffer.w = page_w
		page_buffer.h = height

		if page_buffer.onResize then page_buffer.onResize(page_w, height) end
	end
end
-----------------------------------------------------
rebuild_interface(true)
set_page(create_page_4)
root:mainloop()