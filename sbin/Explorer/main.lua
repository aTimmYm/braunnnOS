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
local c = require("cfunc")
local UI = require("ui")
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local fslist = fs.list("")
local mode = ""
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(root,colors.white)
root:addChild(surface)

local label = UI.New_Label(root,"Explorer",colors.white,colors.black)
label.reSize = function (self)
    self.pos = { x = 4, y = 1 }
    self.size.w = self.parent.size.w-self.pos.x-2
end
surface:addChild(label)

local buttonClose = UI.New_Button(root,"x",colors.white,colors.black)
buttonClose.reSize = function (self)
    self.pos.x = self.parent.size.w
end
surface:addChild(buttonClose)

local buttonAdd = UI.New_Button(root,"+",colors.white,colors.black)
surface:addChild(buttonAdd)

local buttonRet = UI.New_Button(root,"...",_,_,"left")
buttonRet.reSize = function (self)
    self.pos.y = label.pos.y+1
    self.size.w = self.parent.size.w-1
end
surface:addChild(buttonRet)

local list = UI.New_List(root,{},colors.white,colors.black)
list.reSize = function (self)
    self.pos.y = buttonRet.pos.y+1
    self.size = {w=self.parent.size.w-1,h=self.parent.size.h-self.pos.y+1}
end
surface:addChild(list)

local scrollbar = UI.New_Scrollbar(list)
scrollbar.reSize = function (self)
    self.pos = {x=list.size.w+1,y=buttonRet.pos.y}
    self.size.h = list.size.h+1
end
surface:addChild(scrollbar)

local buttonDelete = UI.New_Button(root, "-", colors.white, colors.black)
buttonDelete.reSize = function (self)
    self.pos.x = buttonAdd.pos.x+1
end
surface:addChild(buttonDelete)

local buttonMove = UI.New_Button(root, string_char(187), colors.white, colors.black)
buttonMove.reSize = function (self)
    self.pos.x = buttonDelete.pos.x+1
end
surface:addChild(buttonMove)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local extensions = {
    [".txt"] = function (item,fullPath)
        c.openFile(root,shell.resolveProgram("edit"),item)
        return true
    end,
    [".lua"] = function (item,fullPath)
        local protected_dirs = {"sbin", "lib"--[[, "usr"]]}
        local is_protected = false
        for _, dir in pairs(protected_dirs) do
            if string_find(fullPath, "^"..dir) then
                is_protected = true
                break
            end
        end
        if not is_protected then c.openFile(root,"sbin/Shell/main.lua",fullPath) end
        return true
    end,
    [".conf"] = function (item,fullPath)
        c.openFile(root,"sbin/Shell/main.lua","edit "..item)
        return true
    end,
    [".nfp"] = function (item,fullPath)
        c.openFile(root,shell.resolveProgram("paint"),item)
        return true
    end
}

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
    -- Сортируем папки регистронезависимо
    table_sort(dirs, function(a, b)
        return strCmpIgnoreCase(a, b)
    end)
    -- Сортируем файлы регистронезависимо
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
 list:updateArr(fslist)
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function (self)
    shell.setDir("")
    self.root.running_program = false
end

buttonAdd.pressed = function (self)
    if mode == "delete" then return end
    local dialWin = UI.New_DialWin(root)
    dialWin:callWin(" Creating directory ","Enter the directory name")
    dialWin.btnOK.pressed = function (self)
        if dialWin.child[2].text == "" then
            local infoWin = UI.New_MsgWin(root,"INFO")
            infoWin:callWin(" ERROR ","Invalid directory name")
        else
            fs.makeDir(shell.resolve(dialWin.child[2].text))
            fslist = fs.list(shell.dir())
            sort()
            list:updateArr(fslist)
        end
        dialWin:removeWin()
    end
end

list.pressed = function (self)
    if mode == "delete" or mode == "move" then
        if string_find(self.item, string_char(4)) then
            self.item = " "..string_sub(self.item, 2, #self.item)
        else
            self.item = string_char(4)..string_sub(self.item, 2, #self.item)
        end
        self.array[self.item_index] = self.item
        return
    end
    local fullPath = shell.resolve(list.item)
    if fs.isDir(fullPath) then
        shell.setDir(fullPath)
        fslist = fs.list(shell.dir())
        sort()
        self.scrollpos = 1
        self:updateArr(fslist)
        label:setText(shell.dir())

    elseif fs.exists(fullPath) then
        local extension = list.item:match("^.+(%..+)$") or ""
        if extensions[extension] then
            extensions[extension](list.item,fullPath)
        else
            local msgWin = UI.New_MsgWin(root, "INFO")
            msgWin:callWin(" ERROR ", "Can't open current file extension.")
        end
    end
end

buttonRet.pressed = function (self)
    if shell.dir() ~= "" then
        shell.setDir(fs.getDir(shell.dir()))
        fslist = fs.list(shell.dir())
        sort()
        list.scrollpos = 1
        list:updateArr(fslist)
        if shell.dir() == "" then
            label:setText("Explorer")
        else
            label:setText(shell.dir())
        end
    end
end

buttonDelete.pressed = function (self)
    local toDel = {}

    if mode == "delete" then
        for _,v in pairs(list.array) do
            if string_find(v, string_char(4)) then table_insert(toDel, string_sub(v, 2, #v)) end
        end
        if toDel and #toDel > 0 then
            local questionWin = UI.New_MsgWin(root,"YES,NO")
            questionWin:callWin(" DELETE ","Are you sure?")
            questionWin.btnYES.pressed = function (self)
                for _,v in pairs(toDel) do
                    fs.delete(shell.resolve(v))
                end
                fslist = fs.list(shell.dir())
                sort()
                list:updateArr(fslist)
                questionWin:removeWin()
                label:setText("Explorer")
                mode = ""
            end
            goto finish
        end
        fslist = fs.list(shell.dir())
        sort()
        list:updateArr(fslist)
        label:setText("Explorer")
        mode = ""
    elseif mode == "" then
        mode = "delete"
        label:setText("DELETE MODE")
        for i,_ in pairs(list.array) do
            list.array[i] = " "..list.array[i]
        end
        list.dirty = true
    end
    ::finish::
end

buttonMove.pressed = function (self)
    local moveBuffer = {}

    if mode == "move" then
        for _,v in pairs(list.array) do
            if string_find(v, string_char(4)) then table_insert(moveBuffer, string_sub(v, 2, #v)) end
        end
        if moveBuffer and #moveBuffer > 0 then
            local dialWin = UI.New_DialWin(root)
            dialWin:callWin(" MOVE ","Write a path to move")
            dialWin.btnOK.pressed = function (self)
                for _,v in pairs(moveBuffer) do
                    fs.move(shell.resolve(v),dialWin.child[2].text.."/"..v)
                end
                fslist = fs.list(shell.dir())
                sort()
                list:updateArr(fslist)
                dialWin:removeWin()
                label:setText("Explorer")
                mode = ""
            end
            goto finish
        end
        fslist = fs.list(shell.dir())
        sort()
        list:updateArr(fslist)
        label:setText("Explorer")
        mode = ""
    elseif mode == "" then
        mode = "move"
        label:setText("MOVE MODE")
        for i,_ in pairs(list.array) do
            list.array[i] = " "..list.array[i]
        end
        list.dirty = true
    end
    ::finish::
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
bOS.Explorer = nil
-----------------------------------------------------