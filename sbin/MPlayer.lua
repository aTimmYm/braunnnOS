-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local dfpwm = require("cc.audio.dfpwm")
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
if bOS.shell or bOS.Explorer then return end
root.coroutine = {}
root.seek_to = nil
root.expected_event = nil

local CHUNK_SIZE = 512
local SAMPLE_RATE = 48000  -- Новый: фиксированный sample rate для speaker в CC:Tweaked
local SAMPLES_PER_BYTE = 8  -- Новый: для DFPWM

local sortedCache = {}
local trackButtons = {}
local artistS = {}

if not fs.exists("sbin/MPlayer_Data/cache") then
    local file = fs.open("sbin/MPlayer_Data/cache","w")
    file.write("return {}")
    file.close()
end
local cache = require("sbin/MPlayer_Data/cache")
local confPath = "sbin/MPlayer_Data/player.conf"
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
local surface = UI.New_Box(root, colors.white)
root:addChild(surface)

local btnAll = UI.New_Button(root, "All", colors.white,colors.black)
surface:addChild(btnAll)

local btnAlbum = UI.New_Button(root, "Album", colors.white,colors.lightGray)
btnAlbum.reSize = function(self)
    self.pos.x = btnAll.pos.x + btnAll.size.w + 1
end
surface:addChild(btnAlbum)

local label = UI.New_Label(root, "MPlayer", colors.white, colors.black)
label.reSize = function(self)
    self.size.w = #self.text
    self.pos.x = math.floor((self.parent.size.w-self.size.w)/2)
end
surface:addChild(label)

local btnClose = UI.New_Button(root, "x", colors.white, colors.black)
btnClose.reSize = function(self)
    self.pos.x = self.parent.size.w
end
surface:addChild(btnClose)

local boxAll = UI.New_ScrollBox(root, colors.black)
boxAll.reSize = function(self)
    self.pos = {x = self.parent.pos.x, y = self.parent.pos.y+1}
    self.size = {w = self.parent.size.w - self.pos.x, h = self.parent.size.h - self.pos.y + 1 - 5}
    self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
    self.win.redraw()
end
surface:addChild(boxAll)

local scrollbar = UI.New_Scrollbar(boxAll)
scrollbar.reSize = function(self)
    self.pos = {x = self.obj.pos.x + self.obj.size.w, y = self.obj.pos.y}
    self.size.h = self.obj.size.h
end
surface:addChild(scrollbar)

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

local box2 = UI.New_Box(root, colors.gray)
box2.draw = function(self)
    c.drawFilledBox(self.pos.x, self.pos.y, self.size.w + self.pos.x - 1, self.size.h + self.pos.y - 1, self.bg)
    blittle.draw(blittle.load("sbin/MPlayer_Data/MusicAlbum.ico"), self.pos.x+1, self.pos.y)
    blittle.draw(blittle.load("sbin/MPlayer_Data/volume.ico"), self.size.w-13, self.pos.y+1)
end
box2.reSize = function(self)
    self.pos = {x = 1, y = self.parent.size.h - 4}
    self.size = {w = self.parent.size.w, h = 5}
end
surface:addChild(box2)

local btnVolume = UI.New_Button(root, "")
btnVolume.PrevStatus = 1
btnVolume.reSize = function(self)
    self.pos.x = self.parent.size.w - 13
    self.pos.y = self.parent.pos.y + 1
    self.size.w = 3
end
btnVolume.draw = function(self)
    c.write(string.char(145), self.pos.x, self.pos.y, self.txtcol, self.parent.bg)
    if conf["volume"] ~= 0 then
        c.write(string.char(157), self.pos.x+1, self.pos.y, self.txtcol, self.parent.bg)
        c.write(string.char(132), self.pos.x+2, self.pos.y, self.parent.bg, self.txtcol)
    else
        c.write("x ",self.pos.x+1, self.pos.y, self.parent.bg, self.txtcol)
    end
end
box2:addChild(btnVolume)

local ArtistName = UI.New_Running_Label(root, "Unknown", colors.gray, colors.lightGray, "top left")
ArtistName.reSize = function(self)
    self.pos.x = self.parent.pos.x + 9
    self.pos.y = self.parent.pos.y + 1
    self.size.w = math.floor(self.parent.size.w*0.23)
end
box2:addChild(ArtistName)

