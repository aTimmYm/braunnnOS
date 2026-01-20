--DESIGN BY BASNIPE(AI)
local sys = require "sys"
sys.register_window("CheckEVT", 1, 1, 51, 18, true)

local function printEvent(evt)
	local name = tostring(evt[1] or "nil")

	local parts = { name }

	for i = 2, #evt do
		local v = evt[i]
		if type(v) == "table" then
			parts[#parts + 1] = "[table]"
		else
			parts[#parts + 1] = textutils.serialize(v)
		end
	end

	print(table.concat(parts, " "))
end

while true do
	local evt = { os.pullEvent() }
	printEvent(evt)
end