------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_char = string.char
local string_find = string.find
local string_lower = string.lower
local string_gmatch = string.gmatch
local table_insert = table.insert
local table_sort = table.sort
local table_unpack = table.unpack
local coroutine_resume = coroutine.resume
local coroutine_create = coroutine.create
local coroutine_status = coroutine.status
local coroutine_yield = coroutine.yield
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local dfpwm = require("cc.audio.dfpwm")
local system = require("braunnnsys")
local blittle = require("blittle_extended")
local c = require("cfunc")
local UI = require("ui")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
if bOS.shell or bOS.Explorer then return end
-- root.coroutine = {}
-- root.seek_to = nil
-- root.expected_event = nil

if periphemu then periphemu.create("right", "speaker") end
bOS.speaker = peripheral.find("speaker")

local CHUNK_SIZE = 512
local SAMPLE_RATE = 48000  -- Новый: фиксированный sample rate для speaker в CC:Tweaked
local SAMPLES_PER_BYTE = 8  -- Новый: для DFPWM

local sortedCache = {}
local trackButtons = {}
local artistS = {}

if not fs.exists("sbin/MPlayer/Data/cache") then
    local file = fs.open("sbin/MPlayer/Data/cache","w")
    file.write("return {}")
    file.close()
end
local cache = require("sbin/MPlayer/Data/cache")
local confPath = "sbin/MPlayer/Data/player.conf"
if not fs.exists(confPath) then
    local file = fs.open(confPath,"w")
    file.write("play_next=true\nvolume=1")
    file.close()
end
local conf = c.readConf(confPath)
local played = {}
local Path = "home/Music/"

local volumes = {0, 0.05, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3}
local def = 1
for i, v in pairs(volumes) do
    if conf["volume"] == v then def = i break end
end
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "MPlayer")

local btnAll = UI.New_Button(1, 1, 3, 1, "All", _, colors.white, colors.black)
window:addChild(btnAll)

local btnAlbum = UI.New_Button(btnAll.x + btnAll.w + 1, 1, 5, 1, "Album", _, colors.white, colors.lightGray)
surface:addChild(btnAlbum)

local boxAll = UI.New_ScrollBox(1, 1, surface.w - 1, surface.h - 5, colors.black)
surface:addChild(boxAll)

local scrollbar = UI.New_Scrollbar(boxAll)
surface:addChild(scrollbar)
--[[
local boxAlbum = UI.New_Box(root)
boxAlbum.reSize = function(self)
    self.pos = {x = self.parent.pos.x, y = self.parent.pos.y+1}
    self.size = {w = self.parent.size.w - self.pos.x, h = self.parent.size.h - self.pos.y + 1 - 5}
end

local scrollboxAlbum = UI.New_ScrollBox(root)
scrollboxAlbum.draw = function(self)
    c.drawFilledBox(1,1,self.size.w,self.size.h,self.bg)
    for i=1,self.size.h do
        c.write("|",1,i,self.bg,self.txtcol)
    end
end
scrollboxAlbum.reSize = function(self)
    self.pos = {x = self.parent.pos.x+15, y = self.parent.pos.y}
    self.size = {w = self.parent.size.w - self.pos.x+1, h = self.parent.size.h}
    self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
    self.win.redraw()
end
boxAlbum:addChild(scrollboxAlbum)

local scrollArtist = UI.New_ScrollBox(root)
scrollArtist.reSize = function(self)
    self.pos.y = 2
    self.size = {w = scrollboxAlbum.pos.x-1, h = self.parent.size.h}
    self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
    self.win.redraw()
end
boxAlbum:addChild(scrollArtist)

local IMG = UI.New_Label(root,_,colors.white,colors.white)
IMG.reSize = function(self)
    self.pos = {x = self.parent.pos.x+2, y = self.parent.pos.y+1}
    self.size = {w=9,h=5}
end
scrollboxAlbum:addChild(IMG)

local AlbumName = UI.New_Label(root,"Album Name",colors.black,colors.white,"left")
AlbumName.reSize = function(self)
    self.pos = {x = IMG.pos.x+IMG.size.w+1, y = IMG.pos.y+2}
    self.size.w = 15
end
scrollboxAlbum:addChild(AlbumName)

local AlbumArtistName = UI.New_Label(root,"Artist Name",colors.black,colors.lightGray,"left")
AlbumArtistName.reSize = function(self)
    self.pos = {x = AlbumName.pos.x, y = AlbumName.pos.y+1}
    self.size.w = 15
end
scrollboxAlbum:addChild(AlbumArtistName)

local numCompose = UI.New_Label(root,"5 - Tracks",colors.black,colors.lightGray,"left")
numCompose.reSize = function(self)
    self.pos = {x = AlbumArtistName.pos.x, y = AlbumArtistName.pos.y+1}
    self.size.w = 15
end
scrollboxAlbum:addChild(numCompose)
]]

