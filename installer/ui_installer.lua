------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local _rep = string.rep
local _sub = string.sub
local string_find = string.find
local string_char = string.char
local string_gmatch = string.gmatch
local table_insert = table.insert
local _max = math.max
local _min = math.min
local _floor = math.floor
local _ceil = math.ceil
local function clamp(val, a, b) return _max(a, _min(b, val)) end
-----------------------------------------------------
--CC:Tweaked Lua Minecraft CraftOS bOS™
--lib/ui.lua v0.4.0
local UI = {}

local EVENTS = {
	TOP = {
		["mouse_click"] = true,
		["mouse_scroll"] = true,
	},
	FOCUS = {
		["mouse_up"] = true,
		["mouse_drag"] = true,
		["char"] = true,
		["key"] = true,
		["key_up"] = true,
		["paste"] = true,
		["term_resize"] = true,
	}
}

local expect = require("cc.expect")
local blittle = require("blittle_extended")

local function clip_calc(x1, y1, w1, h1, x2, y2, w2, h2)
	return _max(x1, x2), _max(y1, y2), _min(w1, w2), _min(h1, h2)
end

local function check(self,x,y)
	return (x >= self.x and x < self.w + self.x and
			y >= self.y and y < self.h + self.y)
end
local function onKeyDown(self,key,held) return true end
local function onKeyUp(self,key) return true end
local function onCharTyped(self,chr) return true end
local function onPaste(self,text) return true end
local function onMouseDown(self,btn,x,y) return true end
local function onMouseUp(self,btn,x,y) return true end
local function onMouseScroll(self,dir,x,y) return false end
local function onMouseDrag(self,btn,x,y) return true end
local function onFocus(self,focused) return true end
local function focusPostDraw(self) end
local function pressed(self) end
local function onLayout(self) self.dirty = true end
local function draw(self) end
local function redraw(self)
	if self.dirty then self:draw() self.dirty = false end
end
local function onEvent(self,evt)
	if evt[1] == "mouse_drag" then
		return self:onMouseDrag(evt[2],evt[3],evt[4])
	elseif evt[1] == "mouse_up" then
		return self:onMouseUp(evt[2],evt[3],evt[4])
	elseif evt[1] == "mouse_click" then
		if self.root then self.root.focus = self end
		return self:onMouseDown(evt[2],evt[3],evt[4])
	elseif evt[1] == "mouse_scroll" then
		return self:onMouseScroll(evt[2],evt[3],evt[4])
	elseif evt[1] == "char" then
		return self:onCharTyped(evt[2])
	elseif evt[1] == "key" then
		return self:onKeyDown(evt[2],evt[3])
	elseif evt[1] == "key_up" then
		return self:onKeyUp(evt[2])
	elseif evt[1] == "paste" then
		return self:onPaste(evt[2])
	end
	return false
end

---Basic *class*. Using automatically to create all another *classes*.
---@param x number
---@param y number
---@param w number
---@param h number
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object widget (bigbrother)
local function New_Widget(x, y, w, h, color_bg, color_txt)
	return {
		x = x, y = y,
		w = w, h = h,
		color_bg = color_bg or colors.black,
		color_txt = color_txt or colors.white,
		dirty = true,
		parent = nil,

		check = check,
		onKeyDown = onKeyDown,
		onKeyUp = onKeyUp,
		onCharTyped = onCharTyped,
		onPaste = onPaste,
		onMouseDown = onMouseDown,
		onMouseUp = onMouseUp,
		onMouseScroll = onMouseScroll,
		onMouseDrag = onMouseDrag,
		onFocus = onFocus,
		focusPostDraw = focusPostDraw,
		draw = draw,
		redraw = redraw,
		onLayout = onLayout,
		onEvent = onEvent,
	}
end

local function Tumbler_draw(self)
	local frame = self.animation_frames[self.current_frame]
	for i = 1, 2 do
		local p = frame[i]
		term.setBackgroundColor(p.bgcol)
		term.setTextColor(p.txtcol)
		term.setCursorPos(self.x + i - 1, self.y)
		term.write(p.char)
	end
end

local function Tumbler_startAnimation(self,direction)
	if self.animating then return end
	self.animating = true
	self.animation_direction = direction
	self.current_frame = (direction == "to_on") and "anim1" or "anim2"
	self.dirty = true
	self.timer_id = os.startTimer(self.animation_speed)
end

local function Tumbler_updateAnimation(self)
	if self.animation_direction == "to_on" then
		if self.current_frame == "anim1" then
			self.current_frame = "anim2"
			self.timer_id = os.startTimer(self.animation_speed)
		elseif self.current_frame == "anim2" then
			self.current_frame = "on"
			self.animating = false
			self.on = true
		end
	elseif self.animation_direction == "to_off" then
		if self.current_frame == "anim2" then
			self.current_frame = "anim1"
			self.timer_id = os.startTimer(self.animation_speed)
		elseif self.current_frame == "anim1" then
			self.current_frame = "off"
			self.animating = false
			self.on = false
		end
	end
	self.dirty = true
end

local function Tumbler_onMouseDown(self, btn, x, y)
	if not self.animating then
		self:startAnimation(self.on and "to_off" or "to_on")
		self:pressed()
	end
	return true
end

local function Tumbler_onEvent(self, evt)
	if evt[1] == "timer" and evt[2] == self.timer_id then
		self:updateAnimation()
		return true
	end
	onEvent(self, evt)
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param bg_off color|number|nil
---@param bg_on color|number|nil
---@param switch_color color|number|nil
---@param on boolean|nil
---@return table object tumbler (switcher)
function UI.New_Tumbler(x, y, bg_off, bg_on, switch_color, on)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, bg_off, "number", "nil")
	expect(4, bg_on, "number", "nil")
	expect(5, switch_color, "number", "nil")
	expect(6, on, "boolean", "nil")

	local instance = New_Widget(x, y, 2, 1, _, _)
	instance.on = on or false
	instance.color_bg_off = bg_off or colors.gray
	instance.color_bg_on = bg_on or colors.lime
	instance.switch_color = switch_color or colors.white
	instance.animating = false
	instance.animation_frames = {
		off = {
			{char = string_char(149), txtcol = instance.switch_color, bgcol = instance.color_bg_off},
			{char = " ", txtcol = instance.color_bg_off, bgcol = instance.color_bg_off}
		},
		anim1 = {
			{char = string_char(149), txtcol = instance.color_bg_on, bgcol = instance.switch_color},
			{char = " ", txtcol = instance.color_bg_off, bgcol = instance.color_bg_off}
		},
		anim2 = {
			{char = " ", txtcol = instance.color_bg_on, bgcol = instance.color_bg_on},
			{char = string_char(149), txtcol = instance.switch_color, bgcol = instance.color_bg_off}
		},
		on = {
			{char = " ", txtcol = instance.color_bg_on, bgcol = instance.color_bg_on},
			{char = string_char(149), txtcol = instance.color_bg_on, bgcol = instance.switch_color}
		}
	}
	instance.current_frame = instance.on and "on" or "off"
	instance.animation_speed = 0.05  -- Задержка между кадрами в секундах
	instance.timer_id = nil
	instance.animation_direction = nil  -- "to_on" или "to_off"

	instance.draw = Tumbler_draw
	instance.startAnimation = Tumbler_startAnimation
	instance.updateAnimation = Tumbler_updateAnimation
	instance.onMouseDown = Tumbler_onMouseDown
	instance.onEvent = Tumbler_onEvent
	instance.pressed = pressed

	return instance
end

local function RadioButton_horizontal_draw(self)
	term.setBackgroundColor(self.color_bg)
	for i = 1, self.count do
		term.setCursorPos(self.x + i - 1, self.y)
		if self.item == i then
			term.setTextColor(self.color_txt)
		else
			term.setTextColor(colors.gray)
		end
		term.write(string_char(7))
	end
end

local function RadioButton_horizontal_changeCount(self, arg)
	self.count = arg
	self.w = arg
	self.dirty = true
end

local function RadioButton_horizontal_onMouseUp(self, btn, x, y)
	if self:check(x,y) then
		self.item = x - self.x + 1
		self.dirty = true
		self:pressed()
	end
	return true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param count number|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object radioButton_horizontal
function UI.New_RadioButton_horizontal(x, y, count, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, count, "number", "nil")
	expect(4, color_bg, "number", "nil")
	expect(5, color_txt, "number", "nil")

	local instance = New_Widget(x, y, 1, 1, color_bg, color_txt)
	instance.count = (count and count >= 1 and count or 1)
	instance.w = instance.count
	instance.item = 1

	instance.draw = RadioButton_horizontal_draw
	instance.changeCount = RadioButton_horizontal_changeCount
	instance.pressed = pressed
	instance.onMouseUp = RadioButton_horizontal_onMouseUp

	return instance
end

local function RadioButton_draw(self)
	term.setBackgroundColor(self.color_bg)
	for i, v in ipairs(self.text) do
		term.setCursorPos(self.x, self.y + i - 1)
		term.setTextColor(colors.gray)
		if self.item == i then
			term.setTextColor(self.color_txt)
		end
		term.write(string_char(7))
		term.setCursorPos(self.x + 1, self.y + i - 1)
		term.setTextColor(self.color_txt)
		term.write(_rep(" ", _min(#v, 1))..v)
	end
end

local function RadioButton_onMouseUp(self, btn, x, y)
	if self:check(x, y) then
		self.item = y - self.y + 1
		self.dirty = true
		self:pressed()
	end
	return true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param count number|nil
---@param text string[]|nil table of strings, example: {"string1", "string2"}
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object radioButton
function UI.New_RadioButton(x, y, count, text, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, count, "number", "nil")
	expect(4, text, "table", "nil") -- ← table of strings
	expect(5, color_bg, "number", "nil")
	expect(6, color_txt, "number", "nil")

	local instance = UI.New_RadioButton_horizontal(x, y, count, color_bg, color_txt)
	if text then
		instance.text = text
		instance.count = #instance.text
	else
		instance.text = {}
		for i = 1, instance.count do
			instance.text[i] = ""
		end
	end
	local t = c.findMaxLenStrOfArray(instance.text)
	instance.w = t == 0 and 1 or t + 2
	instance.h = instance.count

	instance.draw = RadioButton_draw
	instance.onMouseUp = RadioButton_onMouseUp

	return instance
end

local function Label_draw(self, bg_override, txtcol_override)
	bg_override = bg_override or self.color_bg
	txtcol_override = txtcol_override or self.color_txt
	local lines = {}
	if #self.text <= self.w then
		table_insert(lines, self.text)
	else
		local mass = {}
		for w in string_gmatch(self.text, "%S+") do
			table_insert(mass, w)
		end
		local row_txt = ""
		local i = 1
		while i <= #mass do
			local word = mass[i]
			if #word > self.w then
				local remainder = _sub(word, self.w + 1)
				if remainder ~= "" then
					table_insert(mass, i + 1, remainder)
				end
				mass[i] = _sub(word, 1, self.w)
				word = mass[i]
			end
			local space_len = (row_txt == "" and 0 or 1)
			if #row_txt + space_len + #word <= self.w then
				row_txt = row_txt .. (row_txt == "" and "" or " ") .. word
				i = i + 1
			else
				if row_txt ~= "" then
					table_insert(lines, row_txt)
					row_txt = ""
				end
			end
			if #lines >= self.h then break end
		end
		if row_txt ~= "" and #lines < self.h then
			table_insert(lines, row_txt)
		end
	end

	local horiz_align = "center"
	if string_find(self.align, "left") then
		horiz_align = "left"
	elseif string_find(self.align, "right") then
		horiz_align = "right"
	end

	local num_lines = #lines
	local vert_align = "center"
	if string_find(self.align, "top") then
		vert_align = "top"
	elseif string_find(self.align, "bottom") then
		vert_align = "bottom"
	end

	local start_y = self.y
	if vert_align == "top" then
		start_y = self.y
	elseif vert_align == "bottom" then
		start_y = self.y + self.h - num_lines
	else  -- center
		start_y = self.y + _floor((self.h - num_lines) / 2)
	end
	start_y = _max(start_y, self.y)

	for i = self.y, start_y - 1 do
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, i); term.setTextColor(txtcol_override); term.write(_rep(" ", self.w))
	end

	for j = 1, num_lines do
		local line = lines[j]
		local line_len = #line
		local x_pos = self.x
		if horiz_align == "left" then
			x_pos = self.x
		elseif horiz_align == "right" then
			x_pos = self.x + self.w - line_len
		else  -- center
			x_pos = self.x + _floor((self.w - line_len) / 2)
		end
		local left_pad = _rep(" ", x_pos - self.x)
		local right_pad = _rep(" ", self.w - (x_pos - self.x + line_len))
		local full_line = left_pad .. line .. right_pad
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, start_y + j - 1); term.setTextColor(txtcol_override); term.write(full_line)
	end

	local end_y = start_y + num_lines - 1
	for i = end_y + 1, self.y + self.h - 1 do
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, i); term.setTextColor(txtcol_override); term.write(_rep(" ", self.w))
	end
