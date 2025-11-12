------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_rep = string.rep
local string_gmatch = string.gmatch
local table_insert = table.insert
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local math_ceil = math.ceil
-----------------------------------------------------
local dM = {} --deskManager

local UI = require("ui")
local c = require("cfunc")
local shortcut_width = 15
local shortcut_height = 8
local spacing_x = 1  -- Отступ по X между ярлыками (можно увеличить для большего пространства)
local spacing_y = 1  -- Отступ по Y между рядами (можно увеличить)

local Parent
local Radio

local APP_ROOT_PATH = "sbin/"
local APP_MAIN_SUFFIX = "/main.lua"
local APP_ICON_SUFFIX = "/icon.ico"

local system_apps = fs.list("sbin")
--local user_apps = fs.list("/usr/bin")
--local allLines = {}
local desktops = {}

local maxRows
local maxCols

local num_desks
local num_shortcuts

local desk_height
local desk_width

local currdesk = 1

local sum

function dM.updateNumDesks()
    num_shortcuts = #system_apps--+#user_apps

    maxCols = math_floor(desk_width/(shortcut_width + spacing_x - 1))
    maxRows = math_floor(desk_height/(shortcut_height + spacing_y - 1))

    num_desks = math_max(math_ceil(num_shortcuts/(maxRows*maxCols)),1)
    return num_desks
end

function dM.deleteDesks(parent)
    for _, desktop in pairs(desktops) do
        desktop.child = {}
        parent:removeChild(desktop)
    end
    desktops = {}
end

function dM.makeDesktops(parent)
    if parent then Parent = parent end
    if desktops and #desktops > 0 then dM.deleteDesks(Parent) end

    sum = shortcut_width

    while sum <= Parent.size.w-4 do
        sum = sum + shortcut_width + spacing_x
    end
    desk_width = sum - shortcut_width - spacing_x

    sum = shortcut_height

    while sum <= Parent.size.h-2 do
        sum = sum + shortcut_height + spacing_y
    end
    desk_height = sum - shortcut_height - spacing_y

    dM.updateNumDesks()

    for j = 1, num_desks do
        local desk = UI.New_Box(Parent.root)

        desk.reSize = function (self)
            self.size = {w = desk_width,h = desk_height}
            self.pos = {x = math_floor((self.parent.size.w-self.size.w)/2)+1,
            y = math_floor((self.parent.size.h-self.size.h)/2)+1}
        end

        desk.draw = function (self)
            local temp = string_rep("-", shortcut_width)
            for a = 1, maxCols-1 do
                temp = temp.."+"..string_rep("-", shortcut_width)
            end
            for i = 1, maxRows-1 do
                c.write(temp, self.pos.x, shortcut_height * i + spacing_y * (i-1) + self.pos.y, self.bg, colors.lightGray)
            end
            local d = 0
            for ci = 1, maxRows do
                for b = 1, shortcut_height do
                    for j = 1, maxCols - 1 do
                        c.write("|", shortcut_width * j + spacing_x * (j-1) + self.pos.x,
                        d+b+(self.pos.y-1)+shortcut_height*(ci-1),
                        self.bg, colors.lightGray)
                    end
                end
                d = d + 1
            end
        end

        table_insert(desktops, desk)
    end

    currdesk = math_min(currdesk, num_desks)
    Parent:addChild(desktops[currdesk])
end

local function reSize(self)
    self.pos = {
        x = self.parent.pos.x + self.offset_X,
        y = self.parent.pos.y + self.offset_Y
    }
    self.size = {
        w = shortcut_width,
        h = shortcut_height
    }
end

local APP_CONFIG = {
    Paint = {
        needArgs = { true }
    },
    converter = {
        needArgs = { true, "converter_main.lua" }
    },
}

function dM.makeShortcuts()
    local col = 1
    local row = 1
    local d = 1
    for _, appName in ipairs(system_apps) do
        local appDir = APP_ROOT_PATH .. appName
        local mainPath = appDir .. APP_MAIN_SUFFIX
        if fs.exists(mainPath) then
            local config = APP_CONFIG[appName] or {}
            local iconPath = appDir .. APP_ICON_SUFFIX
            local shortcut = UI.New_Shortcut(Parent.root, appName, mainPath, iconPath)
            if config.needArgs then
                shortcut.needArgs = config.needArgs
            end
            shortcut.offset_X = (col - 1) * (shortcut_width + spacing_x)
            shortcut.offset_Y = (row - 1) * (shortcut_height + spacing_y)
            shortcut.reSize = reSize
            if desktops[d] then
                desktops[d]:addChild(shortcut)
            else
                error("Ошибка: Попытка добавить ярлык на несуществующий рабочий стол: " .. d)
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
    if currdesk ~= num and Parent:removeChild(desktops[currdesk]) then
        Parent:addChild(desktops[num])
        currdesk = num
    end
end

function dM.setRadio(obj)
    if obj and not Radio then Radio = obj end
end

function dM.tResize()
    Parent.root:layoutChild()
    dM.makeDesktops(Parent)
    dM.makeShortcuts()
    Radio:changeCount(num_desks)
    Radio.item = currdesk
end

return dM