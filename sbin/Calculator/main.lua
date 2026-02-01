-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И surface |-------
local sys = require "syscalls"
local UI = require "ui2"
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local expr = ""

local buttons = {}
local btnTexts = {
	{"7","8","9","/"},
	{"4","5","6","*"},
	{"1","2","3","-"},
	{"0",".","=","+"},
	{"C","\27","(",")"}
}
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
sys.register_window("Calculator", 1, 1, 19, 14, true)

local root = UI.Root()

-- local surface = UI.Box(1, 1, root.w, root.h, colors.gray, colors.white)
local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.gray,
	fc = colors.white,
})
root:addChild(surface)

-- local display = UI.Label(1, 1, surface.w, 3, "0", "right", colors.black, colors.white)
local display = UI.Label({
	x = 1, y = 1,
	w = surface.w, h = 3,
	text = "0",
	align = "right",
	bc = colors.black,
	fc = colors.white,
})
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

		-- local btn = UI.Button(x, y, w, h, txt, _, _, surface.color_bg, colors.white)
		local btn = UI.Button({
			x = x, y = y,
			w = w, h = h,
			text = txt,
			bc = surface.bc,
			fc = colors.white,
		})

		btn.pressed = function(self)
			if txt == "C" then
				expr = ""
				setDisplay(0)
				return
			elseif txt == "\27" then
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
					local sres = tostring(res)
					setDisplay(sres)
					expr = sres
				end
				return
			else
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
	surface.w, surface.h = width, height
	display.w = width
	for row = 1, #btnTexts do
		for col = 1, #btnTexts[row] do
			local totalCols = #btnTexts[1]
			local btn = buttons[(row - 1) * totalCols + col]
			btn.w = math.floor((width - (totalCols - 1)) / totalCols)
			btn.h = math.floor((height - 3)/5)
			btn.local_x = surface.x + (col - 1) * btn.w + 1
			btn.local_y = display.h + (row - 1) * btn.h + 1
		end
	end
end
-----------------------------------------------------
root:mainloop()