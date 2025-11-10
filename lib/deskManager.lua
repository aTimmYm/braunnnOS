local dM = {} --deskManager

local shortcut_width = 15
local shortcut_height = 8
local spacing_x = 1  -- Отступ по X между ярлыками (можно увеличить для большего пространства)
local spacing_y = 1  -- Отступ по Y между рядами (можно увеличить)

local Parent
local Radio

local allLines = {}
local desktops = {}

local maxRows
local maxCols

local num_desks
local num_shortcuts

local desk_height
local desk_width

local currdesk = 1

local sum

function dM.readShortcuts()
    local i, j = 1, 0
    for line in io.lines("usr/sys.conf") do
        j = j + 1
        local oneLine = {}
        for lines in line:gmatch("%S+") do
            oneLine[i] = tostring(lines)
            i = i + 1
        end
        table.insert(allLines, j, oneLine)
        i = 1
    end
end

function dM.updateNumDesks()
    num_shortcuts = #allLines

    maxCols = math.floor(desk_width/(shortcut_width + spacing_x - 1))
    maxRows = math.floor(desk_height/(shortcut_height + spacing_y - 1))

    num_desks = math.max(math.ceil(num_shortcuts/(maxRows*maxCols)),1)
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
            self.pos = {x = math.floor((self.parent.size.w-self.size.w)/2)+1,
            y = math.floor((self.parent.size.h-self.size.h)/2)+1}
        end

        desk.draw = function (self)
            local temp = string.rep("-", shortcut_width)
            for a = 1, maxCols-1 do
                temp = temp.."+"..string.rep("-", shortcut_width)
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

        table.insert(desktops, desk)
    end

    currdesk = math.min(currdesk, num_desks)
    Parent:addChild(desktops[currdesk])
end

function dM.makeShortcuts()
-- Автоматическое размещение ярлыков в сетке
    num_shortcuts = #allLines
    local col = 1
    local row = 1
    local d = 1
    for k = 1, num_shortcuts do
        local line = allLines[k]
        if #line ~= 3 then
            -- Пропускаем некорректные строки (если в строке не ровно 3 элемента)
            error("Warning: Invalid line in sys.conf at index " .. k)
        end

        local text = line[1]      -- Имя ярлыка (Explorer, Polygon и т.д.)
        local filepath = line[2]  -- Путь к файлу (sbin/explorer.lua и т.д.)
        local icopath = line[3]   -- Путь к иконке (sbin/ico/explorer.ico и т.д.)

        local shortcut = UI.New_Shortcut(Parent.root, text, filepath, icopath)
        if text == "Paint" then shortcut.needArgs[1] = true end
        if text == "converter" then shortcut.needArgs[1] = true shortcut.needArgs[2] = "converter_main.lua" end
        -- Сохраняем offsets для позиционирования
        shortcut.offset_X = (col - 1) * (shortcut_width + spacing_x)
        shortcut.offset_Y = (row - 1) * (shortcut_height + spacing_y)

        shortcut.reSize = function (self)
            self.pos = {x = self.parent.pos.x + self.offset_X, y = self.parent.pos.y + self.offset_Y}
            self.size = {w = shortcut_width, h = shortcut_height}
        end

        desktops[d]:addChild(shortcut)

        -- Переход к следующему столбцу/ряду
        col = col + 1
        if col > maxCols then
            col = 1
            row = row + 1
        end

        if k == d*(maxRows*maxCols) then
            d = d + 1
            col = 1
            row = 1
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