------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_char = string.char
local string_find = string.find
local string_lower = string.lower
local string_gmatch = string.gmatch
local table_insert = table.insert
local table_sort = table.sort
local _max = math.max
local _min = math.min
local math_floor = math.floor
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
-- local screen = require("Screen")
local dfpwm = require "cc.audio.dfpwm"
local sys = require "syscalls"
local blittle = require "blittle_extended"
local c = require "cfunc"
local UI = require "ui2"
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
-- if bOS.shell or bOS.Explorer then return end

local function find_folder()
	local folder_path = "MPlayer"
	while true do
		local folders = fs.find(folder_path)
		if folders[1] ~= nil then
			return folders[1]
		end
		folder_path = "*/"..folder_path
		if #folder_path > 27 then error("FOLDER NOT FOUND") end
	end
end

local APP_PATH = find_folder()

local speaker
if periphemu then
	periphemu.create("right", "speaker"); speaker = peripheral.find("speaker")
end
-- bOS.speaker = peripheral.find("speaker")

local CHUNK_SIZE = 512
local SAMPLE_RATE = 48000  -- Новый: фиксированный sample rate для speaker в CC:Tweaked
local SAMPLES_PER_BYTE = 8 -- Новый: для DFPWM

local sortedCache = {}
local trackButtons = {}
local artistS = {}
local currentTrackIndex = 0
local speaker_play

if not fs.exists(APP_PATH.."/Data/cache") then
	local file = fs.open(APP_PATH.."/Data/cache", "w")
	file.write("return {}")
	file.close()
end
local cache = dofile(APP_PATH.."/Data/cache")
local confPath = APP_PATH.."/Data/player.conf"
if not fs.exists(confPath) then
	local file = fs.open(confPath, "w")
	file.write("play_next=true\nvolume=1")
	file.close()
end
local conf = c.readConf(confPath)
local Path = "home/Music/"
if not fs.exists(Path) then
	Path = APP_PATH.."/Music/"
	if not fs.exists(Path) then fs.makeDir(APP_PATH.."/Music") end
end

local volumes = { 0, 0.05, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3 }
local volume = conf["volume"]
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
sys.register_window("MPlayer", 1, 1, 51, 18, true)

local root = UI.Root()

-- local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.black,
	fc = colors.white,
})
root:addChild(surface)

-- local btnAll = UI.Button(1, 1, 3, 1, "All", _, colors.white, colors.black)
-- window:addChild(btnAll)

-- local btnAlbum = UI.Button(btnAll.x + btnAll.w + 1, 1, 5, 1, "Album", _, colors.white, colors.lightGray)
-- window:addChild(btnAlbum)

-- local boxAll = UI.ScrollBox(1, 1, surface.w - 1, surface.h - 5, colors.black)
local boxAll = UI.ScrollBox({
	x = 1, y = 1,
	w = surface.w - 1, h = surface.h - 5,
	bc = colors.black,
	fc = colors.white,
})
surface:addChild(boxAll)

local scrollbar = UI.Scrollbar(boxAll)
surface:addChild(scrollbar)
--[[
local boxAlbum = UI.Box(root)
boxAlbum.reSize = function (self)
	self.pos = {x = self.parent.pos.x, y = self.parent.pos.y+1}
	self.size = {w = self.parent.size.w - self.pos.x, h = self.parent.size.h - self.pos.y + 1 - 5}
end

local scrollboxAlbum = UI.ScrollBox(root)
scrollboxAlbum.draw = function (self)
	c.drawFilledBox(1,1,self.size.w,self.size.h,self.bg)
	for i=1,self.size.h do
		screen.write("|",1,i,self.bg,self.txtcol)
	end
end
scrollboxAlbum.reSize = function (self)
	self.pos = {x = self.parent.pos.x+15, y = self.parent.pos.y}
	self.size = {w = self.parent.size.w - self.pos.x+1, h = self.parent.size.h}
	self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
	self.win.redraw()
end
boxAlbum:addChild(scrollboxAlbum)

local scrollArtist = UI.ScrollBox(root)
scrollArtist.reSize = function (self)
	self.pos.y = 2
	self.size = {w = scrollboxAlbum.pos.x-1, h = self.parent.size.h}
	self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
	self.win.redraw()
end
boxAlbum:addChild(scrollArtist)

local IMG = UI.Label(root,_,colors.white,colors.white)
IMG.reSize = function (self)
	self.pos = {x = self.parent.pos.x+2, y = self.parent.pos.y+1}
	self.size = {w=9,h=5}
end
scrollboxAlbum:addChild(IMG)

local AlbumName = UI.Label(root,"Album Name",colors.black,colors.white,"left")
AlbumName.reSize = function (self)
	self.pos = {x = IMG.pos.x+IMG.size.w+1, y = IMG.pos.y+2}
	self.size.w = 15
end
scrollboxAlbum:addChild(AlbumName)

local AlbumArtistName = UI.Label(root,"Artist Name",colors.black,colors.lightGray,"left")
AlbumArtistName.reSize = function (self)
	self.pos = {x = AlbumName.pos.x, y = AlbumName.pos.y+1}
	self.size.w = 15
end
scrollboxAlbum:addChild(AlbumArtistName)

local numCompose = UI.Label(root,"5 - Tracks",colors.black,colors.lightGray,"left")
numCompose.reSize = function (self)
	self.pos = {x = AlbumArtistName.pos.x, y = AlbumArtistName.pos.y+1}
	self.size.w = 15
end
scrollboxAlbum:addChild(numCompose)
]]

