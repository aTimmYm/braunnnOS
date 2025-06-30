--DEBUG-----------------------------
local function printTable(...)
	local inp = {...}
	for	i, v in pairs(inp) do
		if type(inp[i]) == "table" then
			for i,v in pairs(inp[i]) do
				print(i,"-",v)
			end
		else
			error("The variable type 'table' is not a table")
			break
		end
	end
end
------------------------------------


local curTerm = term.current()
local elements = {}
local sWidth, sHeight = curTerm.getSize()

local function redraw()
    for i, cw in ipairs(elements) do
        cw.redraw()
    end
    term.clear()
end

local function createWindow(a, nX, nY, nWidth, nHeight, visible, name)
    local cw = window.create(curTerm, nX, nY, nWidth, nHeight, visible)
    local name = {cw, name}
    table.insert(elements, name)
end

term.setCursorPos(1,1)
term.setBackgroundColor(colors.lightGray)
term.clear()

createWindow(curTerm, 1, 1, sWidth, 1, true, taskbar)
printTable(elements[1])
