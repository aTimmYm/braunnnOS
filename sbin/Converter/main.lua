------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local math_min = math.min
local string_byte = string.byte
local string_sub = string.sub
-----------------------------------------------------
local system = require("braunnnsys")
local UI = require("ui")
local lib

lib = require("sbin/Converter/Data/id3_meta")
local readID3v1 = lib.readID3v1
local readID3v2 = lib.readID3v2

lib = require("sbin/Converter/Data/mp4_meta")
local readMP4Metadata = lib.readMP4Metadata

local termTxtcol = term.getTextColor()

local window, surface = system.add_window("Titled", colors.black, "Converter")

local W = math_min(24, surface.w - 3)

local textfield_filePath = UI.New_Textfield(2, 2, W, 1, "Path to the audio file", false, colors.gray, colors.white)
surface:addChild(textfield_filePath)

local textfield_saveTo = UI.New_Textfield(2, 4, W, 1, "Path to save new file", false, colors.gray, colors.white)
surface:addChild(textfield_saveTo)

local btnConvert = UI.New_Button(2, 6, 14, 3, "Convert", "center", colors.lightGray, colors.white)
surface:addChild(btnConvert)

local btnDef = UI.New_Button(17, 6, 7, 1, "DefPath", "center", colors.lightGray, colors.white)
surface:addChild(btnDef)

local progress_convert = UI.New_LoadingBar(2, 3, W, colors.black, colors.blue, colors.black, "center", 0)
surface:addChild(progress_convert)

btnConvert.pressed = function (self)
	local filePath = textfield_filePath.text
	if filePath == "" or not fs.exists(filePath) then
		UI.New_MsgWin("INFO", " Error ", "File not found! Try again.")
		window:onLayout()
		return
	end
	local fileSave = textfield_saveTo.text
	if fileSave == "" then
		UI.New_MsgWin("INFO", " Error ", "Enter the path to save file.")
		window:onLayout()
		return
	end
	if fileSave:sub(-1) == "/" then
		UI.New_MsgWin("INFO", " Error ", "Incorrect name of file to save.")
		window:onLayout()
		return
	end
	local ext = filePath:match("%.([^%.]+)$"):lower()

	progress_convert:setValue(0.1)

	local file = fs.open(filePath, "rb")
	local tags = {}
	local data = file.readAll()
	file.close()

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

	progress_convert:setValue(0.25)

	local success, response = pcall(http.post, "https://remote.craftos-pc.cc/music/upload", data, {["Content-Type"] = "application/octet-stream"})
	if not success then
		UI.New_MsgWin("INFO", " Error ", "http.post error: " .. response .. ", try again.")
		window:onLayout()
		return
	end

	local id = response.readAll()
	response.close()

	progress_convert:setValue(0.5)

	local wavUrl = "https://remote.craftos-pc.cc/music/content/" .. id .. ".wav"
	local request = http.get(wavUrl)
	if not request then
		UI.New_MsgWin("INFO", " Error ", "Downloading error, try again.")
		window:onLayout()
		return
	end

	local wavData = request.readAll()
	request.close()
	progress_convert:setValue(0.8)
	local dataPos = wavData:find("data", 1, true)
	local dfpwmRaw = wavData  -- По умолчанию весь файл
	if dataPos then
		local b1 = string_byte(wavData, dataPos + 4) or 0
		local b2 = string_byte(wavData, dataPos + 5) or 0
		local b3 = string_byte(wavData, dataPos + 6) or 0
		local b4 = string_byte(wavData, dataPos + 7) or 0
		local chunkSize = b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)

		dfpwmRaw = string_sub(wavData, dataPos + 8, dataPos + 7 + chunkSize)
	else
		UI.New_MsgWin("INFO", " Error ", "Chunck 'data' not found! Saving file...")
		window:onLayout()
	end

	if not fileSave:find(".dfpwm") then fileSave = fileSave .. ".dfpwm" end
	local meta_block = "\n--METADATA--\n" ..
	"Title:" .. tags.title .. "\n" ..
	"Artist:" .. tags.artist .. "\n" ..
	"Album:" .. tags.album .. "\n" ..
	"--ENDMETADATA--\n"

	local outputfile = fs.open(fileSave, "wb")
	outputfile.write(dfpwmRaw .. meta_block)
	outputfile.close()

	progress_convert:setValue(1)
	UI.New_MsgWin("INFO", " Success ", "Filed converted and saved to " .. fileSave)
	progress_convert:setValue(0)
	window:onLayout()
end

btnDef.pressed = function (self)
	local fileName = textfield_filePath.text:match("([^/]+)$") or ""
	fileName = fileName:match("(.+)%..-$") or fileName
	textfield_saveTo.text = ""
	textfield_saveTo:onPaste("home/Music/" .. fileName)
end

surface:onLayout()