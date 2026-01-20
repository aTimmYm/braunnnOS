local count = 1000


local function sort()

end

local function OLD()
	local start_timer = os.clock()

	for c = 1, count do
		local t = {}
		for i = 1, #windows_visible do
			local win = windows_visible[i]
			t[i] = { win = win, index = i }
		end

		table.sort(t, function(a, b)
			if a.win.order ~= b.win.order then
				return a.win.order < b.win.order
			end

			return a.index < b.index
		end)

		for i = 1, #t do
			windows_visible[i] = t[i].win
		end
	end

	local end_timer = os.clock()

	return end_timer - start_timer
end

print("OLD: "..)
print("NEW: "..)