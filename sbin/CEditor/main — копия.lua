------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local _min = math.min
local _max = math.max
local _sub = string.sub
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

-- Попереднє обчислення кольорів для Blit (швидкий доступ)
local to_blit = colors.toBlit
local COLOR_BLITS = {}
for k, v in pairs(COLORS) do
    COLOR_BLITS[k] = to_blit(v)
end
local BG_BLIT = to_blit(textbox.color_bg)
local DEFAULT_TXT_BLIT = to_blit(colors.white)

-- Кеш для токенів, щоб не викликати _lex постійно
textbox.lex_cache = {}
textbox.lex_cache_text = {} 

-- Отримуємо прямий доступ до буфера екрану для екстремальної швидкості
local screen_buffer = screen.get_buffer()

-- Швидка функція запису рядка прямо в буфер (минаючи screen.write)
local function fast_blit_write(y, x, text, fg, bg)
    local cx, cy, cw, ch = screen.clip_get()
    
    -- Вертикальна перевірка
    if y < cy or y > ch then return end
    
    -- Розрахунок горизонтального відсікання
    local start_draw = _max(x, cx)
    local end_draw   = _min(x + #text - 1, cw)
    
    if start_draw > end_draw then return end

    local offset = start_draw - x + 1
    local len = end_draw - start_draw + 1
    local frame = screen_buffer[y]

    -- "Хірургічна" вставка в рядок буфера
    local prefix = start_draw - 1
    local suffix = end_draw + 1

    frame.text = _sub(frame.text, 1, prefix) .. _sub(text, offset, offset + len - 1) .. _sub(frame.text, suffix)
    frame.color_txt = _sub(frame.color_txt, 1, prefix) .. _sub(fg, offset, offset + len - 1) .. _sub(frame.color_txt, suffix)
    frame.color_bg = _sub(frame.color_bg, 1, prefix) .. _sub(bg, offset, offset + len - 1) .. _sub(frame.color_bg, suffix)
end

textbox.draw = function (self)
    -- Малюємо фон відступів та лінії
    screen.draw_rectangle(1, 2, 4, surface.h, colors.gray)
    local separator_char = string.char(149)
    for i = self.y, self.y + surface.h - 1 do
        screen.write(separator_char, 5, i, self.color_bg, colors.gray)
    end

    -- Встановлюємо кліппінг для тексту
    screen.clip_set(self.x, self.y, self.w, self.h)
    screen.draw_rectangle(self.x, self.y, self.w, self.h, self.color_bg) -- Очищення фону

    local start_line = self.scroll.pos_y + 1
    local end_line = _min(self.h + self.scroll.pos_y, #self.lines)

    for j = start_line, end_line do
        local raw_text = self.lines[j]
        
        -- 1. КЕШУВАННЯ: Лексимо тільки якщо текст змінився
        local tokens = self.lex_cache[j]
        if self.lex_cache_text[j] ~= raw_text then
             -- Прибираємо table.unpack, _lex зазвичай повертає таблицю токенів
            tokens = table.unpack(_lex(raw_text))
            self.lex_cache[j] = tokens
            self.lex_cache_text[j] = raw_text
        end

        -- 2. БУФЕРИЗАЦІЯ: Збираємо рядок кольорів (fg)
        -- Замість десятків викликів screen.write, ми будуємо один blit-рядок
        local blit_fg_parts = {}
        local last_pos = 1
        
        -- Якщо tokens повернувся як розпакований список (залежить від вашого lex.lua), 
        -- то тут треба адаптувати. Припускаємо, що tokens - це { {type=.., posFirst=..}, ... }
        if tokens then
            for _, token in pairs(tokens) do
                -- Заповнюємо пропуски (пробіли, які лексер міг пропустити)
                local gap = token.posFirst - last_pos
                if gap > 0 then 
                    table.insert(blit_fg_parts, _rep(DEFAULT_TXT_BLIT, gap)) 
                end
                
                -- Додаємо колір токена
                local len = #token.data
                local color_char = COLOR_BLITS[token.type] or DEFAULT_TXT_BLIT
                table.insert(blit_fg_parts, _rep(color_char, len))
                
                last_pos = token.posFirst + len
            end
        end
        
        -- Дозаповнюємо кінець рядка дефолтним кольором, якщо треба
        if last_pos <= #raw_text then
            table.insert(blit_fg_parts, _rep(DEFAULT_TXT_BLIT, #raw_text - last_pos + 1))
        end

        local full_fg_str = table.concat(blit_fg_parts)
        local full_bg_str = _rep(BG_BLIT, #raw_text) -- Припускаємо, що фон коду однорідний

        -- 3. СКРОЛЛІНГ ПО ГОРИЗОНТАЛІ
        local visible_len = self.w
        local s_pos = self.scroll.pos_x + 1
        local e_pos = s_pos + visible_len - 1

        local draw_text = _sub(raw_text, s_pos, e_pos)
        local draw_fg   = _sub(full_fg_str, s_pos, e_pos)
        local draw_bg   = _sub(full_bg_str, s_pos, e_pos)

        -- 4. ШВИДКИЙ ВИВІД
        -- Один виклик на рядок замість N викликів на рядок
        local draw_y = j - self.scroll.pos_y + self.y - 1
        fast_blit_write(draw_y, self.x, draw_text, draw_fg, draw_bg)

        -- Малюємо номер рядка (старий код)
        local num = tostring(j)
        local num_color = (self.cursor.y == j) and colors.white or colors.lightGray
        screen.write(_rep(" ", 4 - #num) .. num, 1, draw_y, colors.gray, num_color)
    end

    -- Відновлюємо кліппінг для малювання виділення
    screen.clip_remove() -- Або повертаємо кліппінг surface, якщо потрібно
    
    -- ... (код малювання виділення/selected text залишаємо без змін, він виконується рідко)
    if self.selected.status and self.lines[1] then
        local p1 = self.selected.pos1
        local p2 = self.selected.pos2
        local s, e = p1, p2
        if p1.y > p2.y or (p1.y == p2.y and p1.x > p2.x) then
            s, e = p2, p1
        end

        screen.clip_set(self.x, self.y, self.w, self.h)
        local start = _max(s.y, start_line)
        local _end = _min(e.y, end_line)
        for i = start, _end do
            local line_str = self.lines[i] or ""
            local sel_x_start = (i == s.y) and s.x or 1
            local sel_x_end = (i == e.y) and e.x or #line_str
            
            if sel_x_start <= sel_x_end + 1 then
                local sel_text = _sub(line_str, sel_x_start, sel_x_end)
                if #line_str == 0 and i ~= e.y and i ~= s.y then sel_text = " " end
                local draw_x = self.x + (sel_x_start - 1) - self.scroll.pos_x
                local draw_y = self.y + (i - self.scroll.pos_y) - 1
                screen.write(sel_text, draw_x, draw_y, colors.blue, colors.white)
            end
        end
        screen.clip_remove()
    end
end

-- Очищення кешу при зміні файлу/очищенні
local old_clear = textbox.clear
textbox.clear = function(self)
    self.lex_cache = {}
    self.lex_cache_text = {}
    old_clear(self)
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

local preff_x
local temp_key = textbox.onKeyDown
textbox.onKeyDown = function (self, key, held)
    if not preff_x then preff_x = self.cursor.x end
    if key == keys.up then
        self:moveCursorPos(preff_x, self.cursor.y - 1)
        return true
    elseif key == keys.down then
        self:moveCursorPos(preff_x, self.cursor.y + 1)
        return true
    else
        preff_x = nil
    end
    return temp_key(self, key, held)
end

surface.draw = function (self)
    screen.draw_rectangle(self.x, self.y, self.w, self.h, self.color_bg)
end

surface.onMouseDown = function (self, btn, x, y)
    if x < 5 and y < self.y + self.h - 1 then
        local igrik = y - self.y + 1
        if textbox.lines[igrik] then
            textbox.selected.status = true
            textbox.selected.pos1 = {x = 1, y = igrik}
            textbox.selected.pos2 = {x = #textbox.lines[igrik], y = igrik}
            if textbox.lines[igrik + 1] then
                textbox:moveCursorPos(1, igrik + 1)
            else
                textbox:moveCursorPos(#textbox.lines[igrik] + 1, igrik)
            end
            textbox.root.focus = textbox
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