local trackName = UI.New_Running_Label(root, "Unknown", colors.gray, colors.lightGray, "top left", _, "   ")
trackName.reSize = function(self)
    self.pos.x = ArtistName.pos.x
    self.pos.y = ArtistName.pos.y + 1
    self.size.w = ArtistName.size.w
    self.size.h = 1
end
box2:addChild(trackName)

local btnNext = UI.New_Button(root, string.char(16).."|", colors.gray, colors.white)
btnNext.reSize = function(self)
    self.pos.x = math.floor((self.parent.size.w + self.size.w) / 2) - 1 + self.size.w + 1
    self.pos.y = self.parent.pos.y + 1
end
box2:addChild(btnNext)

local pause = UI.New_Button(root, "|"..string.char(16), colors.gray, colors.white)
pause.play = false
pause.draw = function(self)
    local bg, txtcol, text = self.parent.bg, self.txtcol, "|"..string.char(16)
    if self.play then text = "||" end
    if self.held then
        c.write(text, self.pos.x, self.pos.y, txtcol, bg)
    else
        c.write(text, self.pos.x, self.pos.y, bg, txtcol)
    end
end
pause.reSize = function(self)
    self.pos.x = math.floor((self.parent.size.w + self.size.w) / 2) - 1
    self.pos.y = self.parent.pos.y + 1
end
local temp_onEvent = pause.onEvent
pause.onEvent = function(self,evt)
    temp_onEvent(self,evt)
    if evt[1] == "pause_music" then
        self.play = false
        self:setText("|"..string.char(16))
    elseif evt[1] == "play_next" then
        btnNext:pressed()
    end
end
box2:addChild(pause)

local btnPrev = UI.New_Button(root, "|"..string.char(17), colors.gray, colors.white)
btnPrev.reSize = function(self)
    self.pos.x = pause.pos.x - self.size.w - 1
    self.pos.y = pause.pos.y
end
box2:addChild(btnPrev)

local volumeSlider = UI.New_Slider(root, volumes, colors.gray, colors.white, def, colors.lightGray)
volumeSlider.reSize = function(self)
    self.size.w = #self.arr
    self.pos.x = self.parent.size.w - self.size.w
    self.pos.y = btnNext.pos.y
end
box2:addChild(volumeSlider)

root.timeLine = UI.New_Slider(root, {}, colors.gray, colors.white, 1, colors.lightGray)
root.timeLine.reSize = function(self)
    self.pos.x = self.parent.pos.x + 15
    self.pos.y = self.parent.size.h + self.parent.pos.y - 2
    self.size.w = self.parent.size.w - self.pos.x - 2 - 10
end
box2:addChild(root.timeLine)

local currentTimeLabel = UI.New_Label(root, "00:00", colors.gray, colors.lightGray, "right")
currentTimeLabel.reSize = function(self)
    self.size.w = 5
    self.pos.x = root.timeLine.pos.x - self.size.w - 1
    self.pos.y = root.timeLine.pos.y
end
box2:addChild(currentTimeLabel)

local totalTimeLabel = UI.New_Label(root, "00:00", colors.gray, colors.lightGray, "left")
totalTimeLabel.reSize = function(self)
    self.pos.x = root.timeLine.pos.x + root.timeLine.size.w + 1
    self.pos.y = root.timeLine.pos.y
    self.size.w = 5
end
box2:addChild(totalTimeLabel)

local btnOptionAutoNext = UI.New_Button(root, " ", colors.gray, colors.white)
btnOptionAutoNext.reSize = function(self)
    self.pos.x = math.floor((self.parent.size.w + self.size.w) / 2) + self.size.w + 4
    self.pos.y = self.parent.pos.y + 1
end
box2:addChild(btnOptionAutoNext)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function getConf()
    local val = ""
    if conf["play_next"] then
        val = string.char(167)
    else
        val = string.char(173)
    end
    return val
end
btnOptionAutoNext:setText(getConf())

local function getTotalSeconds(path)
    local size = fs.getSize(path)
    return size * SAMPLES_PER_BYTE / SAMPLE_RATE
end

