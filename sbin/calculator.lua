-- Simple calculator app using the project's UI library (lib/ui.lua)
-- Layout: top display label + grid of buttons
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local root = UI.New_Root(colors.black)
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
local app = UI.New_Box(root, root.bg)
root:addChild(app)

local header = UI.New_Label(root, "Calculator", colors.white, colors.black, "center")
header.reSize = function(self)
    self.pos = { x = 1, y = 1 }
    self.size.w = self.parent.size.w-1
end
app:addChild(header)

local buttonClose = UI.New_Button(root, "x",colors.white, colors.black)
buttonClose.reSize = function(self)
    self.pos = { x = self.parent.size.w, y = 1 }
end
app:addChild(buttonClose)

local display = UI.New_Label(root, "0", root.bg, colors.white, "right")
display.reSize = function(self)
	self.pos = { x = self.parent.pos.x + 1, y = self.parent.pos.y + 1 }
	self.size = { w = math.max(10, self.parent.size.w - 2), h = 3 }
end
app:addChild(display)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function setDisplay(text)
	text = tostring(text or "0")
	-- Truncate if too long
	if #text > display.size.w then
		text = string.sub(text, #text - display.size.w + 1)
	end
	display:setText(text)
end
setDisplay(0)

local function is_valid_expr(s)
	-- allow only digits, operators, dot and parentheses
	if not s or s == "" then return false end
	if string.find(s, "[^%d%+%-%*/%.%(%)]") then return false end
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
		local btn = UI.New_Button(root, txt)
		btn.size = btn.size or { w = 6, h = 3 }

		btn.reSize = function(self)
			local padX = 0
			local padY = 0
			local totalCols = #btnTexts[1]
			--local btnW = math.floor((self.parent.size.w - (totalCols + 1)) / totalCols)
			local btnW = math.floor((self.parent.size.w - (totalCols - 1)) / totalCols)
			self.size.w = btnW
			self.size.h =  math.floor((self.parent.size.h - 3)/5)
			local x = self.parent.pos.x + (col - 1) * (btnW + padX) + 1
			local y = self.parent.pos.y + display.size.h + (row - 1) * (self.size.h + padY) + 1
			self.pos = { x = x, y = y }
		end

		btn.pressed = function(self)
			if txt == "C" then
				expr = ""
				setDisplay(0)
				return
			elseif txt == string.char(27) then
				expr = string.sub(expr, 1, -2)
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

		app:addChild(btn)
		table.insert(buttons, btn)
	end
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function(self)
    self.root.running_program = false
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------