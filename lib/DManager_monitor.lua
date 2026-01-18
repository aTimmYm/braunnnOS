------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_rep = string.rep
local table_insert = table.insert
local _max = math.max
local _min = math.min
local _floor = math.floor
local _ceil = math.ceil
-----------------------------------------------------
local dM = {} --deskManager

local UI = require "ui2"
local system = require "lib.sys"

local shortcut_width = 15
local shortcut_height = 8
local spacing_x = 1  -- Отступ по X между ярлыками (можно увеличить для большего пространства)
local spacing_y = 1  -- Отступ по Y между рядами (можно увеличить)


local APP_ROOT_PATH = "sbin/"
local APP_MAIN_SUFFIX = "/main.lua"
local APP_ICON_SUFFIX = "/icon.ico"

local system_apps = fs.list("sbin")
--local user_apps = fs.list("/usr/bin")
--local allLines = {}
local desktops = {}

local maxRows
local maxCols

local num_desks = 1
local num_shortcuts

local desk_height
local desk_width

local currdesk = 1

local sum

local Root = UI.Root(colors.black)
local Radio = UI.RadioButton_horizontal(_floor((Root.w - num_desks)/2) + 1, Root.h, _, colors.black, colors.white)
Root:addChild(Radio)

local function updateNumDesks()
	num_shortcuts = #system_apps--+#user_apps

	maxCols = _floor(desk_width/(shortcut_width + spacing_x - 1))
	maxRows = _floor(desk_height/(shortcut_height + spacing_y - 1))

	num_desks = _max(_ceil(num_shortcuts/(maxRows*maxCols)),1)
	Radio:changeCount(num_desks)
	return num_desks
end

function dM.deleteDesks(parent)
	for _, desktop in pairs(desktops) do
		desktop.child = {}
		parent:removeChild(desktop)
	end
	desktops = {}
end

local function makeDesktops()
	if desktops and #desktops > 0 then dM.deleteDesks(Root) end

	sum = shortcut_width

	while sum <= Root.w-4 do
		sum = sum + shortcut_width + spacing_x
	end
	desk_width = sum - shortcut_width - spacing_x

	sum = shortcut_height

	while sum <= Root.h-2 do
		sum = sum + shortcut_height + spacing_y
	end
	desk_height = sum - shortcut_height - spacing_y

	updateNumDesks()

	for j = 1, num_desks do
		local desk = UI.Box(_floor((Root.w - desk_width)/2) + 1, _floor((Root.h - desk_height)/2) + 1, desk_width, desk_height - 1)

		desk.onResize = function (width, height)
			desk.w, desk.h = desk_width, desk_height
			desk.x, desk.y = _floor((width - desk_width)/2) + 1, _floor((height - desk_height)/2) + 1
		end

		desk.draw = function (self)
			local temp = string_rep("-", shortcut_width)
			for a = 1, maxCols - 1 do
				temp = temp.."+"..string_rep("-", shortcut_width)
			end
			term.setBackgroundColor(self.color_bg)
			term.setTextColor(colors.lightGray)
			for i = 1, maxRows - 1 do
				term.setCursorPos(self.x, shortcut_height * i + spacing_y * (i - 1) + self.y)
				term.write(temp)
			end
			local d = 0
			for ci = 1, maxRows do
				for b = 1, shortcut_height do
					for j = 1, maxCols - 1 do
						term.setCursorPos(shortcut_width * j + spacing_x * (j-1) + self.x,
						d+b+(self.y-1)+shortcut_height*(ci-1))
						term.write("|")
					end
				end
				d = d + 1
			end
		end

		table_insert(desktops, desk)
	end

	currdesk = _min(currdesk, num_desks)
	Root:addChild(desktops[currdesk])
end

local APP_CONFIG = {
	Paint = {
		needArgs = { true }
	},
	converter = {
		needArgs = { true, "converter_main.lua" }
	},
}

local function makeShortcuts()
	local col = 1
	local row = 1
	local d = 1
	for _, appName in ipairs(system_apps) do
		local appDir = APP_ROOT_PATH .. appName
		local mainPath = appDir .. APP_MAIN_SUFFIX
		if fs.exists(mainPath) then
			local config = APP_CONFIG[appName] or {}
			local iconPath = appDir .. APP_ICON_SUFFIX
			local offset_X = (col - 1) * (shortcut_width + spacing_x)
			local offset_Y = (row - 1) * (shortcut_height + spacing_y)
			local shortcut = UI.Shortcut(1 + offset_X, 1 + offset_Y, shortcut_width, shortcut_height, appName, mainPath, iconPath, colors.blue, colors.white)
			if config.needArgs then
				shortcut.needArgs = config.needArgs
			end
			shortcut.pressed = function (self)
				local func, err = loadfile(self.filePath, _ENV)
				if not func then
					UI.MsgWin("INFO", "Error", err)
				else
					system.process_run(func)
				end
			end
			if desktops[d] then
				desktops[d]:addChild(shortcut)
			else
				error("Error: Attempt add shortcut to (desktop[" .. d .. "] = nil).")
			end

			col = col + 1
			if col > maxCols then
				col = 1
				row = row + 1

				if row > maxRows then
					row = 1
					d = d + 1
				end
			end
		end
	end
end

function dM.selectDesk(num)
	if currdesk ~= num and Root:removeChild(desktops[currdesk]) then
		Root:addChild(desktops[num])
		currdesk = num
	end
end

function dM.getCurrdesk()
	return currdesk
end

function dM.resize(width, height)
	Root.w, Root.h = width, height
	makeDesktops()
	makeShortcuts()
	updateNumDesks()
	Radio.item = dM.getCurrdesk()
	Radio.local_x, Radio.local_y = _floor((Root.w - num_desks)/2) + 1, Root.h
end

makeDesktops()
makeShortcuts()
Root:onLayout()
Root:redraw()

Radio.pressed = function(self)
	dM.selectDesk(self.item)
	self.parent:onLayout()
end
function dM.draw()
	Root:onLayout()
	Root:redraw()
end

function dM.event_handler(evt)
	Root:onEvent(evt)
end


return dM