local box2 = UI.New_Box(1, surface.h - 4, surface.w, 5, colors.gray)
box2.draw = function (self)
    c.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.color_bg)
    blittle.draw(blittle.load("sbin/MPlayer/Data/MusicAlbum.ico"), self.x + 1, self.y)
end
surface:addChild(box2)

local btnVolume = UI.New_Button(surface.w - 13, 2, 3, 1, "", _, box2.color_bg, colors.white)
btnVolume.PrevStatus = 1
btnVolume.draw = function (self)
    c.write(string_char(145), self.x, self.y, self.color_txt, self.parent.color_bg)
    if conf["volume"] ~= 0 then
        c.write(string_char(157), self.x + 1, self.y, self.color_txt, self.color_bg)
        c.write(string_char(132), self.x + 2, self.y, self.color_bg, self.color_txt)
    else
        c.write("x ", self.pos.x + 1, self.y, self.parent.color_bg, self.color_txt)
    end
end
box2:addChild(btnVolume)

local pause = UI.New_Button(math_floor((box2.w - 2) / 2) + 1, 2, 2, 1, "|"..string_char(16), _, box2.color_bg, colors.white)
pause.play = false
pause.draw = function(self)
    local color_bg, color_txt, text = self.parent.color_bg, self.color_txt, "|"..string_char(16)
    if self.play then text = "||" end
    if self.held then
        color_txt = self.color_bg
        color_bg = self.color_txt
    end
    c.write(text, self.x, self.y, color_bg, color_txt)
end
box2:addChild(pause)

local btnNext = UI.New_Button(pause.x + pause.w + 1, pause.y, 2, 1, string_char(16).."|", _, box2.color_bg, colors.white)
box2:addChild(btnNext)

local btnPrev = UI.New_Button(pause.x - 3, pause.y, 2, 1, "|"..string_char(17), _, box2.color_bg, colors.white)
box2:addChild(btnPrev)

local btnOptionAutoNext = UI.New_Button(btnNext.x + btnNext.w + 1, btnNext.y, 1, 1, " ", _, box2.color_bg, colors.white)
box2:addChild(btnOptionAutoNext)

local ArtistName = UI.New_Running_Label(surface.w > 41 and 10 or 2, 2, 7, 1, "Unknown", "left", _, _, box2.color_bg, colors.lightGray)
-- ArtistName.reSize = function(self)
--     self.pos.x = self.root.size.w > 41 and 10 or 2
--     self.pos.y = self.parent.pos.y + 1
--     self.size.w = btnPrev.pos.x-self.pos.x-1
-- end
box2:addChild(ArtistName)

local trackName = UI.New_Running_Label(ArtistName.x, ArtistName.y + 1, ArtistName.w, 1, "Unknown", "left", _, _, box2.color_bg, colors.lightGray)
box2:addChild(trackName)

local volumeSlider = UI.New_Slider(box2.w - 10, 2, 10, volumes, def, colors.lightGray, box2.color_bg, colors.white)
box2:addChild(volumeSlider)

local timeLine = UI.New_Slider(surface.w > 41 and 16 or 8, surface.h - 2, 10, {}, 1, colors.white, box2.color_bg, colors.lightGray)
-- root.timeLine.reSize = function(self)
--     self.pos.x = self.root.size.w > 41 and 16 or 8
--     self.pos.y = self.parent.size.h + self.parent.pos.y - 2
--     self.size.w = self.parent.size.w - self.pos.x - 2 - 10
--     self.size.w = self.root.size.w > 41 and self.parent.size.w - self.pos.x - 12 or self.parent.size.w- self.pos.x - 6
-- end
box2:addChild(timeLine)

