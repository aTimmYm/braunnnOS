local sys = require "syscalls"

sys.register_window("NotYield", 1, 1, 39, 14, true)

local i = 1

while true do
	i = i + 1
	print(i)
end