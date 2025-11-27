local toBlit = colors.toBlit
local _rep = string.rep
local _sub = string.sub
local _min = math.min
local _max = math.max

local _render = {}

local screen_w, screen_h = term.getSize()

-- Буфер экрана
local screenFrame = {}

-- Переменные для Clipping (Ограничение области рисования)
-- По умолчанию область - весь экран
local clip_x1, clip_y1, clip_x2, clip_y2 = 1, 1, screen_w, screen_h

function _render.init()
    screen_w, screen_h = term.getSize()
    clip_x1, clip_y1, clip_x2, clip_y2 = 1, 1, screen_w, screen_h
    for i = 1, screen_h do
        screenFrame[i] = {
            text = _rep(" ", screen_w),
            color_bg = _rep(toBlit(32768), screen_w),
            color_txt = _rep(toBlit(1), screen_w)
        }
    end
end
_render.init() -- Вызываем при загрузке

-- Функция установки области видимости (вместо window.create)
function _render.setClip(x, y, w, h)
    clip_x1 = _max(1, x)
    clip_y1 = _max(1, y)
    clip_x2 = _min(screen_w, x + w - 1)
    clip_y2 = _min(screen_h, y + h - 1)
end

-- Сброс области видимости на весь экран
function _render.removeClip()
    clip_x1, clip_y1, clip_x2, clip_y2 = 1, 1, screen_w, screen_h
end

-- Безопасная функция записи в буфер
function _render.write(str, x, y, bg, txt)
    -- 1. Проверка по вертикали (включая клиппинг)
    if y < clip_y1 or y > clip_y2 then return end

    -- Получаем текущую строку
    local lineObj = screenFrame[y]
    if not lineObj then return end -- Защита от nil

    -- 2. Вычисление видимой части строки по горизонтали
    -- Начало строки должно быть не левее clip_x1
    -- Конец строки не правее clip_x2

    local start_draw = _max(x, clip_x1)
    local end_draw   = _min(x + #str - 1, clip_x2)

    -- Если строка полностью за пределами видимости - уходим
    if start_draw > end_draw then return end

    -- 3. Обрезка входящей строки (если часть ушла за край)
    -- local offset = start_draw - x
    -- Нам нужно вырезать из str кусок, который реально попадет на экран
    local str_offset = start_draw - x + 1
    local str_len = end_draw - start_draw + 1

    local visible_str = _sub(str, str_offset, str_offset + str_len - 1)

    -- Генерируем строки цветов
    local visible_bg = _rep(toBlit(bg), #visible_str)
    local visible_txt = _rep(toBlit(txt), #visible_str)

    -- 4. Вклейка в буфер (String Patching)
    -- Важно: используем start_draw, так как x мог быть меньше 1
    local prefix_len = start_draw - 1
    local suffix_start = end_draw + 1

    lineObj.text = _sub(lineObj.text, 1, prefix_len) .. visible_str .. _sub(lineObj.text, suffix_start)
    lineObj.color_bg = _sub(lineObj.color_bg, 1, prefix_len) .. visible_bg .. _sub(lineObj.color_bg, suffix_start)
    lineObj.color_txt = _sub(lineObj.color_txt, 1, prefix_len) .. visible_txt .. _sub(lineObj.color_txt, suffix_start)
end

function _render.drawRectangle(x, y, w, h, bg)
    -- Используем write для рисования прямоугольника, так как write теперь умный и безопасный
    local line = _rep(" ", w)
    for j = y, y + h - 1 do
        -- Передаем bg как цвет фона, и любой цвет текста (тут пробелы)
        _render.write(line, x, j, bg, 1)
    end
end

function _render.draw()
    for i = 1, #screenFrame do
        term.setCursorPos(1,i)
        term.blit(screenFrame[i].text, screenFrame[i].color_txt, screenFrame[i].color_bg)
    end
end

function _render.blittle_draw(image, x, y)
    local t, tC, bC = image[1], image[2], image[3]
    x, y = x or 1, y or 1  -- terminal не нужен, т.к. мы работаем с буфером

    for i = 1, image.height do
        local tI = t[i]
        local fg_str = tC[i]  -- FG (color_txt)
        local bg_str = bC[i]  -- BG (color_bg)
        local y_eff = y + i - 1

        -- Проверка по вертикали (с учетом клиппинга)
        if y_eff < clip_y1 or y_eff > clip_y2 then
            goto continue  -- Пропускаем строку, если за пределами
        end

        local frame = screenFrame[y_eff]
        if not frame then
            goto continue  -- Защита от nil (хотя буфер должен быть полным)
        end

        local eff_x, text
        if type(tI) == "string" then
            eff_x = x
            text = tI
        elseif type(tI) == "table" then
            eff_x = x + (tI[1] or 0)  -- Смещение из таблицы
            text = tI[2] or ""  -- Текст из таблицы
        else
            goto continue  -- Некорректный тип, пропускаем
        end

        local len = #text
        if len == 0 then
            goto continue
        end

        -- Вычисление видимой части (горизонтальный клиппинг)
        local start_draw = _max(eff_x, clip_x1)
        local end_draw = _min(eff_x + len - 1, clip_x2)
        if start_draw > end_draw then
            goto continue  -- Полностью за пределами
        end

        -- Обрезка строк (текст, fg, bg)
        local offset = start_draw - eff_x + 1
        local vis_len = end_draw - start_draw + 1
        local vis_text = _sub(text, offset, offset + vis_len - 1)
        local vis_fg = _sub(fg_str, offset, offset + vis_len - 1)
        local vis_bg = _sub(bg_str, offset, offset + vis_len - 1)

        -- Вставка в буфер (прямая замена частей строк)
        local prefix_len = start_draw - 1
        local suffix_start = end_draw + 1

        frame.text = _sub(frame.text, 1, prefix_len) .. vis_text .. _sub(frame.text, suffix_start)
        frame.color_txt = _sub(frame.color_txt, 1, prefix_len) .. vis_fg .. _sub(frame.color_txt, suffix_start)
        frame.color_bg = _sub(frame.color_bg, 1, prefix_len) .. vis_bg .. _sub(frame.color_bg, suffix_start)

        ::continue::
    end
end

return _render