------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local _min = math.min
local _max = math.max
local _sub = string.sub
local _rep = string.rep
local _gsub = string.gsub
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

local menu = UI.New_Menu(1, 1, "File", {"New", "Open", "Save", "Save as"}, colors.white, colors.black)
window:addChild(menu)

local textbox = UI.New_TextBox(6, 1, surface.w - 6, surface.h - 1, colors.black, colors.white)
surface:addChild(textbox)

textbox.draw = function (self)
    screen.draw_rectangle(1, self.y, 4, self.h + 1, colors.gray)
    screen.clip_set(1, 2, self.w + self.x - 1, surface.h)
    screen.draw_rectangle(self.x, self.y, self.w, self.h, self.color_bg)
    for j = self.scroll.pos_y + 1, _min(self.h + self.scroll.pos_y, #self.lines) do
        local tokens = table.unpack(_lex(self.lines[j]))
        for _, token in ipairs(tokens) do
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

    local char = string.char(149)
    for i = self.y, self.y + surface.h - 1 do
        screen.write(char, 5, i, self.color_bg, colors.gray)
    end

    screen.clip_set(self.x, self.y, self.w + self.x + 1, self.h + self.y + 1)
    if self.selected.status then
        local p1 = self.selected.pos1
        local p2 = self.selected.pos2
        for i = p1.y, p2.y do
            local line_str = self.lines[i] or ""
            local sel_x_start = 1
            local sel_x_end = #line_str
            if i == p1.y then
                sel_x_start = p1.x
            end
            if i == p2.y then
                sel_x_end = p2.x
            end
            if sel_x_start <= sel_x_end + 1 then
                local sel_text = _sub(line_str, sel_x_start, sel_x_end)
                if #line_str == 0 and i ~= p2.y and i ~= p1.y then sel_text = " " end
                sel_text = _gsub(sel_text, " ", string.char(183))
                local draw_x = self.x + (sel_x_start - 1) - self.scroll.pos_x
                local draw_y = self.y + (i - self.scroll.pos_y) - 1
                screen.write(sel_text, draw_x, draw_y, colors.lightGray, colors.white)
            end
        end
    end
    screen.clip_remove()
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
    if id == "New" then
        opened_file = nil
        textbox:clear()
        textbox.root.focus = textbox
    elseif id == "Open" then
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
    elseif id == "Save" then
        if opened_file then
            local file = fs.open(opened_file, "w")
            for _, v in pairs(textbox.lines) do
                file.writeLine(v)
            end
            file.close()
        end
    elseif id == "Save as" then
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
        if not opened_file then opened_file = path end
    end
end

local temp = textbox.moveCursorPos
textbox.moveCursorPos = function (self, x, y)
    temp(self, x, y)
    self.dirty = true
end

local preff_x
local alt_held = false
local temp_key = textbox.onKeyDown
textbox.onKeyDown = function (self, key, held)
    if not preff_x then preff_x = self.cursor.x end
    if key == keys.leftAlt then
        alt_held = true
        return true
    elseif key == keys.up then
        local cp = self.cursor
        if cp.y == 1 and cp.x ~= 1 then cp.x = 1 end
        if alt_held then
            if self.selected.status then
                local p1 = self.selected.pos1
                local p2 = self.selected.pos2
                if p1.y > 1 then
                    local line = self.lines[p1.y - 1]
                    table.move(self.lines, p1.y, p2.y, p1.y - 1)
                    self:setLine(line, p2.y)
                    p1.y = p1.y - 1
                    p2.y = p2.y - 1
                    if p1.y < self.scroll.pos_y then
                        self:scrollY(-1 / self.scroll.sensitivity_y)
                    end
                    self:moveCursorPos(preff_x, self.cursor.y - 1)
                end
                return true
            end
            if cp.y == 1 then return true end
            local line = self.lines[cp.y - 1]
            table.move(self.lines, cp.y, cp.y, cp.y - 1)
            self:setLine(line, cp.y)
        end
    elseif key == keys.down then
        local cp = self.cursor
        local n = #self.lines
        if cp.y == n and cp.x ~= #self.lines[n] then cp.x = #self.lines[n] end
        if alt_held then
            if self.selected.status then
                local p1 = self.selected.pos1
                local p2 = self.selected.pos2
                local lines = self.lines
                if p2.y < #lines then
                    local line = lines[p2.y + 1]
                    table.move(lines, p1.y, p2.y, p1.y + 1)
                    self:setLine(line, p1.y)
                    p1.y = p1.y + 1
                    p2.y = p2.y + 1
                    if p2.y > self.h + self.scroll.pos_y then
                        self:scrollY(1 / self.scroll.sensitivity_y)
                    end
                    self:moveCursorPos(preff_x, self.cursor.y + 1)
                end
                return true
            end
            if cp.y == 1 then return true end
            local line = self.lines[cp.y + 1]
            table.move(self.lines, cp.y, cp.y, cp.y + 1)
            self:setLine(line, cp.y)
        end
    else
        preff_x = nil
    end
    return temp_key(self, key, held)
end

local temp_keyUp = textbox.onKeyUp
textbox.onKeyUp = function (self, key)
    if key == keys.leftAlt then
        alt_held = false
        return true
    end
    return temp_keyUp(self, key)
end

surface.onMouseDown = function (self, btn, x, y)
    if x < 5 and y < self.y + self.h - 1 then
        local igrik = y - self.y + 1 + textbox.scroll.pos_y
        if textbox.lines[igrik] then
            local selected = textbox.selected
            selected.status = true
            textbox.click_pos = {x = 1, y = igrik}
            selected.pos1 = {x = 1, y = igrik}
            selected.pos2 = {x = #textbox.lines[igrik], y = igrik}
            if textbox.lines[igrik + 1] then
                textbox:moveCursorPos(1, igrik + 1)
            else
                textbox:moveCursorPos(#textbox.lines[igrik] + 1, igrik)
            end
            self.root.focus = textbox
            textbox.dirty = true
        end
        return true
    end
    return false
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