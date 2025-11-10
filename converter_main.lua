-- Таблица транслитерации кириллицы в латиницу (по кодпоинтам Unicode)
local table_insert = table.insert
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

local termTxtcol = term.getTextColor()

-- Функция декодирования текста по encoding и транслитерации/фильтра
local function decode_and_translit(encoding, text)
    if not text then return "" end
    local codepoints = {}

    if encoding == 0 then  -- ISO-8859-1 или Windows-1251
        local has_cyrillic = false
        for i = 1, #text do
            local b = text:byte(i)
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
                local b = text:byte(i)
                local cp = (b >= 128 and win1251_to_uni[b]) or b
                if cp then
                    table_insert(codepoints, cp)
                end
            end
        else
            -- Чистый ISO-8859-1
            for i = 1, #text do
                table_insert(codepoints, text:byte(i))
            end
        end
    elseif encoding == 3 then  -- UTF-8
        local i = 1
        while i <= #text do
            local b1 = text:byte(i) or 0
            local cp
            if b1 < 0x80 then
                cp = b1
                i = i + 1
            elseif b1 < 0xE0 then
                local b2 = text:byte(i + 1) or 0
                cp = ((b1 % 0x20) * 0x40) + (b2 % 0x40)
                i = i + 2
            elseif b1 < 0xF0 then
                local b2 = text:byte(i + 1) or 0
                local b3 = text:byte(i + 2) or 0
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
                local b1, b2 = text:byte(1), text:byte(2)
                if b1 == 0xFE and b2 == 0xFF then
                    big_endian = true
                    text = text:sub(3)
                elseif b1 == 0xFF and b2 == 0xFE then
                    big_endian = false
                    text = text:sub(3)
                end
            end
        end
        for j = 1, #text, 2 do
            local high = text:byte(j) or 0
            local low = text:byte(j + 1) or 0
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

-- Функции для чтения ID3 тегов
local function readID3v1(data)
    if #data < 128 then return nil end
    local tag = data:sub(-128)
    if tag:sub(1, 3) ~= "TAG" then return nil end
    -- Для ID3v1 предполагаем encoding 0 (часто Windows-1251)
    return {
        title = decode_and_translit(0, tag:sub(4, 33)),
        artist = decode_and_translit(0, tag:sub(34, 63)),
        album = decode_and_translit(0, tag:sub(64, 93)),
        year = decode_and_translit(0, tag:sub(94, 97)),
        comment = decode_and_translit(0, tag:sub(98, 125)),
        genre = tag:byte(128)
    }
end

local function readID3v2(data)
    if data:sub(1, 3) ~= "ID3" then return nil end
    local version = data:byte(4)
    local revision = data:byte(5)
    local flags = data:byte(6)
    local function decodeSyncSafe(b1, b2, b3, b4)
        return (b1 * 2097152) + (b2 * 16384) + (b3 * 128) + b4
    end
    local size = decodeSyncSafe(data:byte(7), data:byte(8), data:byte(9), data:byte(10))
    local result = { version = version, revision = revision, title = "", artist = "", album = "" }
    local pos = 11
    while pos < size + 10 do
        local frameID = data:sub( pos, pos + 3)
        if frameID == "" or frameID:match("^%z+$") then break end
        local frameSize
        if version == 4 then
            frameSize = decodeSyncSafe(data:byte(pos + 4), data:byte(pos + 5), data:byte(pos + 6), data:byte(pos + 7))
        else
            frameSize = data:byte(pos + 4) * 16777216 + data:byte(pos + 5) * 65536 + data:byte(pos + 6) * 256 + data:byte(pos + 7)
        end
        local frameFlags = data:byte(pos + 8) * 256 + data:byte(pos + 9)
        local frameData = data:sub(pos + 10, pos + 9 + frameSize)
        local function decodeText(data)
            local encoding = data:byte(1) or 0
            local text = data:sub(2)
            return decode_and_translit(encoding, text)
        end
        if frameID == "TIT2" then result.title = decodeText(frameData)
        elseif frameID == "TPE1" then result.artist = decodeText(frameData)
        elseif frameID == "TALB" then result.album = decodeText(frameData) end
        pos = pos + 10 + frameSize
    end
    return result
end

