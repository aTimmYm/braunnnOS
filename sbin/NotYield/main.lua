local sys = require "sys"

sys.register_window("NotYield", 1, 1, 51, 18, true)

local i = 1

while true do
	i = i + 1
	print(i)
end