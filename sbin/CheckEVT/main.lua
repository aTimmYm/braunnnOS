local sys = require "sys"
sys.register_window("CheckEVT", 1, 1, 51, 18, true)
while true do
	local evt = {os.pullEvent()}
	print(textutils.serialize(evt))
end