local function readMP4Metadata(data)
    --print("Starting MP4 metadata reading. File size:", #data)

    local function readAtom(pos)
        if pos > #data - 8 then
            return 0, "", pos
        end
        local b = function(p) return data:byte(p) or 0 end
        local size = b(pos) * 16777216 + b(pos+1) * 65536 + b(pos+2) * 256 + b(pos+3)
        local atype = data:sub(pos+4, pos+7)

        -- extended size
        if size == 1 and pos + 16 <= #data then
            local ext = 0
            for i = 0, 7 do ext = ext * 256 + b(pos + 8 + i) end
            return ext, atype, pos + 16
        end
        return size, atype, pos + 8
    end

    local function safeReadUInt32(p)
        local b = function(q) return data:byte(q) or 0 end
        return b(p) * 16777216 + b(p+1) * 65536 + b(p+2) * 256 + b(p+3)
    end

    local result = { title = "", artist = "", album = "" }

    local function processContainer(startPos, endPos)
        local pos = startPos
        while pos < endPos do
            local size, atype, payloadStart = readAtom(pos)
            if size == 0 or size > #data then break end

            if atype == "ilst" then
                --print("Found ilst container at", pos, "size", size)
                local ilstEnd = pos + size
                local itemPos = payloadStart
                while itemPos < ilstEnd do
                    local itemSize, itemType, itemPayload = readAtom(itemPos)
                    if itemSize == 0 or itemSize > #data then break end

                    -- читаємо внутрішній data-атом, який повинен починатися в itemPayload
                    local dataAtomSize = safeReadUInt32(itemPayload)
                    local dataAtomType = data:sub(itemPayload+4, itemPayload+7)

                    if dataAtomType == "data" then
                        -- payload of 'data' atom starts at itemPayload + 8
                        -- first 4 bytes = data type indicator, next 4 bytes = locale/flags
                        local valueStart = itemPayload + 8 + 8  -- -> itemPayload + 16
                        local valueEnd = itemPayload + dataAtomSize - 1
                        if valueStart <= valueEnd and valueEnd <= #data then
                            local raw = data:sub(valueStart, valueEnd)

                            -- визначимо кодування: якщо починається з BOM utf16 -> використаємо encoding=1, інакше utf8
                            local b1, b2 = raw:byte(1) or 0, raw:byte(2) or 0
                            local encoding = 3 -- utf-8 за замовчуванням
                            if b1 == 0xFE and b2 == 0xFF or (b1 == 0xFF and b2 == 0xFE) then
                                encoding = 1 -- UTF-16 (BOM)
                            end

                            local value = decode_and_translit(encoding, raw)
                            --print("Found metadata:", itemType, "=", value)

                            local suffix = (itemType:sub(-3) or ""):lower()
                            if suffix == "nam" then result.title = value
                            elseif suffix == "art" then
                                -- '©ART' or 'aART' both end with 'ART'
                                result.artist = value
                            elseif suffix == "alb" then result.album = value end
                        else
                            term.setTextColor(colors.red)
                            print("Data atom bounds invalid:", valueStart, valueEnd, "#data=", #data)
                            term.setTextColor(termTxtcol)
                        end
                    end

                    itemPos = itemPos + itemSize
                end

                break
            elseif atype == "moov" or atype == "udta" or atype == "meta" then
                local skip = (atype == "meta") and 4 or 0 -- meta має 4 байти після заголовка (version/flags)
                processContainer(payloadStart + skip, pos + size)
            end

            pos = pos + size
        end
    end

    processContainer(1, #data)
    return result
end

local function do_loading()
    print("")
    while true do
        local pos = {term.getCursorPos()}
        sleep(0.5)
        term.setTextColor(colors.yellow)
        write("Loading.  ")
        term.setTextColor(termTxtcol)
        term.setCursorPos(pos[1], pos[2])
        sleep(0.5)
        term.setTextColor(colors.yellow)
        write("Loading.. ")
        term.setTextColor(termTxtcol)
        term.setCursorPos(pos[1], pos[2])
        sleep(0.5)
        term.setTextColor(colors.yellow)
        write("Loading...")
        term.setTextColor(termTxtcol)
        term.setCursorPos(pos[1], pos[2])
    end
end

local function checkExit(command)
    if command == "q" or command == "quit" or command == "e" or command == "exit" or command == "" then
        term.setTextColor(colors.red)
        print("\nConvert aborted")
        term.setTextColor(termTxtcol)
        os.sleep(1)
        return true
    end
    return false
end

term.setTextColor(colors.yellow)
print("To abort conversion, type 'q', 'quit', 'e', or 'exit' at any prompt.")
term.setTextColor(colors.green)
print("Specify the path to the audio file (e.g., .mp3, .m4a)")
term.setTextColor(termTxtcol)

local filePath = read()
if checkExit(filePath) then return end

while not filePath or fs.exists(filePath) == false do
    term.setTextColor(colors.red)
    print("\nFile not found: " .. tostring(filePath))
    print("Try again.")
    term.setTextColor(termTxtcol)

    filePath = read()
    if checkExit(filePath) then return end
end

local ext
local file
local data
local tags
local function MAIN1()
    ext = filePath:match("%.([^%.]+)$"):lower()

    file = fs.open(filePath, "rb")
    data = file.readAll()
    file.close()

    tags = {}
    if ext == "mp3" then
        tags = readID3v2(data) or readID3v1(data) or {}
    elseif ext == "m4a" then
        tags = readMP4Metadata(data) or {}
    else
        term.setTextColor(colors.red)
        print("Unsupported format: " .. ext .. ". Metadata extraction skipped.")
        term.setTextColor(termTxtcol)
    end

    tags.title = tags.title ~= "" and tags.title or "Unknown"
    tags.artist = tags.artist ~= "" and tags.artist or "Unknown"
    tags.album = tags.album ~= "" and tags.album or "Unknown"
end

parallel.waitForAny(do_loading, MAIN1)

term.setTextColor(colors.yellow)
print("\nTrack information:")
print("Title: " .. tags.title)
print("Artist: " .. tags.artist)
print("Album: " .. tags.album)
term.setTextColor(colors.green)
print("\nContinue convert? (y/n)")
term.setTextColor(termTxtcol)

if read():lower() ~= "y" then
    term.setTextColor(colors.red)
    print("\nConvert aborted")
    term.setTextColor(termTxtcol)
    return
end

term.setTextColor(colors.green)
write("\nSpecify the name and path of the file")
term.setTextColor(colors.red)
write(" without the extension.")
term.setTextColor(colors.yellow)
print("\nExample: folder/file")
term.setTextColor(termTxtcol)

os.queueEvent("paste", "home/Music/")
local fileSave = read()
if checkExit(fileSave) then return end
fileSave = fileSave .. ".dfpwm"

local function MAIN2()
    local file = fs.open(filePath, "rb")
    local data = file.readAll()
    file.close()

    local success, response = pcall(http.post, "https://remote.craftos-pc.cc/music/upload", data, {["Content-Type"] = "application/octet-stream"})
    if not success then
        term.setTextColor(colors.red)
        print("http.post error: " .. response)
        term.setTextColor(termTxtcol)
        return
    end

    local id = response.readAll()
    response.close()

    local wavUrl = "https://remote.craftos-pc.cc/music/content/" .. id .. ".wav"
    local request = http.get(wavUrl)
    if not request then
        term.setTextColor(colors.red)
        print("Downloading error")
        term.setTextColor(termTxtcol)
        return
    end

    local wavData = request.readAll()
    request.close()

    local dataPos = wavData:find("data", 1, true)
    local dfpwmRaw = wavData  -- По умолчанию весь файл
    if dataPos then
        local b1 = wavData:byte(dataPos + 4) or 0
        local b2 = wavData:byte(dataPos + 5) or 0
        local b3 = wavData:byte(dataPos + 6) or 0
        local b4 = wavData:byte(dataPos + 7) or 0
        local chunkSize = b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)

        dfpwmRaw = wavData:sub(dataPos + 8, dataPos + 7 + chunkSize)
    else
        term.setTextColor(colors.red)
        print("Chunck 'data' not found! Saving file...")
        term.setTextColor(termTxtcol)
    end

    local meta_block = "\n--METADATA--\n" ..
                    "Title:" .. tags.title .. "\n" ..
                    "Artist:" .. tags.artist .. "\n" ..
                    "Album:" .. tags.album .. "\n" ..
                    "--ENDMETADATA--\n"

    local outputfile = fs.open(fileSave, "wb")
    outputfile.write(dfpwmRaw .. meta_block)
    outputfile.close()

    term.setTextColor(colors.green)
    print("[Success]: Convertation has been completed. Metadata added to file.")
    term.setTextColor(termTxtcol)
end

parallel.waitForAny(do_loading, MAIN2)
os.sleep(1)