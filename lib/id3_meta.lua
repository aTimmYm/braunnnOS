local lib = require("translit")
local decode_and_translit = lib.decode_and_translit
local string_sub = string.sub
local string_byte = string.byte
local ret = {}
-- Функции для чтения ID3 тегов
function ret.readID3v1(data)
	if #data < 128 then return nil end
	local tag = string_sub(data, -128)
	if string_sub(tag, 1, 3) ~= "TAG" then return nil end
	-- Для ID3v1 предполагаем encoding 0 (часто Windows-1251)
	return {
		title = decode_and_translit(0, string_sub(tag, 4, 33)),
		artist = decode_and_translit(0, string_sub(tag, 34, 63)),
		album = decode_and_translit(0, string_sub(tag, 64, 93)),
		year = decode_and_translit(0, string_sub(tag, 94, 97)),
		comment = decode_and_translit(0, string_sub(tag, 98, 125)),
		genre = string_byte(tag, 128)
	}
end

function ret.readID3v2(data)
	if string_sub(data, 1, 3) ~= "ID3" then return nil end
	local version = string_byte(data, 4)
	local revision = string_byte(data, 5)
	local flags = string_byte(data, 6)
	local function decodeSyncSafe(b1, b2, b3, b4)
		return (b1 * 2097152) + (b2 * 16384) + (b3 * 128) + b4
	end
	local size = decodeSyncSafe(string_byte(data, 7), string_byte(data, 8), string_byte(data, 9), string_byte(data, 10))
	local result = { version = version, revision = revision, title = "", artist = "", album = "" }
	local pos = 11
	while pos < size + 10 do
		local frameID = string_sub(data, pos, pos + 3)
		if frameID == "" or frameID:match("^%z+$") then break end
		local frameSize
		if version == 4 then
			frameSize = decodeSyncSafe(string_byte(data, pos + 4), string_byte(data, pos + 5), string_byte(data, pos + 6), string_byte(data, pos + 7))
		else
			frameSize = string_byte(data, pos + 4) * 16777216 + string_byte(data, pos + 5) * 65536 + string_byte(data, pos + 6) * 256 + string_byte(data, pos + 7)
		end
		local frameFlags = string_byte(data, pos + 8) * 256 + string_byte(data, pos + 9)
		local frameData = string_sub(data, pos + 10, pos + 9 + frameSize)
		local function decodeText(data)
			local encoding = string_byte(data, 1) or 0
			local text = string_sub(data, 2)
			return decode_and_translit(encoding, text)
		end
		if frameID == "TIT2" then result.title = decodeText(frameData)
		elseif frameID == "TPE1" then result.artist = decodeText(frameData)
		elseif frameID == "TALB" then result.album = decodeText(frameData) end
		pos = pos + 10 + frameSize
	end
	return result
end

return ret