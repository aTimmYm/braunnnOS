local UI = require("ui")
local screen = require("Screen")
local system = require("braunnnsys")
local _lex = require("/sbin/CEditor/Data/lex")

local _min = math.min
local _rep = string.rep

local opened_file = nil

local COLORS = {
    ["whitespace"] = colors.white, --  whitespace: Self-explanatory. Can match spaces, newlines, tabs, and carriage returns (although I don't know why anyone would use those... WINDOWS)
    ["comment"] = colors.gray, --  comment: Either multi-line or single-line comments.
    ["string"] = colors.purple, --  string: A string. Usually the part of the string that is not an escape.
    ["escape"] = colors.white, --  escape: Can only be found within strings (although they are separate tokens)
    ["keyword"] = colors.cyan, --  keyword: Keywords. Like "while", "end", "do", etc
    ["value"] = colors.red, --  value: Special values. Only true, false, and nil.
    ["ident"] = colors.white, --  ident: Identifier. Variables, function names, etc..
    ["number"] = colors.white, --  number: Numbers!
    ["symbol"] = colors.white, --  symbol: Symbols, like brackets, parenthesis, ., .., ... etc
    ["operator"] = colors.red, --  operator: Operators, like =, ==, >=, <=, ~=, etc
    ["unidentified"] = colors.red, --  unidentified: Anything that isn't one of the above tokens. Consider them ERRORS.
    ["function"] = colors.cyan,
    ["nfunction"] = colors.orange,
    ["values"] = colors.red,
    ["equality"] = colors.red,
    ["arg"] = colors.yellow
}

local window, surface = system.add_window("Titled", colors.black, "bCode")

local textBox = UI.New_TextBox(6, 1, surface.w - 6, surface.h - 1, colors.black, colors.white)
surface:addChild(textBox)

surface.draw = function (self)
    screen.draw_rectangle(self.x, self.y, self.w, self.h, self.color_bg)
end

textBox.draw = function (self)
    screen.draw_rectangle(1, 2, 5, surface.h, colors.gray)
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
        screen.write(_rep(" ", 4 - num) .. tostring(j) .. " ", 1, j - self.scroll.pos_y + self.y - 1, colors.gray, color_txt)
    end
    screen.clip_remove()
end

local temp = textBox.moveCursorPos
textBox.moveCursorPos = function(self, x, y)
    temp(self, x, y)
    self.dirty = true
end

local scrollBar_v = UI.New_Scrollbar(textBox)
local scrollBar_h = UI.New_Scrollbar_Horizontal(textBox)
surface:addChild(scrollBar_v)
surface:addChild(scrollBar_h)

local btnSave = UI.New_Button(6, 1, 4, 1, "Save", "center", window.color_bg, colors.black)
window:addChild(btnSave)

local btnOpenFile = UI.New_Button(1, 1, 4, 1, "Open", "center", window.color_bg, colors.black)
window:addChild(btnOpenFile)

local btnSaveAs = UI.New_Button(11, 1, 7, 1, "Save as", "center", window.color_bg, colors.black)
window:addChild(btnSaveAs)

btnOpenFile.pressed = function(self)
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
    textBox.lines = {}
    local i = 1
    for line in io.lines(path) do
        textBox:setLine(line, i)
        i = i + 1
    end
    opened_file = path
    window:onLayout()
end

btnSave.pressed = function (self)
    if opened_file then
        local f = fs.open(opened_file, "w")
        for i, v in pairs(textBox.lines) do
            f.writeLine(v)
        end
        f.close()
    end
end

btnSaveAs.pressed = function (self)
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
    local f = fs.open(path, "w")
    for i, v in pairs(textBox.lines) do
        f.writeLine(v)
    end
    f.close()
end

surface.onResize = function (width, height)
    textBox.w = width - 6
    textBox.h = height - 1
    textBox.scrollbar_v.h = height - 1
    textBox.scrollbar_v.local_x = width
    textBox.scrollbar_h.w = width - 6
    textBox.scrollbar_h.local_y = height
end

surface:onLayout()