end

local function Label_setText(self, text)
	self.text = text
	self.dirty = true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param text string|nil
---@param align string|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object label
function UI.New_Label(x, y, w, h, text, align, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, text, "string", "nil")
	expect(6, align, "string", "nil")
	expect(7, color_bg, "number", "nil")
	expect(8, color_txt, "number", "nil")

	local instance = New_Widget(x, y, w, h, color_bg, color_txt)
	instance.text = text or ""
	instance.align = align or "center"

	instance.draw = Label_draw
	instance.setText = Label_setText

	return instance
end

local function Button_draw(self)
	if self.held then
		Label_draw(self, self.color_txt, self.color_bg)
	else
		Label_draw(self, self.color_bg, self.color_txt)
	end
end

local function Button_onMouseDown(self, btn, x, y)
	self.held = true
	self.dirty = true
	return true
end

local function Button_onMouseUp(self, btn, x, y)
	if self:check(x,y) and self.held == true then self:pressed() end
	self.held = false
	self.dirty = true
	return true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param text string|nil
---@param align string|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object button
function UI.New_Button(x, y, w, h, text, align, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, text, "string", "nil")
	expect(6, align, "string", "nil")
	expect(7, color_bg, "number", "nil")
	expect(8, color_txt, "number", "nil")

	local instance = New_Widget(x, y, w, h, color_bg, color_txt)
	instance.text = text or "button"
	instance.held = false
	instance.align = align or "center"

	instance.draw = Button_draw
	instance.pressed = pressed
	instance.onMouseDown = Button_onMouseDown
	instance.onMouseUp = Button_onMouseUp
	instance.setText = Label_setText

	return instance
end

