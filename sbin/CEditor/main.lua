------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local _min = math.min
local _rep = string.rep
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local system = require("braunnnsys")
local screen = require("Screen")
local UI = require("ui")
local _lex = require("/sbin/CEditor/Data/lex")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local opened_file = nil
local COLORS = {
    ["whitespace"] = colors.white, --  whitespace: Self-explanatory. Can match spaces, newlines, tabs, and carriage returns (although I don't know why anyone would use those... WINDOWS)
    ["comment"] = colors.gray, --  comment: Either multi-line or single-line comments.
    ["string"] = colors.green, --  string: A string. Usually the part of the string that is not an escape.
    ["escape"] = colors.white, --  escape: Can only be found within strings (although they are separate tokens)
    ["keyword"] = colors.blue, --  keyword: Keywords. Like "while", "end", "do", etc
    ["value"] = colors.pink, --  value: Special values. Only true, false, and nil.
    ["ident"] = colors.cyan, --  ident: Identifier. Variables, function names, etc..
    ["number"] = colors.white, --  number: Numbers!
    ["symbol"] = colors.white, --  symbol: Symbols, like brackets, parenthesis, ., .., ... etc
    ["operator"] = colors.white, --  operator: Operators, like =, ==, >=, <=, ~=, etc
    ["unidentified"] = colors.red, --  unidentified: Anything that isn't one of the above tokens. Consider them ERRORS.
    ["function"] = colors.purple,
    ["nfunction"] = colors.yellow,
    ["values"] = colors.red,
    ["equality"] = colors.red,
    ["arg"] = colors.white
}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "CEditor")

local menu = UI.New_Menu(1, 1, "File", {"New","Open", "Save", "Save as"}, colors.white, colors.black)
window:addChild(menu)

local textbox = UI.New_TextBox(6, 1, surface.w - 6, surface.h - 1, colors.black, colors.white)
surface:addChild(textbox)

textbox.draw = function (self)
    local char = string.char(149)
    screen.draw_rectangle(1, 2, 4, surface.h, colors.gray)
    screen.clip_set(1, 1, self.w + self.x - 1, surface.h)
    screen.draw_rectangle(self.x, self.y, self.w, self.h, self.color_bg)
    for j = self.scroll.pos_y + 1, _min(self.h + self.scroll.pos_y, #self.lines) do
        local tokens = table.unpack(_lex(self.lines[j]))
        for i, token in pairs(tokens) do
            screen.write(token.data, token.posFirst + self.x - self.scroll.pos_x - 1, j - self.scroll.pos_y + self.y - 1, self.color_bg, COLORS[token.type])
        end
        local num = #tostring(j)
        local color_txt = colors.lightGray
        if self.cursor.y == j then
            color_txt = colors.white
        end
        screen.write(_rep(" ", 4 - num) .. tostring(j), 1, j - self.scroll.pos_y + self.y - 1, colors.gray, color_txt)
    end
    screen.clip_remove()
    for i = self.y, self.y + surface.h - 1 do
        screen.write(char, 5, i, self.color_bg, colors.gray)
    end
end

local scrollbar_v = UI.New_Scrollbar(textbox)
surface:addChild(scrollbar_v)

local scrollbar_h = UI.New_Scrollbar_Horizontal(textbox)
surface:addChild(scrollbar_h)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------

-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
menu.pressed = function (self, id)
    if id == 1 then
        opened_file = nil
        textbox:clear()
        textbox.root.focus = textbox
    elseif id == 2 then
        local path = UI.New_DialWin(" Open ", "Enter path to file:")
        if not path then
            window:onLayout()
            return
        end
        if not fs.exists(path) then
            UI.New_MsgWin("INFO", " Error ", "File not found")
            window:onLayout()
            return
        end
        textbox:clear()
        local i = 1
        for line in io.lines(path) do
            textbox:setLine(line, i)
            i = i + 1
        end
        opened_file = path
        window:onLayout()
        textbox.root.focus = textbox
    elseif id == 3 then
        if opened_file then
            local file = fs.open(opened_file, "w")
            for _, v in pairs(textbox.lines) do
                file.writeLine(v)
            end
            file.close()
        end
    elseif id == 4 then
        local path = UI.New_DialWin(" Save as ", "Enter path to save:")
        if not path then
            window:onLayout()
            return
        end
        if fs.exists(path) then
            local answ = UI.New_MsgWin("YES,NO", " Message ", "File is already exists. Do you want to override it?")
            window:onLayout()
            if not answ then return end
        end
        local file = fs.open(path, "w")
        for _, v in pairs(textbox.lines) do
            file.writeLine(v)
        end
        file.close()
    end
end

local temp = textbox.moveCursorPos
textbox.moveCursorPos = function (self, x, y)
    temp(self, x, y)
    self.dirty = true
end

surface.draw = function (self)
    screen.draw_rectangle(self.x, self.y, self.w, self.h, self.color_bg)
end

surface.onResize = function (width, height)
    textbox.w = width - 6
    textbox.h = height - 1
    textbox.scrollbar_v.h = height - 1
    textbox.scrollbar_v.local_x = width
    textbox.scrollbar_h.w = width - 6
    textbox.scrollbar_h.local_y = height
end

local temp_pressed = window.close.pressed
window.close.pressed = function (self)
    package.loaded["/sbin/CEditor/Data/lex"] = nil
    return temp_pressed(self)
end
-----------------------------------------------------
textbox.root.focus = textbox
surface:onLayout()