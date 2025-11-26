local string_sub = string.sub
local string_byte = string.byte
local table_insert = table.insert
-- Таблица транслитерации кириллицы в латиницу (по кодпоинтам Unicode)
local translit_table = {
    [0x0410] = 'A', [0x0411] = 'B', [0x0412] = 'V', [0x0413] = 'G', [0x0414] = 'D',
    [0x0415] = 'E', [0x0401] = 'Yo', [0x0416] = 'Zh', [0x0417] = 'Z', [0x0418] = 'I',
    [0x0419] = 'J', [0x041A] = 'K', [0x041B] = 'L', [0x041C] = 'M', [0x041D] = 'N',
    [0x041E] = 'O', [0x041F] = 'P', [0x0420] = 'R', [0x0421] = 'S', [0x0422] = 'T',
    [0x0423] = 'U', [0x0424] = 'F', [0x0425] = 'H', [0x0426] = 'C', [0x0427] = 'Ch',
    [0x0428] = 'Sh', [0x0429] = 'Shch', [0x042A] = '', [0x042B] = 'Y', [0x042C] = '',
    [0x042D] = 'E', [0x042E] = 'Yu', [0x042F] = 'Ya',
    [0x0430] = 'a', [0x0431] = 'b', [0x0432] = 'v', [0x0433] = 'g', [0x0434] = 'd',
    [0x0435] = 'e', [0x0451] = 'yo', [0x0436] = 'zh', [0x0437] = 'z', [0x0438] = 'i',
    [0x0439] = 'j', [0x043A] = 'k', [0x043B] = 'l', [0x043C] = 'm', [0x043D] = 'n',
    [0x043E] = 'o', [0x043F] = 'p', [0x0440] = 'r', [0x0441] = 's', [0x0442] = 't',
    [0x0443] = 'u', [0x0444] = 'f', [0x0445] = 'h', [0x0446] = 'c', [0x0447] = 'ch',
    [0x0448] = 'sh', [0x0449] = 'shch', [0x044A] = '', [0x044B] = 'y', [0x044C] = '',
    [0x044D] = 'e', [0x044E] = 'yu', [0x044F] = 'ya',
    -- Украинские специфические
    [0x0406] = 'I', [0x0456] = 'i',  -- І і
    [0x0407] = 'Yi', [0x0457] = 'yi',  -- Ї ї
    [0x0490] = 'G', [0x0491] = 'g',  -- Ґ ґ
    [0x02BC] = ''  -- Модификатор апострофа ʼ (опускается в официальной транслитерации)
}

local ret = {}
-- Функция декодирования текста по encoding и транслитерации/фильтра
function ret.decode_and_translit(encoding, text)
    if not text then return "" end
    local codepoints = {}

    if encoding == 0 then  -- ISO-8859-1 или Windows-1251
        local has_cyrillic = false
        for i = 1, #text do
            local b = string_byte(text, i)
            if b >= 0xC0 then  -- Вероятно, Windows-1251
                has_cyrillic = true
                break
            end
        end
        if has_cyrillic then
            -- Маппинг Windows-1251 в Unicode codepoints
            local win1251_to_uni = {
                [0xA8] = 0x0401,  -- Ё
                [0xB8] = 0x0451,  -- ё
                -- Украинские в Windows-1251 (CP1251)
                [0xAF] = 0x0407,  -- Ї
                [0xBF] = 0x0457,  -- ї
                [0xA1] = 0x0406,  -- І
                [0xB2] = 0x0456,  -- і
                [0xA5] = 0x0490,  -- Ґ
                [0xB4] = 0x0491,  -- ґ
                -- Апостроф часто 0x27 или специальный
            }
            for b = 0xC0, 0xDF do
                win1251_to_uni[b] = 0x0410 + (b - 0xC0)  -- А-Я
            end
            for b = 0xE0, 0xFF do
                win1251_to_uni[b] = 0x0430 + (b - 0xE0)  -- а-я
            end
            for i = 1, #text do
                local b = string_byte(text, i)
                local cp = (b >= 128 and win1251_to_uni[b]) or b
                if cp then
                    table_insert(codepoints, cp)
                end
            end
        else
            -- Чистый ISO-8859-1
            for i = 1, #text do
                table_insert(codepoints, string_byte(text, i))
            end
        end
    elseif encoding == 3 then  -- UTF-8
        local i = 1
        while i <= #text do
            local b1 = string_byte(text, i) or 0
            local cp
            if b1 < 0x80 then
                cp = b1
                i = i + 1
            elseif b1 < 0xE0 then
                local b2 = string_byte(text, i + 1) or 0
                cp = ((b1 % 0x20) * 0x40) + (b2 % 0x40)
                i = i + 2
            elseif b1 < 0xF0 then
                local b2 = string_byte(text, i + 1) or 0
                local b3 = string_byte(text, i + 2) or 0
                cp = ((b1 % 0x10) * 0x1000) + ((b2 % 0x40) * 0x40) + (b3 % 0x40)
                i = i + 3
            else
                i = i + 1  -- Пропустить недопустимые
            end
            if cp and cp ~= 0 then
                table_insert(codepoints, cp)
            end
        end
    elseif encoding == 1 or encoding == 2 then  -- UTF-16 with BOM or BE
        local big_endian = (encoding == 2)
        if encoding == 1 then  -- Проверить BOM
            if #text >= 2 then
                local b1, b2 = string_byte(text, 1), string_byte(text, 2)
                if b1 == 0xFE and b2 == 0xFF then
                    big_endian = true
                    text = string_sub(text, 3)
                elseif b1 == 0xFF and b2 == 0xFE then
                    big_endian = false
                    text = string_sub(text, 3)
                end
            end
        end
        for j = 1, #text, 2 do
            local high = string_byte(text, j) or 0
            local low = string_byte(text, j + 1) or 0
            local cp = big_endian and (high * 256 + low) or (low * 256 + high)
            if cp ~= 0 then
                table_insert(codepoints, cp)
            end
        end
    end

    -- Теперь транслитерируем и фильтруем
    local result = ""
    for _, cp in ipairs(codepoints) do
        if cp >= 32 and cp <= 126 then  -- Printable ASCII
            result = result .. string.char(cp)
        elseif translit_table[cp] then
            result = result .. translit_table[cp]
        end  -- Иначе игнорируем
    end
    return (result:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " "))
end

return ret