local function Shortcut_draw(self)
	paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.color_bg)

	local dX = _floor((self.w - self.blittle_img.width)/2) + self.x
	local dY = _floor((self.h - 1 - self.blittle_img.height)/2) + self.y
	blittle.draw(self.blittle_img, dX, dY)
	local txtcol_override = self.held and colors.lightGray or self.color_txt

	term.setBackgroundColor(self.color_bg)
	term.setTextColor(txtcol_override)
	term.setCursorPos(self.x, dY + self.blittle_img.height)

	if #self.text >= self.w then
		term.write(_sub(self.text, 1, self.w - 2).."..")
	else
		term.write(_rep(" ",_floor((self.w - #self.text)/2))..self.text..
		_rep(" ", self.w - (_floor((self.w - #self.text)/2) + self.x + #self.text)))
	end
end

local function Shortcut_pressed(self)
	local func, load_err = loadfile(self.filePath, _ENV)  -- "t" для text, или "bt" если нужно
	if not func then
		UI.New_MsgWin("INFO", "Error", load_err)
	else
		local co = coroutine.create(func)
		table_insert(self.root.processes, co)
		-- debug.sethook(co, preempt_hook, "c", 10)
		coroutine.resume(co)

		local ret, exec_err = pcall(func)
		if not ret then
			UI.New_MsgWin("INFO", "Error", exec_err)
		end
	end
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param text string|nil
---@param filepath string
---@param icopath string
---@param color_bg number|nil
---@param color_txt number|nil
---@return table object shortcut
function UI.New_Shortcut(x, y, w, h, text, filepath, icopath, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, text, "string", "nil")
	expect(6, filepath, "string")
	expect(7, icopath, "string")
	expect(8, color_bg, "number", "nil")
	expect(9, color_txt, "number", "nil")

	local instance = UI.New_Button(x, y, w, h, text, _, color_bg, color_txt)
	instance.icoPath = icopath and fs.exists(icopath) and icopath or "usr/icon_default.ico"
	instance.needArgs = {}
	instance.filePath = filepath
	instance.blittle_img = blittle.load(instance.icoPath)

	instance.draw = Shortcut_draw
	instance.pressed = Shortcut_pressed

	return instance
end

local function Running_Label_draw(self, bg_override, txtcol_override)
	bg_override = bg_override or self.color_bg
	txtcol_override = txtcol_override or self.color_txt
	self:checkScrolling()
	if not self.scrolling then
		-- Если не нужно прокручивать, рисуем как обычный label
		Label_draw(self, bg_override, txtcol_override)
		return
	end
	-- Для прокрутки: собираем visible_text по символам с модульной адресацией
	local segment = (self.text or "") .. (self.scroll_gap)
	local cycle_len = #segment
	if cycle_len == 0 then
		local visible_text = _rep(" ", self.w)
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, self.y); term.setTextColor(txtcol_override); term.write(visible_text)
		return
	end

	-- нормалізуємо позицію в межах циклу
	local pos = ((self.scroll_pos - 1) % cycle_len) + 1

	-- будуємо видимий рядок по-символьно, щоб уникнути артефактів при обгортанні
	local visible_chars = {}
	for i = 0, self.w - 1 do
		local idx = ((pos - 1 + i) % cycle_len) + 1
		visible_chars[#visible_chars + 1] = _sub(segment, idx, idx)
	end
	local visible_text = table.concat(visible_chars)

	-- Обрабатываем выравнивание (только горизонтальное, вертикальное игнорируем для простоты, так как h=1 предположительно)
	local horiz_align = "center"
	if string_find(self.align, "left") then
		horiz_align = "left"
	elseif string_find(self.align, "right") then
		horiz_align = "right"
	end

	local x_pos = self.x
	if horiz_align == "left" then
		x_pos = self.x
	elseif horiz_align == "right" then
		x_pos = self.x + self.w - #visible_text
	else  -- center
		x_pos = self.x + _floor((self.w - #visible_text) / 2)
	end

	local left_pad = _rep(" ", x_pos - self.x)
	local right_pad = _rep(" ", self.w - (x_pos - self.x + #visible_text))
	local full_line = left_pad .. visible_text .. right_pad

	term.setBackgroundColor(bg_override); term.setCursorPos(self.x, self.y); term.setTextColor(txtcol_override); term.write(full_line)

	-- Очистка остальных строк, если h > 1 (хотя для бегущей строки обычно h=1)
	for i = self.y + 1, self.y + self.h - 1 do
		term.setBackgroundColor(bg_override); term.setCursorPos(self.x, i); term.setTextColor(txtcol_override); term.write(_rep(" ", self.w))
	end
end

local function Running_Label_setText(self, text)
	if self.text ~= text then self.scroll_pos = 1 end
	self.text = text
	self:checkScrolling()
	self.dirty = true
end

local function Running_Label_checkScrolling(self)
	if #self.text > self.w then
		self.scrolling = true
		self:startTimer()
	else
		self.scrolling = false
		self:stopTimer()
		self.scroll_pos = 1
	end
end

local function Running_Label_startTimer(self)
	if not self.timer_id then
		self.timer_id = os.startTimer(self.scroll_speed)
	end
end

local function Running_Label_stopTimer(self)
	self.timer_id = nil
end

local function Running_Label_onEvent(self, evt)
	if evt[1] == "timer" and evt[2] == self.timer_id then
		if self.scrolling then
			self.scroll_pos = self.scroll_pos + 1
			local cycle_len = (#(self.text or "") + #(self.scroll_gap or ""))
			if cycle_len <= 0 then cycle_len = 1 end
			if self.scroll_pos > cycle_len then
				self.scroll_pos = 1
			end
			self.dirty = true
			self.timer_id = os.startTimer(self.scroll_speed)  -- Перезапускаем таймер
		else
			self.timer_id = nil  -- Не перезапускаем, если прокрутка не нужна
		end
		return true
	end
	onEvent(self,evt)
end

local function Running_Label_onLayout(self)
	onLayout(self)
	self:checkScrolling()
end

---Creating new *object* of *class* "shortcut"
---@param x number
---@param y number
---@param w number
---@param h number
---@param text string|nil
---@param align string|nil
---@param scroll_speed number|nil
---@param gap string|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table return Running_Label
function UI.New_Running_Label(x, y, w, h, text, align, scroll_speed, gap, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, text, "string", "nil")
	expect(6, align, "string", "nil")
	expect(7, scroll_speed, "number", "nil")
	expect(8, gap, "string", "nil")
	expect(9, color_bg, "number", "nil")
	expect(10, color_txt, "number", "nil")

	local instance = UI.New_Label(x, y, w, h, text, align, color_bg, color_txt)
	instance.scroll_speed = scroll_speed or 0.5  -- Задержка между сдвигами в секундах (по умолчанию 0.5)
	instance.scroll_pos = 1
	instance.timer_id = nil
	instance.scrolling = false
	instance.scroll_gap = gap or " " --_rep(" ", instance.w)

	instance.draw = Running_Label_draw
	instance.setText = Running_Label_setText
	instance.checkScrolling = Running_Label_checkScrolling
	instance.startTimer = Running_Label_startTimer
	instance.stopTimer = Running_Label_stopTimer
	instance.onEvent = Running_Label_onEvent
	instance.onLayout = Running_Label_onLayout

	return instance
end

local ScrollableMixin = {}

function ScrollableMixin:initScroll(sensitivity_x, sensitivity_y)
	self.scroll = {
		-- Вертикальный скроллинг
		pos_y = 0,
		max_y = 0,

		-- Горизонтальный скроллинг
		pos_x = 0,
		max_x = 0,

		-- Чувствительность
		sensitivity_x = sensitivity_x or 3,
		sensitivity_y = sensitivity_y or 3,
	}
	self.scrollbar_v = nil  -- Vertical scrollbar
	self.scrollbar_h = nil  -- Horizontal scrollbar
end

-- Вертикальный скроллинг
function ScrollableMixin:getScrollMaxY()
	return self.scroll.max_y
end

function ScrollableMixin:getScrollPosY()
	return self.scroll.pos_y
end

function ScrollableMixin:setScrollPosY(pos)
	local old_pos = self.scroll.pos_y
	self.scroll.pos_y = clamp(pos, 0, self:getScrollMaxY())

	if old_pos ~= self.scroll.pos_y then
		self:updateDirty()
		return true
	end
	return false
end

function ScrollableMixin:scrollY(direction)
	local new_pos = self.scroll.pos_y + (direction * self.scroll.sensitivity_y)
	return self:setScrollPosY(_floor(new_pos + 0.5))
end

-- Горизонтальный скроллинг
function ScrollableMixin:getScrollMaxX()
	return self.scroll.max_x
end

function ScrollableMixin:getScrollPosX()
	return self.scroll.pos_x
end

function ScrollableMixin:setScrollPosX(pos)
	local old_pos = self.scroll.pos_x
	self.scroll.pos_x = clamp(pos, 0, self:getScrollMaxX())

	if old_pos ~= self.scroll.pos_x then
		self:updateDirty()
		return true
	end
	return false
end

function ScrollableMixin:scrollX(direction)
	local new_pos = self.scroll.pos_x + (direction * self.scroll.sensitivity_x)
	return self:setScrollPosX(_floor(new_pos + 0.5))
end

-- Универсальный метод для обратной совместимости (если только Y скроллинг)
function ScrollableMixin:getScrollMax()
	return self:getScrollMaxY()
end

function ScrollableMixin:getScrollPos()
	return self:getScrollPosY()
end

function ScrollableMixin:setScrollPos(pos)
	return self:setScrollPosY(pos)
end

function ScrollableMixin:attachScrollbar(scrollbar, orientation)
	if orientation == "horizontal" or orientation == "h" then
		self.scrollbar_h = scrollbar
	else
		self.scrollbar_v = scrollbar
	end
end

local function add_mixin(object, mixin)
	for k, v in pairs(mixin) do
		object[k] = v
	end
end

local function Scrollbar_draw(self)
	local slider_height = self:getSliderHeight()
	local slider_offset = self:getSliderOffset()
	local slider_y_start = self.y + 1 + slider_offset

	-- Фон трека
	term.setBackgroundColor(self.color_bg)
	for y = self.y + 1, slider_y_start - 1 do
		term.setCursorPos(self.x, y)
		term.write(" ")
	end
	for y = slider_y_start + slider_height, self.y + self.h - 2 do
		term.setCursorPos(self.x, y)
		term.write(" ")
	end

	-- Стрелка вверх
	local up_bg, up_fg = (self.held == 1 and self.color_txt or self.color_bg), (self.held == 1 and self.color_bg or self.color_txt)
	term.setBackgroundColor(up_bg)
	term.setTextColor(up_fg)
	term.setCursorPos(self.x, self.y)
	term.write(string_char(30))

	-- Стрелка вниз
	local down_bg, down_fg = (self.held == 3 and self.color_txt or self.color_bg), (self.held == 3 and self.color_bg or self.color_txt)
	term.setBackgroundColor(down_bg)
	term.setTextColor(down_fg)
	term.setCursorPos(self.x, self.y + self.h - 1)
	term.write(string_char(31))

	-- Ползунок
	term.setBackgroundColor(self.color_txt)
	term.setTextColor(self.color_bg)
	for y = slider_y_start, _min(slider_y_start + slider_height - 1, self.y + self.h - 2) do
		term.setCursorPos(self.x, y)
		term.write(string_char(149))  -- Filled pixel
	end
end

local function Scrollbar_setObj(self, obj)
	self.obj = obj
	self.color_bg = self.obj.bg
	self.color_txt = self.obj.txtcol
	obj:attachScrollbar(instance, "vertical")
	self.dirty = true
end

local function Scrollbar_getTrackHeight(self)
	return self.h - 2
end

local function Scrollbar_checkIn(self, x, y)
	if y == self.y then
		self.held = 1  -- Up arrow
		return true
	elseif y == self.y + self.h - 1 then
		self.held = 3  -- Down arrow
		return true
	end
	return false
end

local function Scrollbar_isOnSlider(self, y)
	local slider_offset = self:getSliderOffset()
	local slider_height = self:getSliderHeight()
	local slider_y_start = self.y + 1 + slider_offset
	return y >= slider_y_start and y <= slider_y_start + slider_height - 1
end

local function Scrollbar_onMouseUp(self, btn, x, y)
	if self.held == 1 and self:check(x, y) and y == self.y then
		self.obj:scrollY(-1)
	elseif self.held == 3 and self:check(x, y) and y == self.y + self.h - 1 then
		self.obj:scrollY(1)
	end
	self.held = 0
	self.dirty = true
	return true
end

local function Scrollbar_onMouseScroll(self, dir, x, y)
	if self:check(x, y) then
		self.obj:scrollY(dir)
		return true
	end
	return false
end

local function Scrollbar_getSliderHeight(self)
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return 0 end

	local total_items = self.obj:getScrollMaxY() + self.obj.h
	local visible_items = self.obj.h or 0

	if total_items <= 0 then
		return track_height
	end

	if visible_items >= total_items then
		return track_height
	end

	local raw = (visible_items * track_height) / total_items
	local h = _floor(raw + 0.5)
	if h < 1 then h = 1 end
	if h > track_height then h = track_height end
	return h
end

local function Scrollbar_getMaxSliderOffset(self)
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return 0 end
	local slider_height = self:getSliderHeight()
	return _max(0, track_height - slider_height)
end

local function Scrollbar_getSliderOffset(self)
	local max_offset = self:getMaxSliderOffset()
	if max_offset == 0 then return 0 end

	local scrollmax = self.obj:getScrollMaxY()
	if scrollmax <= 0 then return 0 end

	local pos = self.obj:getScrollPosY()
	pos = clamp(pos, 0, scrollmax)
	local frac = pos / scrollmax

	return clamp(_floor(frac * max_offset + 0.5), 0, max_offset)
end

local function Scrollbar_onMouseDown(self, btn, x, y)
	if self:checkIn(x, y) then
		self.dirty = true
		return true
	end

	if self:isOnSlider(y) then
		self.held = 2
		self.drag_offset = y - self:getSliderOffset() - self.y - 1
		return true
	end

	local track_top = self.y + 1
	local track_height = self:getTrackHeight()
	if track_height <= 0 then return true end

	local slider_height = self:getSliderHeight()
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxY()

	local click_rel = clamp(y - track_top, 0, track_height - 1)

	-- Центруємо: ставимо центр слайдера на місце кліка
	local half = (slider_height - 1) / 2        -- може бути .5 для парної висоти
	local desired_offset_f = click_rel - half  -- дробовий бажаний offset
	local desired_offset = _floor(desired_offset_f + 0.5) -- округлюємо до найближчого
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = 0
	if max_offset > 0 then
		frac = desired_offset / max_offset
	end
	local pos = _floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosY(pos)

	return true
end

local function Scrollbar_onMouseDrag(self, btn, x, y)
	if self.held == 1 or self.held == 3 then return end
	local track_top = self.y + 1
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxY()

	local desired_offset = _floor((y - track_top) - self.drag_offset + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = desired_offset / max_offset
	local pos = _floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosY(pos)

	return true
end

---Creating new *object* of *class* "scrollbar" which connected at another *object*
---@param obj table *object*
---@return table return scrollbar
function UI.New_Scrollbar(obj)
	expect(1, obj, "table")

	local instance = New_Widget(obj.x + obj.w, obj.y, 1, obj.h, obj.color_bg, obj.color_txt)
	instance.obj = obj
	instance.held = 0  -- 0: none, 1: up arrow, 2: slider, 3: down arrow
	instance.drag_offset = 0
	if obj.attachScrollbar then
		obj:attachScrollbar(instance, "vertical")
	end

	instance.draw = Scrollbar_draw
	instance.setObj = Scrollbar_setObj
	instance.getTrackHeight = Scrollbar_getTrackHeight
	instance.getSliderHeight = Scrollbar_getSliderHeight
	instance.getMaxSliderOffset = Scrollbar_getMaxSliderOffset
	instance.getSliderOffset = Scrollbar_getSliderOffset
	instance.checkIn = Scrollbar_checkIn
	instance.isOnSlider = Scrollbar_isOnSlider
	instance.onMouseDown = Scrollbar_onMouseDown
	instance.onMouseDrag = Scrollbar_onMouseDrag
	instance.onMouseUp = Scrollbar_onMouseUp
	instance.onMouseScroll = Scrollbar_onMouseScroll

	return instance
end

local function Scrollbar_H_getSliderWidth(self)
		local track_width = self:getTrackWidth()
		if track_width <= 0 then return 0 end

		local total_width = self.obj:getScrollMaxX() + self.obj.w
		local visible_width = self.obj.w or 0

		if total_width <= 0 or visible_width >= total_width then
			return track_width
		end

		local raw = (visible_width * track_width) / total_width
		local w = math.floor(raw + 0.5)
		if w < 1 then w = 1 end
		if w > track_width then w = track_width end
		return w
	end

local function Scrollbar_H_getSliderOffset(self)
		local max_offset = self:getMaxSliderOffset()
		if max_offset == 0 then return 0 end

		local scrollmax = self.obj:getScrollMaxX()
		if scrollmax <= 0 then return 0 end

		local pos = self.obj:getScrollPosX()
		pos = clamp(pos, 0, scrollmax)
		local frac = scrollmax > 0 and (pos / scrollmax) or 0
		return clamp(_floor(frac * max_offset + 0.5), 0, max_offset)
end

local function Scrollbar_H_getTrackWidth(self)
	return self.w - 2  -- Минус две стрелки
end

local function Scrollbar_H_getMaxSliderOffset(self)
	local track_width = self:getTrackWidth()
	if track_width <= 0 then return 0 end
	local slider_width = self:getSliderWidth()
	return _max(0, track_width - slider_width)
end

local function Scrollbar_H_onMouseDown(self, btn, x, y)
	-- Левая стрелка
	if x == self.x then
		self.held = 1
		self.dirty = true
		return true
	-- Правая стрелка
	elseif x == self.x + self.w - 1 then
		self.held = 3
		self.dirty = true
		return true
	end

	-- На слайдере
	if self:isOnSlider(x) then
		self.held = 2
		local slider_offset = self:getSliderOffset()
		local slider_x_start = self.x + 1 + slider_offset
		self.drag_offset = x - slider_x_start
		self.dirty = true
		return true
	end

	-- Клик на трек
	local track_left = self.x + 1
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxX()

	if scrollmax <= 0 or max_offset == 0 then
		return true
	end

	local slider_width = self:getSliderWidth()
	local click_rel = clamp(x - track_left, 0, self:getTrackWidth() - 1)
	local half = (slider_width - 1) / 2
	local desired_offset = _floor(click_rel - half + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = max_offset > 0 and (desired_offset / max_offset) or 0
	local pos = _floor(frac * scrollmax + 0.5)
	self.obj:setScrollPosX(pos)

	self.dirty = true
	return true
end

local function Scrollbar_H_onMouseUp(self, btn, x, y)
	if self.held == 1 and self:check(x, y) and x == self.x then
		self.obj:scrollX(-1)
	elseif self.held == 3 and self:check(x, y) and x == self.x + self.w - 1 then
		self.obj:scrollX(1)
	end
	self.held = 0
	self.dirty = true
	return true
end

local function Scrollbar_H_onMouseDrag(self, btn, x, y)
	if self.held == 1 or self.held == 3 then return end
	local track_left = self.x + 1
	local max_offset = self:getMaxSliderOffset()
	local scrollmax = self.obj:getScrollMaxX()

	local desired_offset = _floor((x - track_left) - self.drag_offset + 0.5)
	desired_offset = clamp(desired_offset, 0, max_offset)

	local frac = desired_offset / max_offset
	local pos = _floor(frac * scrollmax + 0.5)

	self.obj:setScrollPosX(pos)

	return true
end

local function Scrollbar_H_onMouseScroll(self, dir, x, y)
	if self:check(x, y) then
		self.obj:scrollX(dir)
		return true
	end
	return false
end

local function Scrollbar_H_isOnSlider(self, x)
	local slider_offset = self:getSliderOffset()
	local slider_width = self:getSliderWidth()
	local slider_x_start = self.x + 1 + slider_offset
	return x >= slider_x_start and x <= slider_x_start + slider_width - 1
end

local function Scrollbar_H_draw(self)
	local slider_width = self:getSliderWidth()
	local slider_offset = self:getSliderOffset()
	local slider_x_start = self.x + 1 + slider_offset

	-- Фон трека
	term.setBackgroundColor(self.color_bg)
	for x = self.x + 1, slider_x_start - 1 do
		term.setCursorPos(x, self.y)
		term.write(" ")
	end
	for x = slider_x_start + slider_width, self.x + self.w - 2 do
		term.setCursorPos(x, self.y)
		term.write(" ")
	end

	-- Стрелка влево
	local left_bg, left_fg = (self.held == 1 and self.color_txt or self.color_bg), (self.held == 1 and self.color_bg or self.color_txt)
	term.setBackgroundColor(left_bg)
	term.setCursorPos(self.x, self.y)
	term.setTextColor(left_fg)
	term.write(string_char(17))

	-- Стрелка вправо
	local right_bg, right_fg = (self.held == 3 and self.color_txt or self.color_bg), (self.held == 3 and self.color_bg or self.color_txt)
	term.setBackgroundColor(right_bg)
	term.setCursorPos(self.x + self.w - 1, self.y)
	term.setTextColor(right_fg)
	term.write(string_char(16))

	-- Ползунок
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	for x = slider_x_start, _min(slider_x_start + slider_width - 1, self.x + self.w - 2) do
		term.setCursorPos(x, self.y)
		term.write(string_char(140))  -- Filled pixel
	end
end

---Creating new *object* of *class* "scrollbar_horizontal" which connected at another *object*
---@param obj table *object*
---@return table return scrollbar_horizontal
function UI.New_Scrollbar_Horizontal(obj)
	expect(1, obj, "table")

	local instance = New_Widget(obj.x, obj.y + obj.h, obj.w, 1, obj.color_bg, obj.color_txt)
	instance.obj = obj
	instance.orientation = "horizontal"
	instance.held = 0
	instance.drag_offset = 0
	if obj.attachScrollbar then
		obj:attachScrollbar(instance, "horizontal")
	end

	instance.draw = Scrollbar_H_draw
	instance.getSliderWidth = Scrollbar_H_getSliderWidth
	instance.getSliderOffset = Scrollbar_H_getSliderOffset
	instance.getTrackWidth = Scrollbar_H_getTrackWidth
	instance.getMaxSliderOffset = Scrollbar_H_getMaxSliderOffset
	instance.onMouseDown = Scrollbar_H_onMouseDown
	instance.onMouseUp = Scrollbar_H_onMouseUp
	instance.onMouseDrag = Scrollbar_H_onMouseDrag
	instance.onMouseScroll = Scrollbar_H_onMouseScroll
	instance.isOnSlider = Scrollbar_H_isOnSlider

	return instance
end


local function List_draw(self)
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	for i = self.scroll.pos_y + 1, _min(self.h + self.scroll.pos_y, #self.array) do
		local index_arr = self.array[i]
		term.setCursorPos(self.x, (i - self.scroll.pos_y - 1) + self.y)
		term.write(_sub(index_arr.._rep(" ", self.w - #index_arr), 1, self.w))
	end
	if self.item and self.item_index then
		if (self.y + self.item_index - self.scroll.pos_y - 1) >= self.y and (self.y + self.item_index - self.scroll.pos_y - 1) <= (self.h + self.y - 1) then
			term.setBackgroundColor(self.color_txt)
			term.setTextColor(self.color_bg)
			term.setCursorPos(self.x, self.y + self.item_index - self.scroll.pos_y - 1)
			term.write(_sub(self.item.._rep(" ",self.w - #self.item), 1, self.w))
		end
	end
	if self.h > #self.array then
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_txt)
		for i = #self.array, self.h - 1 do
			term.setCursorPos(self.x, i + self.y)
			term.write(_sub(_rep(" ", self.w), 1, self.w))
		end
	end
end

local function List_updateArr(self, array)
	self.array = array
	self.item = nil
	self.item_index = nil
	self:updateDirty()
end

local function List_onMouseScroll(self, dir, x, y)
	return self:scrollY(dir)
end

local function List_onFocus(self, focused)
	if not focused then
		self.item = nil
		self.item_index = nil
		self.dirty = true
	end
	return true
end

local function List_onMouseDown(self, btn, x, y)
	local i = y - self.y + 1 + self.scroll.pos_y
	if i <= #self.array then
		if self.item and self.item == self.array[i] then
			self:pressed(self.item, self.item_index)
		elseif not self.item or self.item ~= self.array[i] then
			self.item = self.array[i]
			self.item_index = i
		end
		self.dirty = true
	end
	return true
end

local function List_onKeyDown(self, key, held)
	if self.item then
		if key == keys.up then
			self.item_index = _max(self.item_index - 1, 1)
			self.item = self.array[self.item_index]
			if self.item_index <= self.scroll.pos_y then
				self:scrollY(-(1/self.scroll.sensitivity_y))
			end
		elseif key == keys.down then
			self.item_index = _min(self.item_index + 1, #self.array)
			self.item = self.array[self.item_index]
			if self.item_index > _min(self.h + self.scroll.pos_y, #self.array) then
				self:scrollY(1/self.scroll.sensitivity_y)
			end
		elseif key == keys.home then
			self.scroll.pos_y = 0
			self.item_index = 1
			self.item = self.array[self.item_index]
		elseif key == keys['end'] then
			self.scroll.pos_y = self.scroll.max_y
			self.item_index = #self.array
			self.item = self.array[self.item_index]
		end
		self:updateDirty()
	end
	return true
end

local function List_updateDirty(self)
	if self.scrollbar_v then
		self.scrollbar_v.dirty = true
	end
	if self.scrollbar_h then
		self.scrollbar_h.dirty = true
	end
	self.dirty = true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param array table|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object list
function UI.New_List(x, y, w, h, array, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, array, "table", "nil")
	expect(6, color_bg, "number", "nil")
	expect(7, color_txt, "number", "nil")

	local instance = New_Widget(x, y, w, h, color_bg, color_txt)
	add_mixin(instance, ScrollableMixin)
	instance:initScroll(3, 3)
	instance.array = array
	instance.item = nil
	instance.item_index = nil
	function instance:getScrollMaxY()
		return _max(0, #self.array - self.h)
	end

	instance.draw = List_draw
	instance.updateArr = List_updateArr
	instance.pressed = pressed
	instance.onMouseScroll = List_onMouseScroll
	instance.onFocus = List_onFocus
	instance.onMouseDown = List_onMouseDown
	instance.onKeyDown = List_onKeyDown
	instance.updateDirty = List_updateDirty

	return instance
end

local function Textfield_draw(self)
	term.setBackgroundColor(self.color_bg)
	term.setCursorPos(self.x, self.y)
	local text = self.text
	if self.hidden == true then
		text = _rep("*", #self.text)
	end
	if self.root.focus ~= self and #self.text == 0 and #self.hint <= self.w then
		term.setTextColor(colors.lightGray)
		term.write(self.hint.._rep(" ", self.w - #self.hint))
		return
	end
	term.setTextColor(self.color_txt)
	term.write(_sub(text, self.offset + 1, _min(#self.text, self.offset + self.w)).._rep(" ", self.w - #self.text + self.offset))
end

local function Textfield_focusPostDraw(self)
	term.setTextColor(colors.blue)
	local x = self.x + self.cursor_x - self.offset - 1
	term.setCursorPos(x, self.y)
	if x < self.x or x > self.x + self.w - 1 then
		term.setCursorBlink(false)
	else
		term.setCursorBlink(true)
	end
end

local function Textfield_moveCursorPos(self, pos)
	self.cursor_x = _min(_max(pos, 1), #self.text + 1)
	if self.cursor_x - self.offset > self.w then
		self.offset = self.cursor_x - self.w
	elseif self.cursor_x - self.offset < 1 then
		self.offset = self.cursor_x - 1
	end
end

local function Textfield_onMouseScroll(self, dir, x, y)
	local old_offset = self.offset
	self.offset = _max(0, _min(#self.text - self.w + 1, self.offset - dir))
	if self.offset ~= old_offset then
		self.dirty = true
		return true
	end
	return false
end

local function Textfield_onMouseUp(self, btn, x, y)
	if not self:check(x, y) then
		self.dirty = true
	end
	return true
end

local function Textfield_onFocus(self, focused)
	if focused and bOS.monitor[1] and bOS.monitor[2] then
		self.root:addChild(self.root.keyboard)
		self.root.keyboard:onLayout()
	elseif not focused and bOS.monitor[1] and bOS.monitor[2] then
		self.root:removeChild(self.root.keyboard)
	end
	term.setCursorBlink(focused)
	self.dirty = true
	return true
end

local function Textfield_onMouseDown(self, btn, x, y)
	self:moveCursorPos(x - self.x + 1 + self.offset)
	return true
end

local function Textfield_onCharTyped(self, chr)
	self.text = _sub(self.text, 1, self.cursor_x - 1)..chr.._sub(self.text, self.cursor_x, #self.text)
	self:moveCursorPos(self.cursor_x + 1)
	self.dirty = true
	return true
end

local function Textfield_onPaste(self, text)
	self.text = _sub(self.text, 1, self.cursor_x - 1)..text.._sub(self.text, self.cursor_x, #self.text)
	self:moveCursorPos(self.cursor_x + #text)
	self.dirty = true
	return true
end

local function Textfield_onKeyDown(self, key, held)
	if key == keys.backspace then
		self.text = _sub(self.text, 1, _max(self.cursor_x - 2, 0)).._sub(self.text, self.cursor_x, #self.text)
		self.offset = _max(self.offset - 1, 0)
		self:moveCursorPos(self.cursor_x - 1)
	elseif key == keys.delete then
		self.text = _sub(self.text, 1, self.cursor_x - 1) .. _sub(self.text, self.cursor_x + 1, #self.text)
	elseif key == keys.left then
		self:moveCursorPos(self.cursor_x - 1)
	elseif key == keys.right then
		self:moveCursorPos(self.cursor_x + 1)
	elseif key == keys.enter then
		self:pressed()
	end
	self.dirty = true
	return true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param hint string|nil
---@param hidden boolean|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object Textfield
function UI.New_Textfield(x, y, w, h, hint, hidden, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, hint, "string", "nil")
	expect(6, hidden, "boolean", "nil")
	expect(7, color_bg, "number", "nil")
	expect(8, color_txt, "number", "nil")

	local instance = New_Widget(x, y, w, h, color_bg, color_txt)
	instance.offset = 0
	instance.hint = hint or "Type here"
	instance.text = ""
	instance.cursor_x = #instance.text + 1
	instance.hidden = hidden or false

	instance.draw = Textfield_draw
	instance.moveCursorPos = Textfield_moveCursorPos
	instance.onMouseScroll = Textfield_onMouseScroll
	instance.onMouseUp = Textfield_onMouseUp
	instance.onFocus = Textfield_onFocus
	instance.pressed = pressed
	instance.focusPostDraw = Textfield_focusPostDraw
	instance.onMouseDown = Textfield_onMouseDown
	instance.onCharTyped = Textfield_onCharTyped
	instance.onPaste = Textfield_onPaste
	instance.onKeyDown = Textfield_onKeyDown

	return instance
end

local function delete_selected_text(self)
	if self.selected.status and self.lines[1] then
		local p1 = self.selected.pos1
		local p2 = self.selected.pos2
		local s, e = p1, p2
		if p1.y > p2.y or (p1.y == p2.y and p1.x > p2.x) then
			s, e = p2, p1 -- то, что я пытался сделать, но мозгов не хватило, Увы
		end
		local string = ""
		for i = s.y, e.y do
			local line_str = self.lines[s.y] or ""
			if s.y == i then
				string = string .. _sub(line_str, 1, s.x - 1)
			end
			if e.y == i then
				string = string .. _sub(line_str, e.x + 1, #line_str)
			end
			table.remove(self.lines, s.y)
		end
		table.insert(self.lines, s.y, string)
		self:moveCursorPos(s.x, s.y)
		self.selected.status = false
		return true
	end
	return false
end

local function select_text(self, new_x, new_y)
	local oX = self.click_pos.x
	local oY = self.click_pos.y
	local p1 = self.selected.pos1
	local p2 = self.selected.pos2
	local max_lines = #self.lines
	local nY = _max(1, _min(max_lines + 1, new_y))
	local current_line = #self.lines[_min(max_lines, nY)]
	local nX = _max(1, _min(current_line, new_x))
	self:moveCursorPos(nX, nY)
	if (nX < oX and nY == oY) or nY < oY then
		p1.x = self.cursor.x
		p2.x = oX
		p1.y = self.cursor.y
		p2.y = oY
	else
		p1.x = oX
		p2.x = self.cursor.x
		p1.y = oY
		p2.y = self.cursor.y
	end
	self.selected.status = true
	self.dirty = true
end

local function clipboard_paste(self)
	delete_selected_text(self)
	local paste = clipboard.paste()
	local y = self.cursor.y
	local lines = self.lines
	local t_line = self.lines[self.cursor.y]
	local i = 0
	local ostatok
	for line in paste:gmatch("[^\n]+") do
		if i == 0 then
			ostatok = _sub(t_line, self.cursor.x, #t_line)
			t_line = _sub(t_line, 1, self.cursor.x - 1)..line
			self:setLine(t_line, y)
		else
			table.insert(lines, y + i, line)
		end
		i = i + 1
	end
	local prev_line = lines[y + i - 1]
	lines[y + i - 1] = _sub(prev_line, 1, #prev_line)..ostatok
	self:moveCursorPos(#prev_line + 1, y + i - 1)
	self.dirty = true
end

local function TextBox_draw(self)
	paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.color_bg)

	local start_line = self.scroll.pos_y + 1
	local end_line = _min(self.h + self.scroll.pos_y, #self.lines)

	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)

	for i = start_line, end_line do
		local str = self.lines[i] or ""
		local visible_str = _sub(str, self.scroll.pos_x + 1, self.scroll.pos_x + self.w)
		term.setCursorPos(self.x, self.y + (i - self.scroll.pos_y) - 1)
		term.write(visible_str)
	end

	if self.selected.status then
		local p1 = self.selected.pos1
		local p2 = self.selected.pos2
		term.setBackgroundColor(colors.blue)
		term.setTextColor(colors.white)
		for i = p1.y, p2.y do
			local line_str = self.lines[i] or ""
			local sel_x_start = 1
			local sel_x_end = #line_str
			if i == p1.y then
				sel_x_start = p1.x
			end
			if i == p2.y then
				sel_x_end = p2.x
			end
			if sel_x_start <= sel_x_end + 1 then
				local sel_text = _sub(line_str, sel_x_start, sel_x_end)
				if #line_str == 0 and i ~= p2.y and i ~= p1.y then sel_text = " " end
				local draw_x = self.x + (sel_x_start - 1) - self.scroll.pos_x
				local draw_y = self.y + (i - self.scroll.pos_y) - 1
				term.setCursorPos(draw_x, draw_y)
				term.write(sel_text)
			end
		end
	end
end

local function TextBox_setLine(self, line, number)
	self.lines[number] = line
	self:updateDirty()
end

local function TextBox_moveCursorPos(self, posX, posY)
	local current_lines = self.lines[self.cursor.y]
	posX = clamp(posX, 1, #(current_lines or "") + 1)
	posY = clamp(posY, 1, #self.lines)

	self.cursor.y = posY
	if self.cursor.y - self.scroll.pos_y > self.h then
		self:setScrollPosY(self.cursor.y - self.h)
	elseif self.cursor.y - self.scroll.pos_y < 1 then
		self:setScrollPosY(self.cursor.y - 1)
	end

	local l_start, l_end = string.find(_sub(current_lines, 1, self.cursor.x), '\t', self.cursor.x - self.TabSize)
	local r_start, r_end = string.find(_sub(current_lines, self.cursor.x, #current_lines), '\t', self.cursor.x)
	l_end = l_start and l_end + self.TabSize - 1
	r_end = r_start and r_end + self.TabSize - 1
	-- dbg.print("L_START: "..tostring(l_start).." ".. "L_END: "..tostring(l_end))
	-- dbg.print("R_START: "..tostring(r_start).." ".. "R_END: "..tostring(r_end))
	if l_start and (l_start >= posX or l_end <= posX) then
		self.cursor.x = l_start
	elseif r_start and (r_start > posX or r_end <= posX) then
		self.cursor.x = r_end
	else
		self.cursor.x = posX
	end
	-- self.cursor.x = start and s_end or posX

	if self.cursor.x - self.scroll.pos_x > self.w then
		self:setScrollPosX(self.cursor.x - self.w)
	elseif self.cursor.x - self.scroll.pos_x < 1 then
		self:setScrollPosX(self.cursor.x - 1)
	end

	-- line_str = _sub(line_str, 1, self.cursor.x)
	-- if _sub(line_str, self.cursor.x - 1, self.cursor.x - 1) == '\t' then
	-- 	self.cursor.x = clamp(self.cursor.x + self.TabSize - 1, 1, #(self.lines[self.cursor.y] or "") + 1)
	-- else
	-- 	if start then
	-- 		self.cursor.x = clamp(start, 1, #(self.lines[self.cursor.y] or "") + 1)
	-- 	end
	-- end
end

local function TextBox_clear(self)
	self.lines = {""}
	self.cursor = {x = 1, y = 1}
	self.scroll.pos_y = 0
	self.scroll.pos_x = 0
	self.dirty = true
end

local function TextBox_focusPostDraw(self)
	local x = self.x - self.scroll.pos_x + self.cursor.x - 1
	local y = self.y - self.scroll.pos_y + self.cursor.y - 1
	term.setCursorPos(x, y)
	term.setTextColor(colors.blue)
	if (x < self.x or x > self.x + self.w - 1) or (y < self.y or y > self.y + self.h - 1) then
		term.setCursorBlink(false)
	else
		term.setCursorBlink(true)
	end
end

local function TextBox_onFocus(self, focused)
	term.setCursorBlink(focused)
	if not focused then
		self.selected.status = false
		self.dirty = true
	end
end

local function TextBox_onCharTyped(self, chr)
	delete_selected_text(self)
	local y = self.cursor.y
	local x = self.cursor.x
	local line = self.lines[y]
	line = line or ""
	self.lines[y] = _sub(line, 1, x - 1)..chr.._sub(line, x, #line)
	self:moveCursorPos(x + #chr, y)
	self.dirty = true
	return true
end

local function TextBox_onMouseDown(self, btn, x, y)
	self:moveCursorPos(x - self.x + self.scroll.pos_x + 1, y - self.y + self.scroll.pos_y + 1)
	local cx, cy = self.cursor.x, self.cursor.y
	self.click_pos = {x = cx, y = cy}
	self.selected.pos1 = {x = cx, y = cy}
	self.selected.pos2 = {x = cx, y = cy}
	self.selected.status = false
	self.dirty = true
	return true
end

local function TextBox_onMouseDrag(self, btn, x, y)
	local click_pos = self.click_pos
	local nY = y - self.y + 1 + self.scroll.pos_y
	local nX = x - self.x + 1 + self.scroll.pos_x
	if nY < 1 then return false end
	click_pos.x = click_pos.x or nX
	click_pos.y = click_pos.y or nY
	select_text(self, nX, nY)
	return true
end

local function TextBox_onMouseScroll(self, dir, x, y)
	if self.shift_held then
		return self:scrollX(dir)
	end
	return self:scrollY(dir)
end

local function TextBox_onKeyUp(self, key)
	if key == keys.leftShift then
		self.shift_held = false
	end
	if key == keys.leftCtrl then
		self.ctrl_held = false
	end
	return true
end

local function TextBox_onKeyDown(self, key, held)
	local y = self.cursor.y
	local line = self.lines[y] or ""
	if key == keys.backspace then
		if delete_selected_text(self) then self:updateDirty() return true end
		if _sub(line, 1, self.cursor.x - 1) == "" and self.lines[y - 1] then
			self:moveCursorPos(#self.lines[y - 1] + 1, y - 1)
			self.lines[y - 1] = self.lines[y - 1] .. line
			table.remove(self.lines, y)
			self:setScrollPosX(_max(self.scroll.pos_x - 1, 0))
		else
			self.lines[y] = _sub(line, 1, _max(self.cursor.x - 2, 0)).._sub(line, self.cursor.x, #line)
			self:setScrollPosX(_max(self.scroll.pos_x - 1, 0))
			self:moveCursorPos(self.cursor.x - 1, y)
		end
	elseif key == keys.delete then
		if delete_selected_text(self) then self:updateDirty() return true end
		if self.cursor.x > #line and self.lines[y + 1] then
			self.lines[y] = line .. self.lines[y + 1]
			table.remove(self.lines, y + 1)
			self:setScrollPosX(_max(self.scroll.pos_x - 1, 0))
		else
			self.lines[y] = _sub(line, 1, self.cursor.x - 1) .. _sub(line, self.cursor.x + 1, #line)
		end
	elseif key == keys.left then
		self:moveCursorPos(self.cursor.x - 1, y)
		if self.shift_held then
			local a = self.cursor.x
			if not self.selected.status then a = a + 1 end
			select_text(self, a, self.cursor.y)
		end
		if not self.shift_held then self.selected.status = false end
	elseif key == keys.right then
		self:moveCursorPos(self.cursor.x + 1, y)
		if self.shift_held then
			local a = self.cursor.x
			if not self.selected.status then a = a - 1 end
			select_text(self, a, self.cursor.y)
		end
		if not self.shift_held then self.selected.status = false end
	elseif key == keys.c and self.ctrl_held then
		local peremennaya = {}
		for i = self.selected.pos1.y, self.selected.pos2.y do
			table_insert(peremennaya, self.lines[i])
		end
		peremennaya[#peremennaya] = _sub(peremennaya[#peremennaya], 1, self.selected.pos2.x)
		peremennaya[1] = _sub(peremennaya[1], self.selected.pos1.x, #peremennaya[1])
		clipboard.copy(peremennaya)
		return true
	elseif key == keys.v and self.ctrl_held then
		clipboard_paste(self)
	elseif key == keys.a and self.ctrl_held then
		local p1, p2 = self.selected.pos1, self.selected.pos2
		local all_lines = #self.lines
		local last_line = self.lines[all_lines]
		p1.x, p1.y = 1, 1
		p2.x, p2.y = #last_line, all_lines
		self.selected.status = true
		self.cursor.x, self.cursor.y = p2.x + 1, p2.y
	elseif key == keys.up then
		self:moveCursorPos(self.cursor.x, y - 1)
		if self.shift_held then select_text(self, self.cursor.x, self.cursor.y) end
		if not self.shift_held then self.selected.status = false end
	elseif key == keys.down then
		self:moveCursorPos(self.cursor.x, y + 1)
		if self.shift_held then select_text(self, self.cursor.x, self.cursor.y) end
		if not self.shift_held then self.selected.status = false end
	elseif key == keys.leftShift and not held then
		if not self.selected.status then
			local cx, cy = self.cursor.x, self.cursor.y
			self.click_pos = {x = cx, y = cy}
			self.selected.pos1 = {x = cx, y = cy}
			self.selected.pos2 = {x = cx, y = cy}
		end
		self.shift_held = true
	elseif key == keys.leftCtrl and not held then
		self.ctrl_held = true
	elseif key == keys.enter then
		if delete_selected_text(self) then self:updateDirty() return true end
		table_insert(self.lines, y + 1, _sub(line, self.cursor.x, #line))
		self:setLine(_sub(line, 1, self.cursor.x - 1), y)
		self:moveCursorPos(1, y + 1)
	elseif key == keys.tab then
		self:onCharTyped('\t' .. _rep(" ", self.TabSize - 1))
	elseif key == keys.pageDown then
		self:scrollY(self.h / self.scroll.sensitivity_y)
		self.selected.status = false
	elseif key == keys.pageUp then
		self:scrollY(-self.h / self.scroll.sensitivity_y)
		self.selected.status = false
	elseif key == keys.home then
		self:moveCursorPos(1, y)
		self.selected.status = false
	elseif key == keys["end"] then
		self:moveCursorPos(#line + 1, y)
		self.selected.status = false
	end
	self:updateDirty()
	return true
end

function TextBox_onPaste(self)
	clipboard_paste(self)
	return true
end

function UI.New_TextBox(x, y, w, h, color_bg, color_txt)
	local instance = New_Widget(x, y, w, h, color_bg, color_txt)
	add_mixin(instance, ScrollableMixin)
	instance:initScroll(3, 3)
	instance.TabSize = 4
	instance.lines = {""}
	instance.cursor = {x = 1, y = 1}
	instance.click_pos = {}
	instance.selected = {
		status = false,
		pos1 = {x = 1, y = 1},
		pos2 = {x = 1, y = 1}
	}

	function instance:getScrollMaxX()
		return c.findMaxLenStrOfArray(self.lines) - self.w
	end
	function instance:getScrollMaxY()
		return _max(0, #self.lines - self.h)
	end

	instance.draw = TextBox_draw
	instance.setLine = TextBox_setLine
	instance.onCharTyped = TextBox_onCharTyped
	instance.moveCursorPos = TextBox_moveCursorPos
	instance.onMouseDown = TextBox_onMouseDown
	instance.focusPostDraw = TextBox_focusPostDraw
	instance.onFocus = TextBox_onFocus
	instance.onMouseScroll = TextBox_onMouseScroll
	instance.onKeyUp = TextBox_onKeyUp
	instance.onKeyDown = TextBox_onKeyDown
	instance.clear = TextBox_clear
	instance.updateDirty = List_updateDirty
	instance.onPaste = TextBox_onPaste
	instance.onMouseDrag = TextBox_onMouseDrag
	--instance.onMouseUp = TextBox_onMouseUp

	return instance
end

local function Checkbox_draw(self)
	local bg_override, txtcol_override = self.color_bg, self.color_txt
	if self.held then
		bg_override, txtcol_override = self.color_txt, self.color_bg
	end
	term.setBackgroundColor(bg_override)
	term.setTextColor(txtcol_override)
	term.setCursorPos(self.x, self.y)
	if self.on then
		term.write("x")
	else
		term.write(" ")
	end
end

local function Checkbox_onMouseUp(self,btn, x, y)
	if self:check(x, y) then
		self:pressed()
		self.on = not self.on
	end
	self.held = false
	self.dirty = true
	return true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param on boolean|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object checkbox
function UI.New_Checkbox(x, y, on, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, on, "boolean", "nil")
	expect(4, color_bg, "number", "nil")
	expect(5, color_txt, "number", "nil")

	local instance = New_Widget(x, y, 1, 1, color_bg, color_txt)
	instance.on = on or false

	instance.draw = Checkbox_draw
	instance.pressed = pressed
	instance.onMouseDown = Button_onMouseDown
	instance.onMouseUp = Checkbox_onMouseUp

	return instance
end

local function Clock_updateSize(self)
	local len = #os.date(self.format)
	self.w, self.h = len, 1
end

local function Clock_draw(self)
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	term.setCursorPos(self.x, self.y)
	term.write(self.time)
end

local function Clock_updateTime(self)
	self.time = os.date(self.format)
	if type(self.time) ~= "string" then
		self.time = os.date("%H:%M")
	end
	self.timer = os.startTimer(self.updt_rate)
	self.dirty = true
end

local function Clock_setFormat(self, Show_seconds, Is_24h)
	expect(1, Show_seconds, "boolean", "nil")
	expect(2, Is_24h, "boolean", "nil")

	self.show_seconds = Show_seconds ~= false
	self.is_24h = Is_24h ~= false
	updateFormat()
	self.time = os.date(self.format)
	self:updateSize()
	self.dirty = true
	if self.parent then
		self.parent:onLayout()
	end
end

local function Clock_onEvent(self, evt)
	if evt[1] == "timer" and evt[2] == self.timer then
		self:updateTime()
		return true
	end
	onEvent(self, evt)
end

local function LoadingBar_setValue(self, value)
	if value > 1 or value < 0 then return error("Value may be between 0 and 1 (1 = 100%)") end
	self.value = value
	self:draw()
	-- screen.update()
end

local function LoadingBar_draw(self)
	local LoadX = math.floor(self.value * self.w)
	if self.orientation == "top" then
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_Loading)
		term.setCursorPos(self.x, self.y)
		term.write(_rep(string_char(131), LoadX))
		term.setTextColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(_rep(string_char(131), self.w - LoadX))
	elseif self.orientation == "center"  then
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_Loading)
		term.setCursorPos(self.x, self.y)
		term.write(_rep(string_char(140), LoadX))
		term.setTextColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(_rep(string_char(140), self.w - LoadX))
	elseif self.orientation == "bottom"  then
		term.setBackgroundColor(self.color_Loading)
		term.setTextColor(self.color_bg)
		term.setCursorPos(self.x, self.y)
		term.write(_rep(string_char(143), LoadX))
		term.setBackgroundColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(_rep(string_char(143), self.w - LoadX))
	elseif self.orientation == "filled"  then
		term.setBackgroundColor(self.color_Loading)
		term.setTextColor(self.color_bg)
		term.setCursorPos(self.x, self.y)
		term.write(_rep(" ", LoadX))
		term.setBackgroundColor(self.color_NotLoaded)
		term.setCursorPos(self.x + LoadX, self.y)
		term.write(_rep(" ", self.w - LoadX))
	end
end

---@param orientation "center"|"top"|"bottom"|"filled"
function UI.New_LoadingBar(x, y, w, color_bg, color_Loading, color_NotLoaded, orientation, defaultValue)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	assert(defaultValue and defaultValue >= 0 and defaultValue <= 1, "expecteded argument #6 in range 0-1")

	local instance = New_Widget(x, y, w, 1, color_bg, color_txt)
	instance.orientation = orientation or "center"
	instance.color_bg = color_bg or colors.black
	instance.color_Loading = color_Loading or colors.white
	instance.color_NotLoaded = color_NotLoaded or colors.gray
	instance.value = defaultValue

	instance.draw = LoadingBar_draw
	instance.setValue = LoadingBar_setValue

	return instance
end


---Creating new *object* of *class*
---@param x number
---@param y number
---@param show_seconds boolean|nil
---@param is_24h boolean|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object clock
function UI.New_Clock(x, y, show_seconds, is_24h, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, show_seconds, "boolean", "nil")
	expect(4, is_24h, "boolean", "nil")
	expect(5, color_bg, "number", "nil")
	expect(6, color_txt, "number", "nil")

	local instance = New_Widget(x, y, _, _, color_bg, color_txt)
	instance.show_seconds = show_seconds ~= false
	instance.is_24h = is_24h ~= false
	instance.updt_rate = 1

	local function updateFormat()
		if instance.is_24h then
			instance.format = instance.show_seconds and "%H:%M:%S" or "%H:%M"
		else
			instance.format = instance.show_seconds and "%I:%M:%S %p" or "%I:%M %p"
		end
	end

	updateFormat()
	instance.time = os.date(instance.format)
	instance.timer = os.startTimer(instance.updt_rate)
	instance.dirty = true

	instance.updateSize = Clock_updateSize
	instance:updateSize()
	instance.draw = Clock_draw
	instance.updateTime = Clock_updateTime
	instance.setFormat = Clock_setFormat
	instance.onEvent = Clock_onEvent

	return instance
end

local function Dropdown_draw(self)
	local index_arr = self.array[self.item_index]
	if self.orientation == "left" then
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_txt)
		term.setCursorPos(self.x, self.y)
		term.write(_sub((index_arr), 1, self.w - 1).._rep(" ", self.w - 1 - #index_arr)..string_char(31))
		if self.expanded then
			for i, v in pairs(self.array) do
				term.setBackgroundColor(self.color_bg)
				term.setTextColor(self.color_txt)
				term.setCursorPos(self.x, self.y + i)
				term.write(_sub((v.._rep(" ", self.w - #v)), 1, self.w))
			end
			term.setBackgroundColor(self.color_bg)
			term.setTextColor(self.color_txt)
			term.setCursorPos(self.x, self.y)
			term.write(_sub((index_arr), 1, self.w - 1).._rep(" ", self.w - 1 - #index_arr)..string_char(30))
			self.h = #self.array + 1
		else
			self.h = 1
		end
	elseif self.orientation == "right" then
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_txt)
		term.setCursorPos(self.x, self.y)
		term.write(_sub(index_arr.._rep(" ", self.w - 1 - #index_arr)..string_char(30), 1, self.w))
		if self.expanded then
			for i, v in pairs(self.array) do
				term.setBackgroundColor(self.color_bg)
				term.setTextColor(self.color_txt)
				term.setCursorPos(self.x, self.y + i)
				term.write(_sub(_rep(" ", self.w - #v)..v, 1, self.w))
			end
			term.setBackgroundColor(self.color_bg)
			term.setTextColor(self.color_txt)
			term.setCursorPos(self.x, self.y)
			term.write(_sub(index_arr, 1, self.w - 1).._rep(" ", self.w - 1 - #index_arr)..string_char(31))
			self.h = #self.array + 1
		else
			self.h = 1
		end
	else
		error("Bad argument init.dropdown(#6): " .. tostring(self.orientation))
	end
end

local function Dropdown_onFocus(self,focused)
	if not focused and self.expanded then
		self.expanded = false
		self.parent:onLayout()
		self.dirty = true
	end
	return true
end

local function Dropdown_onMouseDown(self, btn, x, y)
	if (y - self.y) > 0 then self.item_index = _min(_max(y - self.y, 1), #self.array) end
	self.expanded = not self.expanded
	if self.expanded == false then self.parent:onLayout() else self.dirty = true end
	self:pressed()
	return true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param array string[]|nil
---@param defaultValue string|nil
---@param maxSizeW number|nil
---@param orientation string|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object dropdown
function UI.New_Dropdown(x, y, array, defaultValue, maxSizeW, orientation, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, array, "table", "nil")
	expect(4, defaultValue, "string", "nil")
	expect(5, maxSizeW, "number", "nil")
	expect(6, orientation, "string", "nil")
	expect(7, color_bg, "number", "nil")
	expect(8, color_txt, "number", "nil")

	local instance = New_Widget(x, y, 1, 1, color_bg, color_txt)
	instance.array = array or {}
	instance.item_index = 1
	if defaultValue then
		for i, v in pairs(instance.array) do
			if v == defaultValue then
				instance.item_index = i
				break
			end
		end
	end
	instance.orientation = orientation or "left"
	if type(maxSizeW) ~= "number" then maxSizeW = nil end
	instance.w = maxSizeW or c.findMaxLenStrOfArray(instance.array) + 1
	instance.expanded = false

	instance.draw = Dropdown_draw
	instance.onFocus = Dropdown_onFocus
	instance.pressed = pressed
	instance.onMouseDown = Dropdown_onMouseDown

	return instance
end

local function menu_onFocus(self, focused)
	if not focused and self.expanded then
		self.expanded = false
		self.parent:onLayout()
		self.h = 1
		self.w = #self.name
	end
	return true
end

local function menu_onMouseDown(self, btn, x, y)
	if self.expanded then
		local coord = y - self.y
		if coord == 0 then return false end
		local elem = self.arr[coord]
		if elem then
			self:pressed(elem)
		end
	end
	self.expanded = not self.expanded
	if not self.expanded then
		self.parent:onLayout()
		self.h = 1
		self.w = #self.name
	else self.dirty = true end
	return true
end

local function menu_draw(self)
	local color_bg, color_txt = self.color_bg, self.color_txt
	if self.expanded then
		local max_length = c.findMaxLenStrOfArray(self.arr)
		for i, v in pairs(self.arr) do
			term.setBackgroundColor(color_bg)
			term.setTextColor(color_txt)
			term.setCursorPos(self.x, self.y + i)
			term.write(v.._rep(" ", max_length - #v))
		end
		color_bg, color_txt = self.color_txt, self.color_bg
		self.h = #self.arr + 1
		self.w = max_length
	end
	term.setBackgroundColor(color_bg)
	term.setTextColor(color_txt)
	term.setCursorPos(self.x, self.y)
	term.write(self.name)
end

function UI.New_Menu(x, y, name, arr, color_bg, color_txt)
	local instance = New_Widget(x, y, #name, 1, color_bg, color_txt)
	instance.arr = arr or {}
	instance.name = name
	instance.expanded = false

	instance.draw = menu_draw
	instance.onMouseDown = menu_onMouseDown
	instance.onFocus = menu_onFocus

	return instance
end

local function Slider_draw(self)
	local N = #self.arr
	local W = self.w

	-- Calculate thumb position if N > 0
	if N > 0 then
		local i = self.slidePosition
		local offset = (N == 1) and 0 or _min(_floor((i - 1) / (N - 1) * (W - 1)), self.w - 1)
		local thumb_x = self.x + offset
 		-- Overlay thumb (use a different char, e.g., █ or slider thumb equivalent)
 		term.setBackgroundColor(self.color_txt)
 		term.setTextColor(self.color_bg)
 		term.setCursorPos(thumb_x, self.y)
 		term.write(" ")
 		term.setBackgroundColor(self.color_bg)
 		term.setTextColor(self.color_txt2)
 		term.setCursorPos(self.x, self.y)
 		term.write(_rep(string_char(140), offset))
 		term.setBackgroundColor(self.color_bg)
 		term.setTextColor(self.color_txt)
 		term.setCursorPos(thumb_x + 1, self.y)
 		term.write(_rep(string_char(140), self.w - offset - 1))
	else
 		term.setBackgroundColor(self.color_bg)
 		term.setTextColor(self.color_txt)
 		term.setCursorPos(self.x, self.y)
 		term.write(_rep(string_char(140), W))
	end
end

local function Slider_updatePos(self, x, y)
	local N = #self.arr

	if N > 0 and self.w > 1 then  -- Avoid div by zero
		local offset = x - self.x
		local raw_index = _floor((offset / (self.w - 1) * (N - 1)) + 0.5) + 1
		self.slidePosition = _max(1, _min(N, raw_index))
	end
	self.dirty = true
end

local function Slider_onMouseDown(self, btn, x, y)
	self:updatePos(x, y)
	self:pressed(btn, x, y)
	return true
end

local function Slider_onMouseDrag(self, btn, x, y)
	self:updatePos(x, y)
	self:pressed(btn, x, y)
	return true
end

local function Slider_updateArr(self, array)
	self.arr = array
	self.dirty = true
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param arr number[]|nil
---@param defaultPosition number|nil
---@param color_txt2 color|number|nil
---@param color_bg color|number|nil
---@param color_txt color|number|nil
---@return table object slider
function UI.New_Slider(x, y, w, arr, defaultPosition, color_txt2, color_bg, color_txt)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, arr, "table")
	expect(5, defaultPosition, "number", "nil")
	expect(6, color_txt2, "number", "nil")
	expect(7, color_bg, "number", "nil")
	expect(8, color_txt, "number", "nil")

	local instance = New_Widget(x, y, w, 1, color_bg, color_txt)
	instance.arr = arr
	instance.slidePosition = defaultPosition or 1
	instance.color_txt2 = color_txt2 or instance.color_txt

	instance.draw = Slider_draw
	instance.pressed = pressed
	instance.updatePos = Slider_updatePos
	instance.onMouseDown = Slider_onMouseDown
	instance.onMouseDrag = Slider_onMouseDrag
	instance.updateArr = Slider_updateArr

	return instance
end

local function Container_layoutChild(self)
	for _, child in ipairs(self.children) do
		child.x, child.y = self.x + child.local_x - 1, self.y + child.local_y - 1
	end
end

local function Container_onLayout(self)
	self:layoutChild()
	for _, child in ipairs(self.children) do
		child:onLayout()
	end
end

local function Container_addChild(self, child)
	for _, v in ipairs(self.children) do
		if v == child then
			return false
		end
	end
	local function addRoot(object, root)
		object.root = root

		if object.children then
			for i = 1, #object.children do
				addRoot(object.children[i], root)
			end
		end
	end

	addRoot(child, self.root or self)
	if not child.local_x then child.local_x = child.x end
	if not child.local_y then child.local_y = child.y end
	child.parent = self
	table_insert(self.children, child)
	--child.dirty = true
	return true
end

local function Container_removeChild(self, child)
	if child == true then
		self.children = {}
		return
	end
	for i, v in ipairs(self.children) do
		if v == child then
			child.parent = nil
			table.remove(self.children, i)
			self:onLayout()
			return true
		end
	end
	return false
end

local function Container_redraw(self)
	redraw(self)
	for _, child in pairs(self.children) do
		child:redraw()
	end
end

local function Container_onEvent(self, evt)
	local event = evt[1]
	-- if self.modal and EVENTS.TOP[event] and (self.modal.root.keyboard:onEvent(evt) or self.modal:onEvent(evt)) then return true end
	if EVENTS.TOP[event] then
		for i = #self.children, 1, -1 do
			local child = self.children[i]
			if child:check(evt[3], evt[4]) and child:onEvent(evt) then
				return true
			end
		end
	elseif not EVENTS.FOCUS[event] then
		for _, child in pairs(self.children) do
			if child:onEvent(evt) then
				return true
			end
		end
	end
	-- If no child handled the event, try to handle it ourselves
	return onEvent(self, evt)
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param color_bg color|number|nil
---@return table object container
function UI.New_Container(x, y, w, h, color_bg)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, color_bg, "number", "nil")

	local instance = New_Widget(x, y, w, h, color_bg, _)
	instance.children = {}

	instance.layoutChild = Container_layoutChild
	instance.onLayout = Container_onLayout
	instance.addChild = Container_addChild
	instance.removeChild = Container_removeChild
	instance.redraw = Container_redraw
	instance.onEvent = Container_onEvent

	return instance
end

-- local function SwitchContainer_add_tab(self, name, ...)
--     local args = {...}
--     self.tabs[name] = {table.unpack(args)}
-- end

-- local function SwitchContainer_set_tab(self, name)
--     if self.tab_buffer and self.tab_buffer ~= name then
--         for _, child in ipairs(self.tabs[self.tab_buffer]) do
--             self.page:removeChild(child)
--         end
--     end
--     for _, child in ipairs(self.tabs[name]) do
--         self.page:addChild(child)
--     end
--     self.tab_buffer = name
-- end

-- function UI.New_SwitchContainer(x, y, w, h, colors_bg)
--     local instance = UI.New_Container(x, y, w, h, colors_bg)
--     instance.tabs = {}
--     instance.tab_buffer = nil
--     instance.page = UI.New_Container(x, y + 1, w, h - 1, colors_bg)
--     instance:addChild(instance.page)

--     instance.addTab = SwitchContainer_add_tab
--     instance.setTab = SwitchContainer_set_tab

--     return instance
-- end

local function TabBar_draw(self)
	local self_color_bg, self_color_txt = self.color_bg, self.color_txt
		paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self_color_bg)
	local offset = 1
	for i, text in ipairs(self.tabs) do
			if i == self.selected then
				term.setBackgroundColor(self_color_txt)
				term.setTextColor(colors.white)
				term.setCursorPos(offset, self.y)
				term.write(_sub(text, 1, self.max_w - 1).._rep(" ", self.max_w - #text - 1).."x")
				term.setBackgroundColor(self_color_txt)
				term.setTextColor(colors.gray)
				term.setCursorPos(self.max_w * i, self.y)
				term.write("x")
			else
				term.setBackgroundColor(self_color_bg)
				term.setTextColor(self_color_txt)
				term.setCursorPos(offset, self.y)
				term.write(_sub(text, 1, self.max_w - 1).._rep(" ", self.max_w - #text - 1).."x")
				term.setBackgroundColor(self_color_bg)
				term.setTextColor(colors.gray)
				term.setCursorPos(self.max_w * i, self.y)
				term.write("x")
			end
		offset = i * self.max_w + 1
	end
end

local function TabBar_onMouseUp(self, btn, x, y)
	if y ~= self.y then return end
	local local_x = x - self.x + 1
	local new_index = _ceil(local_x / self.max_w)
	if new_index > #self.tabs then return end
	self.selected = new_index
	self.dirty = true
	self:pressed(new_index)
	self.temp = nil
	return true
end

local function TabBar_addTab(self, name, pos)
	if pos then table.insert(self.tabs, pos, name) return end
	table.insert(self.tabs, name)
end

function UI.New_TabBar(x, y, w, h, color_bg, color_txt)
	local instance = New_Widget(x, y, w, h, color_bg, color_txt)
	instance.selected = 0
	instance.tabs = {}
	instance.offset = 0
	instance.max_w = 10

	instance.onMouseUp = TabBar_onMouseUp
	instance.addTab = TabBar_addTab
	instance.draw = TabBar_draw
	instance.pressed = pressed

	return instance
end

local function MsgWin_draw(self)
	for i = 1, self.h - 2 do
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_txt)
		term.setCursorPos(self.x + 1, self.y + i)
		term.write(_rep(" ", self.w - 2)..string_char(149))
		term.setBackgroundColor(self.color_txt)
		term.setTextColor(self.color_bg)
		term.setCursorPos(self.x, self.y + i)
		term.write(string_char(149))
	end
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	term.setCursorPos(self.x + 1, self.y)
	term.write(_rep(string_char(140), self.w - 2)..string_char(148))
	term.setBackgroundColor(self.color_txt)
	term.setTextColor(self.color_bg)
	term.setCursorPos(self.x, self.y)
	term.write(string_char(151))
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	term.setCursorPos(self.x, self.h + self.y - 1)
	term.write(string_char(138).._rep(string_char(140), self.w - 2)..string_char(133))
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	term.setCursorPos(_floor((self.w - #self.title)/2) + self.x, self.y)
	term.write(self.title)
end

local function MsgWin_onLayout(self)
	self.dirty = true
	Container_onLayout(self)
end

---Creating new *object* of *class*
---@param mode string "INFO" or "YES,NO"
---@return boolean object true or false
function UI.New_MsgWin(mode, title, msg)
	local root = UI.New_Root()

	local instance = UI.New_Container(math.floor(root.w*0.2 + 0.5), math.floor(root.h*0.2  + 0.5), math.floor(root.w*0.65  + 0.5), math.floor(root.h*0.65  + 0.5), colors.black)
	instance.title = title or " Error "
	instance.draw = MsgWin_draw
	instance.onLayout = MsgWin_onLayout

	local ok = false
	local label = UI.New_Label(2, 2, instance.w - 2, instance.h - 2, msg or "Message", "center", instance.color_bg, instance.color_txt)
	instance:addChild(label)
	local btnOK, btnYES
	if mode == "INFO" then
		btnOK = UI.New_Button(_floor((instance.w - 4)/2)+1, instance.h, 4, 1," OK ")
		instance:addChild(btnOK)
	elseif mode == "YES,NO" then
		btnYES = UI.New_Button(_floor((instance.w - 5)/2) - 2, instance.h, 5, 1," YES ")
		instance:addChild(btnYES)
		btnOK = UI.New_Button(_floor((instance.w + 4)/2), instance.h, 4, 1, " NO ")
		instance:addChild(btnOK)

		btnYES.pressed = function (self)
			table.remove(root.children, 1)
			root.running_program = false
			ok = true
		end
	end

	btnOK.pressed = function (self)
		table.remove(root.children, 1)
		root.running_program = false
	end

	instance.onResize = function (width, height)
		instance.local_x, instance.local_y = math.floor(width*0.2 + 0.5), math.floor(height*0.2  + 0.5)
		instance.w,  instance.h = math.floor(width*0.65  + 0.5), math.floor(height*0.65  + 0.5)
		label.w, label.h = instance.w - 2, instance.h - 2
		if mode == "INFO" then
			btnOK.local_x, btnOK.local_y = _floor((instance.w - 4)/2), instance.h
		elseif mode == "YES,NO" then
			btnYES.local_x, btnYES.local_y = _floor((instance.w - 5)/2) - 2, instance.h
			btnOK.local_x, btnOK.local_y = _floor((instance.w + 4)/2), instance.h
		end
	end

	root:addChild(instance)
	root:mainloop()

	return ok
end

---Creating new *object* of *class*
--@return table|nil object DialWin
function UI.New_DialWin(title, msg)
	local root = UI.New_Root()

	local instance = UI.New_Container(_floor((root.w - 24)/2) + 1, _floor((root.h - 4)/2), 24, 4, colors.black)
	instance.title = title or " Title "
	instance.draw = MsgWin_draw
	instance.onLayout = MsgWin_onLayout

	local label = UI.New_Label(2, 2, instance.w - 2, 1, msg or "", "left", instance.color_bg, instance.color_txt)
	instance:addChild(label)

	local textfield = UI.New_Textfield(label.local_x, label.local_y + 1, instance.w - 2, 1, "", false, colors.gray--[[instance.color_bg]], instance.color_txt)
	instance:addChild(textfield)

	local btnOK = UI.New_Button(_floor(instance.w/2 - 4 - 1), instance.h, 4, 1, " OK ", _, instance.color_bg, instance.color_txt)
	instance:addChild(btnOK)
	local ok = nil

	btnOK.pressed = function (self)
		table.remove(root.children, 1)
		root.running_program = false
		ok = true
	end

	local btnCANCEL = UI.New_Button(_floor(instance.w/2), instance.h, 8, 1, " CANCEL ", _, instance.color_bg, instance.color_txt)
	instance:addChild(btnCANCEL)

	textfield.pressed = function (self)
		table.remove(root.children, 1)
		root.running_program = false
		ok = true
	end

	btnCANCEL.pressed = function (self)
		table.remove(root.children, 1)
		root.running_program = false
	end

	instance.onResize = function (width, height)
		instance.local_x, instance.local_y = _floor((width - 24)/2), _floor((height - 4)/2)
	end

	root:addChild(instance)
	root.focus = textfield
	root:mainloop()

	if ok then return textfield.text end
end

local function Keyboard_draw(self)
	for i = 1, self.h - 2 do
		term.setBackgroundColor(self.color_txt)
		term.setTextColor(self.color_bg)
		term.setCursorPos(self.w + self.x - 1, self.y + i)
		term.write(string_char(149))
		term.setBackgroundColor(self.color_bg)
		term.setTextColor(self.color_txt)
		term.setCursorPos(self.x, self.y + i)
		term.write(string_char(149).._rep(" ",self.w - 2))
	end
	term.setBackgroundColor(self.color_bg)
	term.setTextColor(self.color_txt)
	term.setCursorPos(self.x, self.y)
	term.write(string_char(151).._rep(string_char(131), self.w - 2))
	term.setBackgroundColor(self.color_txt)
	term.setTextColor(self.color_bg)
	term.setCursorPos(self.w + self.x - 1, self.y)
	term.write(string_char(148))
	term.setBackgroundColor(self.color_txt)
	term.setTextColor(self.color_bg)
	term.setCursorPos(self.x, self.h + self.y - 1)
	term.write(string_char(138).._rep(string_char(143), self.w - 2)..string_char(133))
end

local function Keyboard_onEvent(self,evt)
	if not self.parent then return false end
	if evt[3] and evt[4] and self:check(evt[3],evt[4]) then
		if EVENTS.TOP[evt[1]] then
			for i = #self.children, 1, -1 do
				local child = self.children[i]
				if child:check(evt[3],evt[4]) and child:onEvent(evt) then
					return true
				end
			end
		elseif self.focus and EVENTS.FOCUS[evt[1]] and self.focus:onEvent(evt) then
			return true
		end
		return true
	end
	return false
end

function UI.New_Keyboard(width, height)
	local instance = UI.New_Container(_floor((width - 21)/2) + 1, height - 6, 21, 7, colors.black)
	instance.focus = nil
	-- Стани: 0=default, 1=shift, 2=caps, 3=smileys
	instance.upper = 0

	local layout_default = {
		"1","2","3","4","5","6","7","8","9","0", --10
		"q","w","e","r","t","y","u","i","o","p", --20
		"a","s","d","f","g","h","j","k","l", --29
		string_char(24)..string_char(95),"z","x","c","v","b","n","m", string_char(27).."-", --38
		" "..string_char(2).." ", ",", ".", "  SPACE",string_char(27), string_char(24), string_char(25), string_char(26), string_char(17)..string_char(172)
	}

	local layout_shift = {
		"1","2","3","4","5","6","7","8","9","0", --10 string_char(27)
		"Q","W","E","R","T","Y","U","I","O","P", --20
		"A","S","D","F","G","H","J","K","L", --29
		string_char(24)..string_char(95),"Z","X","C","V","B","N","M", string_char(27).."-", --38
		" "..string_char(2).." ", ",", ".", "  SPACE", string_char(27), string_char(24), string_char(25), string_char(26), string_char(17)..string_char(172)
	}

	local layout_smile = {
		-- Ряд 1 (індекси 1-10)
		"!", "\"", "#", ";", "%", ":", "?", "*", "(", ")",
		-- Ряд 2 (індекси 11-20)
		"~", "@", "T", "$", string_char(19), "^", "&", "=", "+", "-",
		-- Ряд 3 (індекси 21-29)
		"_", "`", "'", string_char(171), string_char(187), "{", "}", "[", "]",
		-- Ряд 4 (індекси 30-38)
		layout_default[30], -- 30: Shift (Спеціальна, залишаємо)
		string_char(177), string_char(191), "|", "/", "\\", "<", ">", -- 31-37 (z,x,c,v,b,n,m)
		layout_default[38], -- 38: Backspace (Спеціальна, залишаємо)
		-- Ряд 5 (індекси 39-45)
		"ABC",         -- 39: "Smile" button, тепер це "ABC"
		layout_default[40], -- 40: Comma (Спеціальна)
		layout_default[41], -- 41: Dot (Спеціальна)
		layout_default[42], -- 42: Space (Спеціальна)
		layout_default[43], -- 43: Left (Спеціальна)
		layout_default[44], -- 44: Up (Спеціальна)
		layout_default[45], -- 45: Down (Спеціальна)
		layout_default[46], -- 46: Right (Спеціальна)
		layout_default[47],  -- 47: Enter (Спеціальна)
	}

	local keyLayout = {
		-- Ряд 1: Цифри (y=1)
		{ 1, 1, 1 }, { 2, 3, 1 }, { 3, 5, 1 }, { 4, 7, 1 }, { 5, 9, 1 }, { 6, 11, 1 }, { 7, 13, 1 }, { 8, 15, 1 }, { 9, 17, 1 }, { 10, 19, 1 },
		-- Ряд 2: QWERTY (y=2)
		{ 11, 1, 2 }, { 12, 3, 2 }, { 13, 5, 2 }, { 14, 7, 2 }, { 15, 9, 2 }, { 16, 11, 2 }, { 17, 13, 2 }, { 18, 15, 2 }, { 19, 17, 2 }, { 20, 19, 2 },
		-- Ряд 3: ASDF (y=3)
		{ 21, 2, 3 }, { 22, 4, 3 }, { 23, 6, 3 }, { 24, 8, 3 }, { 25, 10, 3 }, { 26, 12, 3 }, { 27, 14, 3 }, { 28, 16, 3 }, { 29, 18, 3 },
		-- Ряд 4: ZXCV (y=4)
		{ 30, 1, 4, "shift" },
		{ 31, 4, 4 }, { 32, 6, 4 }, { 33, 8, 4 }, { 34, 10, 4 }, { 35, 12, 4 }, { 36, 14, 4 }, { 37, 16, 4 },
		{ 38, 18, 4, "backspace" },
		-- Ряд 5: Нижній (y=5)
		{ 39, 1, 5, "smile" },
		{ 40, 4, 5 }, -- comma
		{ 41, 5, 5 }, -- dot
		{ 42, 6, 5, "space" },
		{ 43, 14, 5, "left" },
		{ 44, 15, 5, "up"},
		{ 45, 16, 5, "down"},
		{ 46, 17, 5, "right" },
		{ 47, 18, 5, "enter" },
	}

	local function setKeyboardLayout(layoutTable, newUpperState)
		instance.upper = newUpperState
		for k, child in pairs(instance.children) do
			if layoutTable[k] then
				child:setText(layoutTable[k])
			end
		end
		if newUpperState == 2 then
			instance.children[30]:setText(string_char(23)..string_char(95))
		end
		if newUpperState == 3 or newUpperState == 0 then
			instance.children[30].held = false
		end
		if instance.children[30] then instance.children[30].dirty = true end
		if instance.children[39] then instance.children[39].dirty = true end
	end

	local specialActions = {
		backspace = function (self)
			os.queueEvent("key", keys.backspace)
		end,
		left = function (self)
			os.queueEvent("key", keys.left)
		end,
		space = function (self)
			os.queueEvent("char", " ")
		end,
		right = function (self)
			os.queueEvent("key", keys.right)
		end,
		enter = function (self)
			os.queueEvent("key", keys.enter)
		end,
		up = function (self)
			os.queueEvent("key", keys.up)
		end,
		down = function (self)
			os.queueEvent("key", keys.down)
		end,

		shift = function (self)
			if instance.upper == 0 then
				setKeyboardLayout(layout_shift, 1) -- Shift
			elseif instance.upper == 1 then
				setKeyboardLayout(layout_shift, 2) -- Caps
			elseif instance.upper == 2 then
				setKeyboardLayout(layout_default, 0)
			elseif instance.upper == 3 then
				self.held = false
			end
		end,

		-- (ОНОВЛЕНО) Посилається на локальні layout_* таблиці
		smile = function (self)
			if instance.upper == 3 then
				setKeyboardLayout(layout_default, 0)
			else
				setKeyboardLayout(layout_smile, 3)
			end
		end
	}

	for _, keyDef in ipairs(keyLayout) do
		local keyIndex = keyDef[1]
		local relX = keyDef[2]
		local relY = keyDef[3]
		local actionName = keyDef[4]

		if layout_default[keyIndex] then
			local btn = UI.New_Button(1 + relX, 1 + relY, #layout_default[keyIndex], 1, layout_default[keyIndex], "center", instance.color_bg, colors.white)
			btn.pressed = function (self)
				os.queueEvent("char", self.text)
				if instance.upper == 1 then
					setKeyboardLayout(layout_default, 0)
				end
			end
			btn.onEvent = function (self, evt)
				if evt[1] == "mouse_click" then
					if self.parent then self.parent.focus = self end
					return self:onMouseDown(evt[2], evt[3], evt[4])
				end
				return onEvent(self, evt)
			end

			if actionName and specialActions[actionName] then
				btn.pressed = specialActions[actionName]
			end

			if actionName == "shift" then
				btn.onMouseUp = function (self, btn, x, y)
					if self:check(x, y) and self.held == true then self:pressed() end
					if self.parent.upper == 0 then self.held = false end
					self.dirty = true
					return true
				end
			end

			instance:addChild(btn)
		end
	end

	instance.draw = Keyboard_draw
	instance.onLayout = MsgWin_onLayout
	instance.onEvent = Keyboard_onEvent
	instance.onResize = function (width, height)
		instance.local_x, instance.local_y = _floor((width - 21)/2) + 1, height - 6
	end

	return instance
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param color_bg color|number
---@param title string
---@return table object Window
function UI.New_Window(x, y, w, h, color_bg, title)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, color_bg, "number")
	expect(6, title, "string")

	local instance = UI.New_Box(x, y, w, h, colors.white)
	instance.label = UI.New_Label(math.floor((w - #title)/2) + 1, y, #title, 1, title, _, colors.white, colors.black)
	instance:addChild(instance.label)
	instance.close = UI.New_Button(w, y, 1, 1, "x" , _, colors.white, colors.black)
	instance:addChild(instance.close)
	instance.surface = UI.New_Box(1, 2, w, h - 1, color_bg)
	instance:addChild(instance.surface)

	return instance
end

local function Box_draw(self)
	paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.color_bg)
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param color_bg color|number|nil
---@return table object box
function UI.New_Box(x, y, w, h, color_bg)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, color_bg, "number", "nil")

	local instance = UI.New_Container(x, y, w, h, color_bg or colors.black)

	instance.draw = Box_draw
	instance.onLayout = MsgWin_onLayout

	return instance
end

local function ScrollBox_draw(self)
	paintutils.drawFilledBox(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, self.color_bg)
end

local function ScrollBox_redraw(self)
	-- screen.clip_set(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1)

	if self.dirty then self:draw() self.dirty = false end

	for _, child in ipairs(self.visibleChild) do
		child:redraw()
	end
	-- screen.clip_remove()
end

local function ScrollBox_onLayout(self)
	self.visibleChild = {}
	self.dirty = true
	Container_onLayout(self)
	for _, child in pairs(self.children) do
		child.y = child.y - self.scroll.pos_y
		self.scroll.max_y = _max(_max(self.scroll.max_y, child.local_y + child.h) - self.h, 0)
		if child.y + child.h > self.y and child.y <= self.y + self.h - 1 then
			table_insert(self.visibleChild, child)
		end
	end
	-- self.len = self.scroll.max_y + self.h
end

local function ScrollBox_updateDirty(self)
	List_updateDirty(self)
	self:onLayout()
end

---Creating new *object* of *class*
---@param x number
---@param y number
---@param w number
---@param h number
---@param color_bg color|number|nil
---@return table object ScrollBox
function UI.New_ScrollBox(x, y, w, h, color_bg)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, w, "number")
	expect(4, h, "number")
	expect(5, color_bg, "number", "nil")

	local instance = UI.New_Container(x, y, w, h, color_bg)
	add_mixin(instance, ScrollableMixin)
	instance:initScroll(3, 3)
	instance.term = term.current()
	instance.visibleChild = {}

	instance.draw = ScrollBox_draw
	instance.redraw = ScrollBox_redraw
	instance.onLayout = ScrollBox_onLayout
	instance.onMouseScroll = List_onMouseScroll
	instance.updateDirty = ScrollBox_updateDirty

	return instance
end

local function Root_show(self)
	self:onLayout()
	self:redraw()
end

local function Root_tResize(self)
	self.w, self.h = term.native().getSize()
	self.term_current.reposition(1,1,self.w, self.h)
	for _, child in ipairs(self.children) do
		if child.onResize and child ~= self.keyboard then
			child.onResize(self.w, self.h)
		end
	end
	if self.keyboard then
		self.keyboard.onResize(self.w, self.h)
		self.keyboard.x, self.keyboard.y = self.x + self.keyboard.local_x - 1, self.y + self.keyboard.local_y - 1
	end
	self:onLayout()
	-- screen.fill()
end

local function Root_redraw(self)
	Container_redraw(self)
	-- screen.update()
	if self.focus then
		self.focus:focusPostDraw()
	end
	self.term_current.setVisible(true)
end

local function Root_onEvent(self, evt)
	local event = evt[1]
	local focus = self.focus
	local ret = Container_onEvent(self, evt)
	if self.focus and EVENTS.FOCUS[event] and self.focus:onEvent(evt) then
		if self.keyboard then self.keyboard:onEvent(evt) end
		ret = true
	end
	if event == "term_resize" then
		self:tResize()
	end
	if self.focus ~= focus then
		if focus then
			focus:onFocus(false)
		end
		if self.focus then
			self.focus:onFocus(true)
		end
	end
	self:redraw()
	return ret
end

local function Root_mainloop(self)
	self:show()
	while self.running_program do
		local evt = {os.pullEventRaw()}
		self.term_current.setVisible(false)
		-- dbg.print(textutils.serialize(evt))
		-- print(textutils.serialize(self.size))
		if evt[1] == "terminate" then
			term.setCursorPos(1,1)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.clear()
			self.running_program = false
			break
		end

		if #self.processes > 0 then
			local status, ret = coroutine.resume(self.processes[1], table.unpack(evt))
			if not status then UI.New_MsgWin("INFO", " ERROR ", ret) self:onLayout() end
			if coroutine.status(self.processes[1]) == "dead" then
				table.remove(self.processes, 1)
			end
		end

		self:onEvent(evt)
	end
end

---Creating new *object* of *class* root - event handler, to use root:mainloop()
---@return table object root
function UI.New_Root()

	local instance = UI.New_Container(1, 1, term.getSize())
	instance.focus = nil
	instance.running_program = true
	instance.term_current = term.current()
	instance.processes = {}

	instance.show = Root_show
	instance.tResize = Root_tResize
	instance.redraw = Root_redraw
	instance.onEvent = Root_onEvent
	instance.mainloop = Root_mainloop

	return instance
end

return UI