local function format_time(sec)
    sec = math.floor(sec)
    local min = math.floor(sec / 60)
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
            table.insert(newFiles, v)
            cacheModified = true -- Нашли новый файл, кеш нужно обновить
        end
    end

    -- 2. Ищем удаленные файлы (есть в кеше, нет на диске)
    local removedFiles = {}
    for filename, _ in pairs(cache) do
        if not onDiskFiles[filename] then
            table.insert(removedFiles, filename)
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

            local tailRead = math.min(8192, fileSize)
            local tail = ""
            if tailRead > 0 then
                -- Обернем в pcall на случай ошибки доступа
                pcall(function() handle:seek("set", math.max(0, fileSize - tailRead)) end)
                tail = handle:read(tailRead) or ""
            end

            local meta_start, meta_end = nil, nil
            if tail and #tail > 0 then
                local marker = "--METADATA--"
                local s = string.find(tail, marker, 1, true)
                if s then
                    meta_start = (fileSize - #tail) + s
                    local e_marker = "--ENDMETADATA--"
                    local e = string.find(tail, e_marker, s + #marker, true)
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
                for ln in meta_block:gmatch("([^\r\n]+)") do
                    local k, v = ln:match("^%s*(%a+):%s*(.*)")
                    if k and v then
                        k = k:lower()
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
        local cacheFile, err = fs.open("sbin/MPlayer_Data/cache", "w")
        if not cacheFile then
            print(err)
            return
        end
        cacheFile.write("return " .. textutils.serialise(cache))
        cacheFile.close()

        -- 5. Перезагружаем модуль кеша, чтобы программа использовала актуальные данные
        package.loaded["sbin/MPlayer_Data/cache"] = nil
        cache = require("sbin/MPlayer_Data/cache")
    end
end
cacheUpdate()

-- Очищаем старый sortedCache и заполняем его актуальными данными из обновленного кеша
sortedCache = {}
artistS = {}
for k,v in pairs(cache) do
    table.insert(sortedCache, k)
    table.insert(artistS, v.artist)
end
table.sort(sortedCache)
table.sort(artistS)

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
    speakerWin:callWin(" INFO ","Speaker not found. Please, put speaker near computer or monitor.")
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
    root.coroutine[1] = coroutine.create(function()
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
            local to_read = math.min(CHUNK_SIZE, data_end - cur_pos)
            if to_read <= 0 then break end
            local chunk = h:read(to_read)
            if not chunk then break end
            local buffer = decoder(chunk)
            while not bOS.speaker.playAudio(buffer, volume) do
                os.pullEvent("speaker_audio_empty")
            end
            coroutine.yield(current_chunk)
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
    local trackPlay = UI.New_Button(root,string.char(16),colors.black,colors.white)
    trackPlay.play = false
    trackPlay.draw = function(self)
        local bg, txtcol, text = self.parent.bg, self.txtcol, string.char(16)
        if self.play then text = string.char(15) end
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
    table.insert(trackButtons, trackPlay)
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

    if trackButtons[played[3]] then
        trackButtons[played[3]].play = true
        trackButtons[played[3]].dirty = true
        played[2] = trackButtons[played[3]]
    end
end

btnPrev.pressed = function(self)
    if not played[1] or #sortedCache == 0 then return end

    local current_index = played[3] or 1
    local prev_index = current_index - 1
    if prev_index < 1 then
        prev_index = #sortedCache
    end
    played[3] = prev_index
    played[1] = sortedCache[prev_index]

    startTrack(played[1], false)

    if trackButtons[played[3]] then
        trackButtons[played[3]].play = true
        trackButtons[played[3]].dirty = true
        played[2] = trackButtons[played[3]]
    end
end

volumeSlider.pressed = function(self,btn, x, y)
    volume = self.arr[self.slidePosition]
    conf["volume"] = volume
    c.saveConf(confPath, conf)
    btnVolume.dirty = true
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
        self:setText(string.char(173))
    else
        conf["play_next"] = true
        self:setText(string.char(167))
    end
    c.saveConf(confPath, conf)
end

root.timeLine.pressed = function(self,btn, x, y)
    if btn == 1 and played[1] then
        local new_pos = math.max(1, math.min(#self.arr, math.floor((x - self.pos.x) / self.size.w * #self.arr) + 1))
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
    local success, result = coroutine.resume(co, ...)
    if success and result and type(result) == "string" then
        root.expected_event = result
        return true, nil
    end
    return success, result
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

        if self.coroutine[1] and not self.coroutine[2] and coroutine.status(self.coroutine[1]) == "suspended" and not self.expected_event then
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
            if coroutine.status(self.coroutine[1]) == "dead" then
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
            local success, current_chunk = resume_coroutine(self.coroutine[1], table.unpack(evt))
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
            if coroutine.status(self.coroutine[1]) == "dead" then
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
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------