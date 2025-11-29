-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local system = require("braunnnsys")
local UI = require("ui")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local expr = ""

local buttons = {}
local btnTexts = {
	{"7","8","9","/"},
	{"4","5","6","*"},
	{"1","2","3","-"},
	{"0",".","=","+"},
	{"C",string.char(27),"(",")"}
}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "Calculator")

local display = UI.New_Label(1, 1, math.max(10, surface.w - 2), 3, "0", "right", surface.color_bg, colors.white)
surface:addChild(display)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------

local function setDisplay(text)
	text = tostring(text or "0")
	-- Truncate if too long
	if #text > display.w then
		text = text:sub(#text - display.w + 1)
	end
	display:setText(text)
end
setDisplay(0)

local function is_valid_expr(s)
	-- allow only digits, operators, dot and parentheses
	if not s or s == "" then return false end
	if s:find("[^%d%+%-%*/%.%(%)]") then return false end
	return true
end

local function eval_expr(s)
	if not is_valid_expr(s) then return nil, "Invalid chars" end
	local chunk, err = load("return " .. s)
	if not chunk then return nil, err end
	local ok, res = pcall(chunk)
	if not ok then return nil, res end
	return res
end

for row = 1, #btnTexts do
	for col = 1, #btnTexts[row] do
		local txt = btnTexts[row][col]
		local totalCols = #btnTexts[1]
		local w = math.floor((surface.w - (totalCols - 1)) / totalCols)
		local h = math.floor((surface.h - 3)/5)
		local x = surface.x + (col - 1) * w + 1
		local y = display.h + (row - 1) * h + 1

		local btn = UI.New_Button(x, y, w, h, txt)

		btn.pressed = function(self)
			if txt == "C" then
				expr = ""
				setDisplay(0)
				return
			elseif txt == string.char(27) then
				expr = expr:sub(1, -2)
				if expr == "" then setDisplay(0) else setDisplay(expr) end
				return
			elseif txt == "=" then
				if expr == "" then return end
				local res, err = eval_expr(expr)
				if err or res == nil then
					setDisplay("ERR")
					expr = ""
				else
					-- show number and keep it as expression for further ops
					local sres = tostring(res)
					setDisplay(sres)
					expr = sres
				end
				return
			else
				-- Append digit/operator
				expr = expr .. txt
				setDisplay(expr)
			end
		end

		surface:addChild(btn)
		table.insert(buttons, btn)
	end
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
surface.onResize = function (width, height)
	display.w = math.max(10, width - 2)
	for row = 1, #btnTexts do
		for col = 1, #btnTexts[row] do
			local totalCols = #btnTexts[1]
			local btn = buttons[(row - 1) * totalCols + col]
			btn.w = math.floor((width - (totalCols - 1)) / totalCols)
			btn.h = math.floor((height - 3)/5)
			btn.local_x = surface.local_x + (col - 1) * btn.w + 1
			btn.local_y = display.h + (row - 1) * btn.h + 1
		end
	end
end
-----------------------------------------------------
surface:onLayout()