-- local box2 = UI.Box(1, surface.h - 4, surface.w, 5, colors.gray)
local box2 = UI.Box({
	x = 1, y = surface.h - 4,
	w = surface.w, h = 5,
	bc = colors.gray,
	fc = colors.white
})
box2.ico = blittle.load(APP_PATH.."/Data/MusicAlbum.ico")
box2.draw = function(self)
	paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.bc)
	if surface.w > 41 then blittle.draw(self.ico, self.x + 1, self.y) end
end
surface:addChild(box2)

-- local currentTimeLabel = UI.Label(box2.w > 41 and 10 or 2, box2.h - 1, 5, 1, "00:00", _, box2.bc, colors.lightGray, "right")
local currentTimeLabel = UI.Label({
	x = (box2.w > 41) and 10 or 2, y = box2.h - 1,
	w = 5, h = 1,
	text = "00:00",
	bc = box2.bc,
	fc = colors.lightGray,
	align = "right"
})
box2:addChild(currentTimeLabel)

-- local pause = UI.Button(math_floor((box2.w - 2) / 2) + 1, 2, 2, 1, "|" .. "\16), _, _, box2.bc, colors.white)
local pause = UI.Button({
	x = math_floor((box2.w - 2) / 2) + 1, y = 2,
	w = 2, h = 1,
	text = "|" .. "\16",
	bc = box2.bc,
	fc = colors.white,
})
pause.play = false
pause.draw = function(self)
	local bc, fc, text = self.parent.bc, self.fc, "|" .. "\16"
	if self.play then text = "||" end
	if self.held then fc, bc = self.bc, self.fc end
	term.setBackgroundColor(bc)
	term.setTextColor(fc)
	term.setCursorPos(self.x, self.y)
	term.write(text)
	-- screen.write(text, self.x, self.y, bc, fc)
end
box2:addChild(pause)

-- local btnNext = UI.Button(pause.x + pause.w + 1, pause.y, 2, 1, "\16) .. "|", _, _, box2.bc, colors.white)
local btnNext = UI.Button({
	x = pause.x + pause.w + 1, y = pause.y,
	w = 2, h = 1,
	text = "\16" .. "|",
	bc = box2.bc,
	fc = colors.white
})
box2:addChild(btnNext)

-- local btnPrev = UI.Button(pause.x - 3, pause.y, 2, 1, "|" .. "\17), _, _, box2.bc, colors.white)
local btnPrev = UI.Button({
	x = pause.x - 3, y = pause.y,
	w = 2, h = 1,
	text = "|" .. "\17",
	bc = box2.bc,
	fc = colors.white
})
box2:addChild(btnPrev)

-- local btnOptionAutoNext = UI.Button(btnNext.x + btnNext.w + 1, btnNext.y, 1, 1, " ", _, _, box2.bc, colors.white)
local btnOptionAutoNext = UI.Button({
	x = btnNext.x + btnNext.w + 1, y = btnNext.y,
	w = 1, h = 1,
	text = " ",
	bc = box2.bc,
	fc = colors.white
})
box2:addChild(btnOptionAutoNext)

local AN_X = box2.w > 41 and 10 or 2
-- local ArtistName = UI.Running_Label(AN_X, 2, btnPrev.x - AN_X - 1, 1, "Unknown", "left", _, _, box2.bc, colors.lightGray)
local ArtistName = UI.Running_Label({
	x = AN_X, y = 2,
	w = btnPrev.x - AN_X - 1, h = 1,
	text = "Unknown",
	align = "left",
	bc = box2.bc,
	fc = colors.lightGray,
})
box2:addChild(ArtistName)

-- local trackName = UI.Running_Label(ArtistName.x, ArtistName.y + 1, ArtistName.w, 1, "Unknown", "left", _, _, box2.bc, colors.lightGray)
local trackName = UI.Running_Label({
	x = ArtistName.x, y = ArtistName.y + 1,
	w = ArtistName.w, h = 1,
	text = "Unknown",
	align = "left",
	bc = box2.bc,
	fc = colors.lightGray,
})
box2:addChild(trackName)

-- local totalTimeLabel = UI.Label(box2.w > 41 and box2.w - 11 or box2.w - 5, box2.h - 1, 5, 1, "00:00", _, box2.bc, colors.lightGray)
local totalTimeLabel = UI.Label({
	x = (box2.w > 41) and box2.w - 11 or box2.w - 5, y = box2.h - 1,
	w = 5, h = 1,
	text = "00:00",
	bc = box2.bc,
	fc = colors.lightGray,
})
box2:addChild(totalTimeLabel)

local TL_X = box2.w > 41 and 16 or 8
-- local timeLine = UI.Slider(TL_X, box2.h - 1, totalTimeLabel.local_x - TL_X - 1, {}, 1, colors.lightGray, box2.bc, colors.white)
local timeLine = UI.Slider({
	x = TL_X, y = box2.h - 1,
	w = totalTimeLabel.x - TL_X - 1,
	arr = {},
	fc_alt = colors.lightBlue,
	bc = box2.bc,
	fc = colors.white,
	fc_cl = colors.lightGray,
})
box2:addChild(timeLine)

local btnVolume, volumeSlider                 -- Для широкого режима
local btnVolumeUp, btnVolumeDown, volumeLabel -- Для компактного режима
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function format_time(sec)
	sec = math_floor(sec)
	local min = math_floor(sec / 60)
	local s = sec % 60
	return string.format("%02d:%02d", min, s)
end

local function getTotalChunks(path)
	local size = fs.getSize(path)
	return math.ceil(size / CHUNK_SIZE)
end

local function checkSpeaker()
	-- if bOS.speaker then return true end
	-- if peripheral.find("speaker") then
	-- 	bOS.speaker = peripheral.find("speaker")
	-- 	return true
	-- end
	local speakerWin = UI.MsgWin(root, "INFO")
	speakerWin:callWin(" INFO ", "Speaker not found. Please, put speaker near computer.")
	return false
end

local function play_at_chunk(start_chunk)
	local start_pos = (start_chunk - 1) * CHUNK_SIZE
	root.music_file.seek("set", start_pos)
	root.current_chunk = start_chunk
end

local function play(self, path)
	-- if not checkSpeaker() then return end
	self.filePath = path or self.filePath
	local total_chunks = getTotalChunks(self.filePath)
	timeLine.arr = {}
	for i = 1, total_chunks do
		timeLine.arr[i] = i
	end
	local temp = self.filePath:match("([^/\\]+)$")
	totalTimeLabel:setText(cache[temp].time)

	ArtistName:setText(cache[temp].artist)
	local Title = cache[temp].title
	if Title ~= "Unknown" then
		trackName:setText(Title)
	else
		local name = temp:match("(.+)%..-$")
		trackName:setText(name)
	end

	self.music_file = fs.open(self.filePath, "rb")
	if not self.music_file then error("Failed to open file: " .. self.filePath) end
	local ok, fileSize = pcall(function() return self.music_file.seek("end") end)
	fileSize = tonumber(fileSize) or 0

	self.data_end = fileSize
	if cache[temp].meta_start then
		self.data_end = cache[temp].meta_start - 1
	end

	play_at_chunk(1)
	self:play_next_chunk()
end

local function play_next_chunk(self)
	local cur_pos = self.music_file.seek("cur")
	if cur_pos >= self.data_end then
		if conf["play_next"] then
			os.queueEvent("play_next")
			self.music_file.close()
			return
		end
		os.queueEvent("pause_music")
		return
	end
	local to_read = _min(CHUNK_SIZE, self.data_end - cur_pos)
	if to_read <= 0 then return false end
	local chunk = self.music_file.read(to_read)
	if not chunk then return false end
	local buffer = self.decoder(chunk)
	speaker_play = speaker.playAudio(buffer, volume)
	self.current_chunk = self.current_chunk + 1
	timeLine.slidePosition = self.current_chunk
	timeLine.dirty = true
	local time_per_chunk = CHUNK_SIZE * SAMPLES_PER_BYTE / SAMPLE_RATE
	local current_sec = (self.current_chunk - 1) * time_per_chunk
	currentTimeLabel:setText(format_time(current_sec))
end

local function set_pause(bool)
	if root.pause == bool then return end
	root.pause = bool
	pause.play = not bool
	pause.dirty = true
end

local function updateTrackIcons(newIndex)
	if currentTrackIndex > 0 and trackButtons[currentTrackIndex] then
		trackButtons[currentTrackIndex].play = false
		trackButtons[currentTrackIndex].dirty = true
	end

	currentTrackIndex = newIndex

	if trackButtons[currentTrackIndex] then
		trackButtons[currentTrackIndex].play = true
		trackButtons[currentTrackIndex].dirty = true
	end
end

-- local temp_pressed = window.close.pressed
-- local function pressed(self)
-- 	if self.parent.music_file then
-- 		self.parent.music_file.close()
-- 	end
-- 	package.loaded["cc.audio.dfpwm"] = nil
-- 	package.loaded["sbin/MPlayer/Data/cache"] = nil
-- 	return temp_pressed(self)
-- end

local temp_onEvent = root.onEvent
local function onEvent(self, evt)
	local event = evt[1]
	if event == "speaker_audio_empty" and not self.pause then
		self:play_next_chunk()
		--return true
	elseif event == "unpause_music" then
		local cur_pos = self.music_file.seek("cur")
		set_pause(false)
		if cur_pos >= self.data_end then
			self:play()
			--return true
		end
		self:play_next_chunk()
		--return true
	elseif event == "play_music" then
		local trackIdx = evt[3]
		if trackIdx then
			updateTrackIcons(trackIdx)
		end
		self:play(evt[2])
		set_pause(false)
		--return true
	elseif event == "pause_music" then
		set_pause(true)
		--return true
	elseif event == "play_next" then
		btnNext:pressed()
		--return true
	end
	return temp_onEvent(self, evt)
end

root.decoder = dfpwm.make_decoder()
root.onEvent = onEvent
root.play = play
root.play_next_chunk = play_next_chunk
-- window.close.pressed = pressed

local function getConf()
	local val = ""
	if conf["play_next"] then
		val = "\167"
	else
		val = "\173"
	end
	return val
end
btnOptionAutoNext:setText(getConf())

local function getTotalSeconds(path)
	local size = fs.getSize(path)
	return size * SAMPLES_PER_BYTE / SAMPLE_RATE
end

local function cacheUpdate()
	local arr = fs.list(Path)
	local onDiskFiles = {}
	for _, v in pairs(arr) do
		onDiskFiles[v] = true
	end

	local newFiles = {}
	local cacheModified = false

	if type(cache) ~= "table" then
		cache = {}
		cacheModified = true
	end

	for _, v in pairs(arr) do
		if not cache[v] then
			table_insert(newFiles, v)
			cacheModified = true
		end
	end

	local removedFiles = {}
	for filename, _ in pairs(cache) do
		if not onDiskFiles[filename] then
			table_insert(removedFiles, filename)
			cacheModified = true
		end
	end

	for _, filename in pairs(removedFiles) do
		cache[filename] = nil
	end

	if #newFiles > 0 then
		for _, v in pairs(newFiles) do
			local handle = fs.open(Path .. v, "rb")
			if not handle then
				print("Warning: Could not open " .. v .. " to cache.")
				goto continue
			end

			local metadata = {}
			local _, fileSize = pcall(function() return handle.seek("end") end)
			fileSize = tonumber(fileSize) or 0
			local total_sec = getTotalSeconds(Path .. v)
			total_sec = format_time(total_sec)

			local tailRead = _min(8192, fileSize)
			local tail = ""
			if tailRead > 0 then
				pcall(function() handle.seek("set", _max(0, fileSize - tailRead)) end)
				tail = handle.read(tailRead) or ""
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
				pcall(function() handle.seek("set", meta_start + #"--METADATA--") end)
				local meta_len = meta_end - meta_start - #"--METADATA--"
				local meta_block = handle.read(meta_len) or ""

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
			handle.close()

			if not metadata["artist"] or metadata["artist"] == "" then metadata["artist"] = "Unknown" end
			if not metadata["title"] or metadata["title"] == "" then metadata["title"] = "Unknown" end
			if not metadata["album"] or metadata["album"] == "" then metadata["album"] = "Unknown" end

			cache[v] = metadata

			::continue::
		end
	end

	if cacheModified then
		local cacheFile, err = fs.open(APP_PATH.."/Data/cache", "w")
		if not cacheFile then
			print(err)
			return
		end
		cacheFile.write("return " .. textutils.serialise(cache))
		cacheFile.close()
	end
end
cacheUpdate()

sortedCache = {}
artistS = {}
for k, v in pairs(cache) do
	table_insert(sortedCache, k)
	table_insert(artistS, v.artist)
end
table_sort(sortedCache)
table_sort(artistS)

for i, v in pairs(sortedCache) do
	-- local trackPlay = UI.Button(1, 1 + i, 3, 1, "\16), _, _, boxAll.bc, colors.white)
	local trackPlay = UI.Button({
		x = 1, y = 1 + i,
		w = 3, h = 1,
		text = "\16",
		bc = boxAll.bc,
		fc = colors.white,
		fc_cl = colors.gray,
		bg_cl = colors.black,
	})
	trackPlay.play = false
	local trackPlay_draw = trackPlay.draw
	trackPlay.draw = function(self)
		self.text = "\16"
		if self.play then self.text = "\15" end
		trackPlay_draw(self)
	end
	trackPlay.pressed = function(self)
		os.queueEvent("play_music", Path .. v, i)
	end
	boxAll:addChild(trackPlay)
	table_insert(trackButtons, trackPlay)

	local name = v:match("(.+)%..-$")
	-- local trackLabel = UI.Label(trackPlay.x + trackPlay.w, trackPlay.y, boxAll.w - 10, 1, name, "left", boxAll.bc, colors.white)
	local trackLabel = UI.Label({
		x = trackPlay.x + trackPlay.w, y = trackPlay.y,
		w = boxAll.w - 10, h = 1,
		text = name,
		align = "left",
		bc = boxAll.bc,
		fc = colors.white,
	})
	boxAll:addChild(trackLabel)

	-- local trackTime = UI.Label(boxAll.w - 5, trackPlay.y, 5, 1, cache[v].time, "left", boxAll.bc, colors.lightGray)
	local trackTime = UI.Label({
		x = boxAll.w - 5, y = trackPlay.y,
		w = 5, h = 1,
		text = cache[v].time,
		align = "left",
		bc = boxAll.bc,
		fc = colors.lightGray,
	})
	boxAll:addChild(trackTime)
end
--[[
for i,v in pairs(artistS) do
	local buttonArtist = UI.Button(root,v,_,_,"left")
	buttonArtist.reSize = function (self)
		self.pos.y = i+2
		self.size.w = self.parent.size.w
	end
	scrollArtist:addChild(buttonArtist)
end]]

local function clearVolumeWidgets()
	if btnVolume then
		box2:removeChild(btnVolume)
		btnVolume = nil
	end
	if volumeSlider then
		box2:removeChild(volumeSlider)
		volumeSlider = nil
	end
	if btnVolumeUp then
		box2:removeChild(btnVolumeUp)
		btnVolumeUp = nil
	end
	if btnVolumeDown then
		box2:removeChild(btnVolumeDown)
		btnVolumeDown = nil
	end
	if volumeLabel then
		box2:removeChild(volumeLabel)
		volumeLabel = nil
	end
end

local function initWideMode(width)
	if btnVolume and volumeSlider then
		btnVolume.local_x = width - 13
		volumeSlider.local_x = width - 10
		return
	end

	clearVolumeWidgets()

	-- btnVolume = UI.Button(width - 13, 2, 3, 1, "", _, _, box2.bc, colors.white)
	btnVolume = UI.Button({
		x = width - 13, y = 2,
		w = 3, h = 1,
		bc = box2.bc,
		fc = colors.white,
	})
	btnVolume.PrevStatus = 1

	btnVolume.draw = function(self)
		term.setBackgroundColor(self.fc)
		term.setTextColor(self.bc)
		term.setCursorPos(self.x, self.y)
		term.write("\145")
		-- screen.write("\145), self.x, self.y, self.fc, self.bc)
		if conf["volume"] ~= 0 then
			term.setCursorPos(self.x + 1, self.y)
			term.write("\157")
			term.setBackgroundColor(self.bc)
			term.setTextColor(self.fc)
			term.setCursorPos(self.x + 2, self.y)
			term.write("\132")
			-- screen.write("\157), self.x + 1, self.y, self.fc, self.bc)
			-- screen.write("\132), self.x + 2, self.y, self.bc, self.fc)
		else
			term.setBackgroundColor(self.parent.bc)
			term.setTextColor(self.fc)
			term.setCursorPos(self.x + 1, self.y)
			term.write("x ")
			-- screen.write("x ", self.x + 1, self.y, self.parent.bc, self.fc)
		end
	end

	btnVolume.pressed = function(self)
		if conf["volume"] == 0 then
			conf["volume"] = self.PrevStatus
			for i, v in pairs(volumes) do
				if v == conf["volume"] then
					if volumeSlider then volumeSlider.slidePosition = i end
					break
				end
			end
			volume = self.PrevStatus
		else
			self.PrevStatus = conf["volume"]
			conf["volume"] = 0
			volume = 0
			if volumeSlider then volumeSlider.slidePosition = 1 end
		end
		c.saveConf(confPath, conf)
		self.dirty = true
		if volumeSlider then volumeSlider.dirty = true end
	end

	local currentIdx = 1
	for i, v in pairs(volumes) do
		if v == conf["volume"] then
			currentIdx = i
			break
		end
	end

	-- volumeSlider = UI.Slider(width - 10, 2, 10, volumes, currentIdx, colors.lightGray, box2.bc, colors.white)
	volumeSlider = UI.Slider({
		x = width - 10, y = 2,
		w = 10,
		arr = volumes,
		slidePosition = currentIdx,
		fc_alt = colors.lightBlue,
		bc = box2.bc,
		fc = colors.white,
		fc_cl = colors.lightGray,
	})

	volumeSlider.pressed = function(self, btn, x, y)
		volume = self.arr[self.slidePosition]
		conf["volume"] = volume
		c.saveConf(confPath, conf)
		if btnVolume then btnVolume.dirty = true end
	end

	box2:addChild(btnVolume)
	box2:addChild(volumeSlider)
end

local function initNarrowMode(width)
	if btnVolumeUp and volumeLabel then
		local volX = width - 2
		btnVolumeUp.local_x = volX
		volumeLabel.local_x = volX
		btnVolumeDown.local_x = volX
		return
	end

	clearVolumeWidgets()

	local volX = width - 2

	local currentIdx = 1
	for i, v in pairs(volumes) do
		if v == conf["volume"] then
			currentIdx = i
			break
		end
	end

	-- btnVolumeUp = UI.Button(volX, 1, 3, 1, "\30), _, _, box2.bc, colors.white)
	btnVolumeUp = UI.Button({
		x = volX, y = 1,
		w = 3, h = 1,
		text = "\30",
		bc = box2.bc,
		fc = colors.white,
	})

	-- volumeLabel = UI.Label(volX, 2, 3, 1, tostring(currentIdx - 1), "center", box2.bc, colors.lightGray)
	volumeLabel = UI.Label({
		x = volX, y = 2,
		w = 3, h = 1,
		text = tostring(currentIdx - 1),
		align = "center",
		bc = box2.bc,
		fc = colors.lightGray,
	})

	-- btnVolumeDown = UI.Button(volX, 3, 3, 1, "\31), _, _, box2.bc, colors.white)
	btnVolumeDown = UI.Button({
		x = volX, y = 3,
		w = 3, h = 1,
		text = "\31",
		bc = box2.bc,
		fc = colors.white,
	})

	btnVolumeUp.pressed = function(self)
		local cIdx = tonumber(volumeLabel.text) + 1 or 1
		local nIdx = _min(cIdx + 1, #volumes)
		volume = volumes[nIdx]
		conf["volume"] = volume
		c.saveConf(confPath, conf)
		volumeLabel:setText(tostring(nIdx - 1))
	end

	btnVolumeDown.pressed = function(self)
		local cIdx = tonumber(volumeLabel.text) + 1 or 1
		local nIdx = _max(cIdx - 1, 1)
		volume = volumes[nIdx]
		conf["volume"] = volume
		c.saveConf(confPath, conf)
		volumeLabel:setText(tostring(nIdx - 1))
	end

	box2:addChild(btnVolumeUp)
	box2:addChild(volumeLabel)
	box2:addChild(btnVolumeDown)
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
-- btnAll.pressed = function (self)
-- 	if root:removeChild(boxAlbum) then
-- 		btnAlbum.txtcol = colors.lightGray
-- 		self.txtcol = colors.black
-- 		root:addChild(boxAll)
-- 		boxAll:onLayout()
-- 		scrollbar:setObj(boxAll)
-- 	end
-- end

-- btnAlbum.pressed = function (self)
-- 	if root:removeChild(boxAll) then
-- 		btnAll.txtcol = colors.lightGray
-- 		self.txtcol = colors.black
-- 		root:addChild(boxAlbum)
-- 		boxAlbum:onLayout()
-- 		scrollbar:setObj(scrollboxAlbum)
-- 	end
-- end

pause.pressed = function(self)
	if self.play then
		os.queueEvent("pause_music")
	elseif not self.play and root.pause then
		os.queueEvent("unpause_music")
	end
end

btnNext.pressed = function(self)
	if #sortedCache == 0 then return end

	local nextIndex = currentTrackIndex + 1
	if nextIndex > #sortedCache then
		nextIndex = 1
	end

	local nextPath = Path .. sortedCache[nextIndex]

	os.queueEvent("play_music", nextPath, nextIndex)
end

btnPrev.pressed = function(self)
	if #sortedCache == 0 then return end

	local prevIndex = currentTrackIndex - 1
	if prevIndex < 1 then
		prevIndex = #sortedCache
	end

	local prevPath = Path .. sortedCache[prevIndex]

	os.queueEvent("play_music", prevPath, prevIndex)
end

btnOptionAutoNext.pressed = function(self)
	if conf["play_next"] == true then
		conf["play_next"] = false
		self:setText("\173")
	else
		conf["play_next"] = true
		self:setText("\167")
	end
	c.saveConf(confPath, conf)
end

timeLine.pressed = function(self, btn, x, y)
	if not root.music_file then return end
	local relative_x = x - self.x
	local width_range = _max(1, self.w - 1)
	local percentage = relative_x / width_range
	local total_chunks = #self.arr
	local exact_pos = percentage * total_chunks + 1
	local new_pos = math_floor(exact_pos + 0.5)
	new_pos = _max(1, _min(total_chunks, new_pos))
	self.slidePosition = new_pos
	play_at_chunk(new_pos)
end

boxAll.onResize = function(width, height)
	for i = 1, #boxAll.children, 3 do
		boxAll.children[i + 1].w = width - 10
		boxAll.children[i + 2].local_x = width - 5
	end
end

box2.onResize = function(width, height)
	compact = width > 41
	if compact then
		initWideMode(width)
	else
		initNarrowMode(width)
	end
	AN_X = compact and 10 or 2
	TL_X = compact and 16 or 8
	pause.local_x = math_floor((width - 2) / 2) + 1
	btnNext.local_x = pause.local_x + pause.w + 1
	btnPrev.local_x = pause.local_x - 3
	btnOptionAutoNext.local_x = btnNext.local_x + btnNext.w + 1
	ArtistName.local_x, ArtistName.w = AN_X, btnPrev.local_x - AN_X - 1
	trackName.local_x, trackName.w = ArtistName.local_x, ArtistName.w
	currentTimeLabel.local_x = compact and 10 or 2
	totalTimeLabel.local_x = compact and width - 11 or width - 5
	timeLine.local_x, timeLine.w = TL_X, totalTimeLabel.local_x - TL_X - 1
end

surface.onResize = function(width, height)
	surface.w, surface.h = width, height
	boxAll.w, boxAll.h = width - 1, height - 5
	boxAll.win.reposition(boxAll.x, boxAll.y, boxAll.w, boxAll.h)
	scrollbar.local_x, scrollbar.h = boxAll.w + 1, boxAll.h
	box2.local_y, box2.w = height - 4, width
	box2.onResize(box2.w, box2.h)
	boxAll.onResize(boxAll.w, boxAll.h)
	if root.music_file and not speaker_play then play_next_chunk(root) end
end
-----------------------------------------------------
local compact = box2.w > 41

if compact then
	initWideMode(box2.w)
else
	initNarrowMode(box2.w)
end

root:mainloop()