local currentTimeLabel = UI.New_Label(surface.w > 41 and 10 or 2, surface.h - 2, 5, 1, "00:00", _, box2.color_bg, colors.lightGray, "right")
box2:addChild(currentTimeLabel)

local totalTimeLabel = UI.New_Label(surface.w - 11, surface.h - 2, 5, 1, "00:00", _, box2.color_bg, colors.lightGray)
-- totalTimeLabel.reSize = function(self)
--     self.size.w = 5
--     self.pos.x = self.root.size.w > 41 and self.parent.size.w - self.size.w-6 or self.parent.size.w - self.size.w
--     self.pos.y = root.timeLine.pos.y
-- end
box2:addChild(totalTimeLabel)
--[[
local btnVolumeUp = UI.New_Button(root,string_char(30),colors.gray,colors.white)
btnVolumeUp.reSize = function (self)
    self.pos = {x=self.parent.size.w-1,y=self.parent.pos.y}
end

local volumeLabel = UI.New_Label(root,tostring(def),colors.gray,_,"right")
volumeLabel.reSize = function (self)
    self.pos = {x=self.parent.size.w-2,y=self.parent.pos.y+1}
    self.size.w = 2
end

local btnVolumeDown = UI.New_Button(root,string_char(31),colors.gray,colors.white)
btnVolumeDown.reSize = function (self)
    self.pos = {x=self.parent.size.w-1,y=self.parent.pos.y+2}
end
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function adaptive()
    if root.size.w <= 41 then
        box2:removeChild(btnVolume)
        box2:removeChild(volumeSlider)
        box2:addChild(btnVolumeUp)
        box2:addChild(btnVolumeDown)
        box2:addChild(volumeLabel)
    elseif root.size.w > 41 then
        box2:addChild(btnVolume)
        box2:addChild(volumeSlider)
        box2:removeChild(btnVolumeUp)
        box2:removeChild(btnVolumeDown)
        box2:removeChild(volumeLabel)
    end
end
adaptive()

local function getConf()
    local val = ""
    if conf["play_next"] then
        val = string_char(167)
    else
        val = string_char(173)
    end
    return val
end
btnOptionAutoNext:setText(getConf())

local function getTotalSeconds(path)
    local size = fs.getSize(path)
    return size * SAMPLES_PER_BYTE / SAMPLE_RATE
end

local function format_time(sec)
    sec = math_floor(sec)
    local min = math_floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", min, s)
end

local function cacheUpdate()
    local arr = fs.list(Path)
    local onDiskFiles = {} -- Создаем "сет" (таблицу-множество) для быстрой проверки
    for _, v in pairs(arr) do
        onDiskFiles[v] = true
    end

    local newFiles = {}
    local cacheModified = false -- Флаг, отслеживающий изменения

    -- 0. Убедимся, что кеш - это таблица
    if type(cache) ~= "table" then
        cache = {}
        cacheModified = true -- Кеш был пуст, его нужно будет создать
    end

    -- 1. Ищем новые файлы (есть на диске, нет в кеше)
    for _, v in pairs(arr) do
        if not cache[v] then
            table_insert(newFiles, v)
            cacheModified = true -- Нашли новый файл, кеш нужно обновить
        end
    end

    -- 2. Ищем удаленные файлы (есть в кеше, нет на диске)
    local removedFiles = {}
    for filename, _ in pairs(cache) do
        if not onDiskFiles[filename] then
            table_insert(removedFiles, filename)
            cacheModified = true -- Нашли удаленный файл, кеш нужно обновить
        end
    end
    -- Удаляем их из кеша
    for _, filename in pairs(removedFiles) do
        cache[filename] = nil
    end

    -- 3. Обрабатываем *только* новые файлы
    if #newFiles > 0 then
        for _, v in pairs(newFiles) do
            local handle = io.open(Path .. v, "rb")
            if not handle then
                print("Warning: Could not open " .. v .. " to cache.")
                goto continue -- Пропускаем этот файл, если не можем открыть
            end

            local metadata = {}
            local _, fileSize = pcall(function() return handle:seek("end") end)
            fileSize = tonumber(fileSize) or 0
            local total_sec = getTotalSeconds(Path .. v)
            total_sec = format_time(total_sec)

            local tailRead = math_min(8192, fileSize)
            local tail = ""
            if tailRead > 0 then
                -- Обернем в pcall на случай ошибки доступа
                pcall(function() handle:seek("set", math_max(0, fileSize - tailRead)) end)
                tail = handle:read(tailRead) or ""
            end

            local meta_start, meta_end = nil, nil
            if tail and #tail > 0 then
                local marker = "--METADATA--"
                local s = string_find(tail, marker, 1, true)
                if s then
                    meta_start = (fileSize - #tail) + s
                    local e_marker = "--ENDMETADATA--"
                    local e = string_find(tail, e_marker, s + #marker, true)
                    if e then
                        meta_end = (fileSize - #tail) + e + #e_marker - 1
                    end
                end
            end

            if meta_start and meta_end and meta_end > meta_start then
                pcall(function() handle:seek("set", meta_start + #"--METADATA--") end)
                local meta_len = meta_end - meta_start - #"--METADATA--"
                local meta_block = handle:read(meta_len) or ""

                local function trim(s)
                    if not s then return "" end
                    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
                end
                for ln in string_gmatch(meta_block, "([^\r\n]+)") do
                    local k, v = ln:match("^%s*(%a+):%s*(.*)")
                    if k and v then
                        k = string_lower(k)
                        if k == "title" or k == "artist" or k == "album" then
                            metadata[k] = trim(v)
                        end
                    end
                end
                metadata["meta_start"] = meta_start
            end
            metadata["time"] = total_sec
            handle:close()

            if not metadata["artist"] or metadata["artist"] == "" then metadata["artist"] = "Unknown" end
            if not metadata["title"] or metadata["title"] == "" then metadata["title"] = "Unknown" end
            if not metadata["album"] or metadata["album"] == "" then metadata["album"] = "Unknown" end

            cache[v] = metadata -- Добавляем новый файл в нашу таблицу кеша

            ::continue:: -- Метка для goto
        end
    end

    -- 4. Если были изменения (новые ИЛИ удаленные файлы), перезаписываем файл кеша
    if cacheModified then
        local cacheFile, err = fs.open("sbin/MPlayer/Data/cache", "w")
        if not cacheFile then
            print(err)
            return
        end
        cacheFile.write("return " .. textutils.serialise(cache))
        cacheFile.close()

        -- 5. Перезагружаем модуль кеша, чтобы программа использовала актуальные данные
        package.loaded["sbin/MPlayer/Data/cache"] = nil
        cache = require("sbin/MPlayer/Data/cache")
    end
end
cacheUpdate()

-- Очищаем старый sortedCache и заполняем его актуальными данными из обновленного кеша
sortedCache = {}
artistS = {}
for k,v in pairs(cache) do
    table_insert(sortedCache, k)
    table_insert(artistS, v.artist)
end
table_sort(sortedCache)
table_sort(artistS)

local function getTotalChunks(path)
    local size = fs.getSize(path)
    return math.ceil(size / CHUNK_SIZE)
end

local function checkSpeaker()
    if bOS.speaker then return true end
    if peripheral.find("speaker") then
        bOS.speaker = peripheral.find("speaker")
        return true
    end
    local speakerWin = UI.New_MsgWin(root,"INFO")
    speakerWin:callWin(" INFO ","Speaker not found. Please, put speaker near computer.")
    return false
end

local volume = conf["volume"]
local function runMusic(path, start_chunk)
    --textutils.slowPrint(path) os.sleep(1)
    if not checkSpeaker() then return end
    start_chunk = start_chunk or 1
    local temp = path:match("([^/\\]+)$")

    -- Update UI labels with parsed metadata (if available)

    ArtistName:setText(cache[temp].artist)
    local Title = cache[temp].title
    if Title ~= "Unknown" then
        trackName:setText(Title)
    else
        trackName:setText(temp)
    end

    -- Prepare coroutine to stream only the audio bytes (exclude appended metadata)
    root.coroutine[1] = coroutine_create(function()
        -- Re-open handle in coroutine scope to ensure proper position handling
        local h = io.open(path, "rb")
        if not h then error("Failed to open file: " .. path) end
        local ok, fileSize = pcall(function() return h:seek("end") end)
        fileSize = tonumber(fileSize) or 0

        -- compute data end position (if metadata present, stop before it)
        local data_end = fileSize
        if cache[temp].meta_start then
            data_end = cache[temp].meta_start - 1
        end

        -- Seek to requested start_chunk
        if start_chunk > 1 then
            local start_pos = (start_chunk - 1) * CHUNK_SIZE
            if start_pos < data_end then
                h:seek("set", start_pos)
            else
                -- start beyond data; nothing to play
                h:close()
                return
            end
        else
            h:seek("set", 0)
        end

        local decoder = dfpwm.make_decoder()
        local current_chunk = start_chunk

        while true do
            local cur_pos = h:seek("cur") or 0
            if cur_pos >= data_end then break end
            local to_read = math_min(CHUNK_SIZE, data_end - cur_pos)
            if to_read <= 0 then break end
            local chunk = h:read(to_read)
            if not chunk then break end
            local buffer = decoder(chunk)
            while not bOS.speaker.playAudio(buffer, volume) do
                os.pullEvent("speaker_audio_empty")
            end
            coroutine_yield(current_chunk)
            current_chunk = current_chunk + 1
        end
        h:close()
    end)
end

local function startTrack(filename, isTogglePause)
    if not checkSpeaker() then return false end
    local full_path = Path .. filename

    if isTogglePause then
        pause.play = not pause.play
        pause.dirty = true
        root.coroutine[2] = not root.coroutine[2]
        return
    end

    if played[2] then
        played[2].play = false
        played[2].dirty = true
    end
    if root.coroutine[1] then root.coroutine = {} end

    local total_chunks = getTotalChunks(full_path)
    root.timeLine.arr = {}
    for i = 1, total_chunks do
        root.timeLine.arr[i] = i
    end
    root.timeLine.slidePosition = 1
    root.timeLine.dirty = true
    root.seek_to = nil

    totalTimeLabel:setText(cache[filename].time)

    played[1] = filename
    ArtistName:setText(cache[filename].artist or "Unknown")
    trackName:setText(cache[filename].title or filename)

    pause.play = true
    pause.dirty = true

    runMusic(full_path)
    return true
end

for i,v in pairs(sortedCache) do
    local trackPlay = UI.New_Button(root,string_char(16),colors.black,colors.white)
    trackPlay.play = false
    trackPlay.draw = function(self)
        local bg, txtcol, text = self.parent.bg, self.txtcol, string_char(16)
        if self.play then text = string_char(15) end
        if self.held then
            c.write(" "..text.." ", self.pos.x, self.pos.y, txtcol, bg)
        else
            c.write(" "..text.." ", self.pos.x, self.pos.y, bg, txtcol)
        end
    end
    trackPlay.reSize = function(self)
        self.pos = {x = self.parent.pos.x, y = self.parent.pos.y + i-self.parent.scrollpos+1}
        self.size.w = 3
    end
    boxAll:addChild(trackPlay)
    table_insert(trackButtons, trackPlay)
    local trackLabel = UI.New_Label(root,v,colors.black,colors.white,"left")
    trackLabel.reSize = function(self)
        self.pos = {x = trackPlay.pos.x + trackPlay.size.w, y = trackPlay.pos.y}
        self.size.w = self.parent.size.w - self.pos.x - 6
    end
    boxAll:addChild(trackLabel)
    local trackTime = UI.New_Label(root,cache[v].time,colors.black,colors.lightGray,"left")
    trackTime.reSize = function(self)
        self.size.w = 5
        self.pos = {x = self.parent.size.w-self.size.w, y = self.parent.pos.y + i-self.parent.scrollpos+1}
    end
    boxAll:addChild(trackTime)
    trackPlay.pressed = function(self)
        if not startTrack(v,false) then return end
        self.play = true
        played[2] = self
        played[3] = i
    end
end

for i,v in pairs(artistS) do
    local buttonArtist = UI.New_Button(root,v,_,_,"left")
    buttonArtist.reSize = function(self)
        self.pos.y = i+2
        self.size.w = self.parent.size.w
    end
    scrollArtist:addChild(buttonArtist)
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
btnAll.pressed = function(self)
    if surface:removeChild(boxAlbum) then
        btnAlbum.txtcol = colors.lightGray
        self.txtcol = colors.black
        surface:addChild(boxAll)
        boxAll:onLayout()
        scrollbar:setObj(boxAll)
    end
end

btnAlbum.pressed = function(self)
    if surface:removeChild(boxAll) then
        btnAll.txtcol = colors.lightGray
        self.txtcol = colors.black
        surface:addChild(boxAlbum)
        boxAlbum:onLayout()
        scrollbar:setObj(scrollboxAlbum)
    end
end

btnClose.pressed = function(self)
    self.root.running_program = false
end

pause.pressed = function(self)
    if not played[1] then return end
    startTrack(played[1], true)
end

btnNext.pressed = function(self)
    if not played[1] or #sortedCache == 0 then return end

    local current_index = played[3] or 1
    local next_index = current_index + 1
    if next_index > #sortedCache then
        next_index = 1
    end
    played[3] = next_index
    played[1] = sortedCache[next_index]

    startTrack(played[1], false)
]]
--     if trackButtons[played[3]] then
--         trackButtons[played[3]].play = true
--         trackButtons[played[3]].dirty = true
--         played[2] = trackButtons[played[3]]
--     end
-- end

-- btnPrev.pressed = function(self)
--     if not played[1] or #sortedCache == 0 then return end

--     local current_index = played[3] or 1
--     local prev_index = current_index - 1
--     if prev_index < 1 then
--         prev_index = #sortedCache
--     end
--     played[3] = prev_index
--     played[1] = sortedCache[prev_index]

--     startTrack(played[1], false)

--     if trackButtons[played[3]] then
--         trackButtons[played[3]].play = true
--         trackButtons[played[3]].dirty = true
--         played[2] = trackButtons[played[3]]
--     end
-- end
--[[
local temp_onEvent = pause.onEvent
pause.onEvent = function(self,evt)
    if evt[1] == "pause_music" then
        self.play = false
        self:setText("|"..string_char(16))
        return true
    elseif evt[1] == "play_next" then
        btnNext:pressed()
        return true
    end
    temp_onEvent(self,evt)
end

volumeSlider.pressed = function(self,btn, x, y)
    volume = self.arr[self.slidePosition]
    conf["volume"] = volume
    c.saveConf(confPath, conf)
    btnVolume.dirty = true
    volumeLabel:setText(tostring(self.slidePosition))
end

btnVolume.pressed = function(self)
    if conf["volume"] == 0 then
        conf["volume"] = self.PrevStatus
        for i, v in pairs(volumes) do
            if v == conf["volume"] then
                volumeSlider.slidePosition = i
                break
            end
            volume = self.PrevStatus
        end
    else
        self.PrevStatus = conf["volume"]
        conf["volume"] = 0
        volume = 0
        volumeSlider.slidePosition = 1
    end
    c.saveConf(confPath, conf)
    self.dirty = true
    volumeSlider.dirty = true
end

btnOptionAutoNext.pressed = function(self)
    if conf["play_next"] == true then
        conf["play_next"] = false
        self:setText(string_char(173))
    else
        conf["play_next"] = true
        self:setText(string_char(167))
    end
    c.saveConf(confPath, conf)
end

btnVolumeUp.pressed = function (self)
    local temp = math_min(tonumber(volumeLabel.text)+1,10)
    volume = volumes[temp]
    conf["volume"] = volume
    c.saveConf(confPath, conf)
    volumeLabel:setText(tostring(temp))
    volumeSlider.slidePosition = temp
end

btnVolumeDown.pressed = function (self)
    local temp = math_max(tonumber(volumeLabel.text)-1,1)
    volume = volumes[temp]
    conf["volume"] = volume
    c.saveConf(confPath, conf)
    volumeLabel:setText(tostring(temp))
    volumeSlider.slidePosition = temp
end

root.timeLine.pressed = function(self,btn, x, y)
    if btn == 1 and played[1] then
        local new_pos = math_max(1, math_min(#self.arr, math_floor((x - self.pos.x) / self.size.w * #self.arr) + 1))
        self.slidePosition = new_pos
        self.root.seek_to = new_pos
        self.dirty = true
        -- Новый: обновить current_time при seek (для мгновенного отображения)
        local time_per_chunk = CHUNK_SIZE * SAMPLES_PER_BYTE / SAMPLE_RATE
        local current_sec = (new_pos - 1) * time_per_chunk
        currentTimeLabel:setText(format_time(current_sec))
    end
end

local function resume_coroutine(co, ...)
    local success, result = coroutine_resume(co, ...)
    if success and result and type(result) == "string" then
        root.expected_event = result
        return true, nil
    end
    return success, result
end
root.tResize = function (self)
    c.termClear(self.bg)
    self.size.w, self.size.h = term.getSize()
    adaptive()
    self:onLayout()
end

root.mainloop = function(self)
    self:show()
    while self.running_program do
        if self.seek_to then
            local full_path = Path .. played[1]
            self.coroutine = {}
            self.expected_event = nil
            runMusic(full_path, self.seek_to)
            self.seek_to = nil
            pause.play = true
            pause:setText("||")
            pause.dirty = true
            -- Новый: обновить current_time после seek
            local time_per_chunk = CHUNK_SIZE * SAMPLES_PER_BYTE / SAMPLE_RATE
            local current_sec = (self.timeLine.slidePosition - 1) * time_per_chunk
            currentTimeLabel:setText(format_time(current_sec))
        end

        if self.coroutine[1] and not self.coroutine[2] and coroutine_status(self.coroutine[1]) == "suspended" and not self.expected_event then
            local success, current_chunk = resume_coroutine(self.coroutine[1])
            if success then
                if current_chunk then
                    self.timeLine.slidePosition = current_chunk
                    self.timeLine.dirty = true
                    -- Новый: обновить current_time
                    local time_per_chunk = CHUNK_SIZE * SAMPLES_PER_BYTE / SAMPLE_RATE
                    local current_sec = (current_chunk - 1) * time_per_chunk
                    currentTimeLabel:setText(format_time(current_sec))
                end
            else
                local infoWin = UI.New_MsgWin(root, "ERROR")
                infoWin:callWin(" Coroutine error ", tostring(current_chunk))
                self.coroutine = {}
                self.expected_event = nil
            end
            if coroutine_status(self.coroutine[1]) == "dead" then
                self.coroutine = {}
                self.expected_event = nil
                if conf["play_next"] then
                    os.queueEvent("play_next")
                else
                    os.queueEvent("pause_music")
                end
            end
        end

        local evt = {os.pullEventRaw()}

        local event_used = false
        if self.coroutine[1] and self.expected_event and evt[1] == self.expected_event then
            local success, current_chunk = resume_coroutine(self.coroutine[1], table_unpack(evt))
            self.expected_event = nil
            event_used = true
            if success then
                if current_chunk then
                    self.timeLine.slidePosition = current_chunk
                    self.timeLine.dirty = true
                    -- Новый: обновить current_time
                    local time_per_chunk = CHUNK_SIZE * SAMPLES_PER_BYTE / SAMPLE_RATE
                    local current_sec = (current_chunk - 1) * time_per_chunk
                    currentTimeLabel:setText(format_time(current_sec))
                end
            else
                local infoWin = UI.New_MsgWin(root, "ERROR")
                infoWin:callWin(" Coroutine error ", tostring(current_chunk))
                self.coroutine = {}
            end
            if coroutine_status(self.coroutine[1]) == "dead" then
                self.coroutine = {}
                os.queueEvent("pause_music")
            end
        end

        if not event_used then
                if evt[1] == "terminate" then
                    c.termClear(self.bg)
                    self.running_program = false
                end
                self:onEvent(evt)
                --dbg.print(textutils.serialise(evt))
            end
        self:redraw()
    end
    c.termClear()
end]]
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
-----------------------------------------------------
surface:onLayout()