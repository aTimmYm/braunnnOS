------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local _min = math.min
local _max = math.max
local _sub = string.sub
local _rep = string.rep
local _gsub = string.gsub
local _ceil = math.ceil
local _win = window
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local system = require("braunnnsys")
local screen = require("Screen")
local UI = require("ui")
local _lex = require("/sbin/CEditor/Data/lex")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local COLORS = {
	["whitespace"] = colors.white, --  whitespace: Self-explanatory. Can match spaces, newlines, tabs, and carriage returns (although I don't know why anyone would use those... WINDOWS)
	["comment"] = colors.gray, --  comment: Either multi-line or single-line comments.
	["string"] = colors.green, --  string: A string. Usually the part of the string that is not an escape.
	["escape"] = colors.white, --  escape: Can only be found within strings (although they are separate tokens)
	["keyword"] = colors.blue, --  keyword: Keywords. Like "while", "end", "do", etc
	["value"] = colors.pink, --  value: Special values. Only true, false, and nil.
	["ident"] = colors.cyan, --  ident: Identifier. Variables, function names, etc..
	["number"] = colors.white, --  number: Numbers!
	["symbol"] = colors.white, --  symbol: Symbols, like brackets, parenthesis, ., .., ... etc
	["operator"] = colors.white, --  operator: Operators, like =, ==, >=, <=, ~=, etc
	["unidentified"] = colors.red, --  unidentified: Anything that isn't one of the above tokens. Consider them ERRORS.
	["function"] = colors.purple,
	["nfunction"] = colors.yellow,
	["values"] = colors.red,
	["equality"] = colors.red,
	["arg"] = colors.white
}
local new_tabs = setmetatable({}, {__len = function (tbl)
	local i = 0
	for _, _ in pairs(tbl) do
		i = i + 1
	end
	return i
end})
local tabs = {}
local tab_buffer = nil
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "CEditor")

local menu = UI.New_Menu(1, 1, "File", {"New", "Open", "Save", "Save as"}, colors.white, colors.black)
window:addChild(menu)

local run = UI.New_Button(5, 1, 3, 1, string.char(16), "center", window.color_bg, colors.gray)
window:addChild(run)

local tabbar = UI.New_TabBar(1, 1, surface.w, 1, colors.black, colors.lightGray)
surface:addChild(tabbar)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function textbox_draw(self)
	local gray = colors.gray
	local lightGray = colors.lightGray
	local white = colors.white
	local self_x, self_y = self.x, self.y
	local self_w, self_h = self.w, self.h
	local self_color_bg = self.color_bg
	local self_scroll_pos_x, self_scroll_pos_y = self.scroll.pos_x, self.scroll.pos_y

	screen.draw_rectangle(1, self_y, 4, self.h + 1, gray)
	screen.clip_set(1, self_y, self_w + self_x - 1, self_h + self_y - 1)
	screen.draw_rectangle(self_x, self_y, self_w, self_h, self_color_bg)

	local visible_start = self_scroll_pos_y + 1
	local visible_end = _min(self_h + self_scroll_pos_y, #self.lines)

	local start_lex = visible_start
	while start_lex > 1 and (not self.tokenCache[start_lex - 1] or self.dirtyLines[start_lex - 1]) do
		start_lex = start_lex - 1
	end

	local prevState
	if start_lex == 1 then
		prevState = { type = "normal", level = 0 }
	else
		prevState = self.tokenCache[start_lex - 1].stateOut
	end

	for j = start_lex, visible_end do
		if not self.tokenCache[j] or self.dirtyLines[j] then
			local tokens, newState = _lex(self.lines[j] or "", prevState)
			self.tokenCache[j] = { tokens = tokens, stateIn = prevState, stateOut = newState }
			self.dirtyLines[j] = nil
			prevState = newState
		else
			prevState = self.tokenCache[j].stateOut
		end
	end

	for j = visible_start, visible_end do
		local tokens = self.tokenCache[j].tokens
		for _, token in ipairs(tokens) do
			screen.write(token.data, token.posFirst + self_x - self_scroll_pos_x - 1, j - self_scroll_pos_y + self_y - 1, self_color_bg, COLORS[token.type] or colors.white)
		end
		local num = #tostring(j)
		local color_txt = lightGray
		if self.cursor.y == j then
			color_txt = white
		end
		screen.write(_rep(" ", 4 - num) .. tostring(j), 1, j - self_scroll_pos_y + self_y - 1, gray, color_txt)
	end
	screen.clip_remove()

	local char = string.char(149)
	for i = self_y, self_y + self_h do
		screen.write(char, 5, i, self_color_bg, gray)
	end

	screen.clip_set(self_x, self_y, self_w + self_x - 1, self_h + self_y - 1)
	if self.selected.status then
		local p1 = self.selected.pos1
		local p2 = self.selected.pos2
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
				sel_text = _gsub(sel_text, " ", string.char(183))
				sel_text = _gsub(sel_text, "\t", string.char(26))
				local draw_x = self_x + (sel_x_start - 1) - self_scroll_pos_x
				local draw_y = self_y + (i - self_scroll_pos_y) - 1
				screen.write(sel_text, draw_x, draw_y, lightGray, white)
			end
		end
	end
	screen.clip_remove()
end

local function create_textbox(path)
	local textbox = UI.New_TextBox(6, 2, surface.w - 6, surface.h - 2, colors.black, colors.white)
	textbox.path = path
	textbox.draw = textbox_draw
	textbox.tokenCache = {}  -- { [lineNum] = {tokens = {}, stateIn = {}, stateOut = {} } }
	textbox.dirtyLines = setmetatable({}, {__index = function() return false end})  -- Флаги dirty

	function textbox:invalidateCacheFrom(y)
		for i = y, #self.lines do
			self.tokenCache[i] = nil
			self.dirtyLines[i] = true
		end
	end

	function textbox:cleanCache()
		local max = 0
		for k in pairs(self.tokenCache) do
			if type(k) == "number" then
				max = math.max(max, k)
			end
		end
		for i = #self.lines + 1, max do
			self.tokenCache[i] = nil
			self.dirtyLines[i] = nil
		end
	end

	local temp_char = textbox.onCharTyped
	if temp_char then
		textbox.onCharTyped = function(self, chr)
			local min_y = self.cursor.y
			temp_char(self, chr)
			self:invalidateCacheFrom(min_y)
			self:cleanCache()
		end
	end

	local temp_setLine = textbox.setLine
	textbox.setLine = function(self, line, y)
		temp_setLine(self, line, y)
		self:invalidateCacheFrom(y)
		self:cleanCache()
	end

	local temp = textbox.moveCursorPos
	textbox.moveCursorPos = function (self, x, y)
		temp(self, x, y)
		self.dirty = true
	end

	local preff_x
	local alt_held = false
	local temp_key = textbox.onKeyDown
	textbox.onKeyDown = function (self, key, held)
		local min_y
		if self.selected.status then
			min_y = math.min(self.selected.pos1.y, self.selected.pos2.y, self.cursor.y)
		else
			min_y = self.cursor.y
		end

		if not preff_x then preff_x = self.cursor.x end
		if key == keys.leftAlt then
			alt_held = true
			return true
		elseif key == keys.up then
			local cp = self.cursor
			if cp.y == 1 and cp.x ~= 1 then cp.x = 1 end
			if alt_held then
				if self.selected.status then
					local p1 = self.selected.pos1
					local p2 = self.selected.pos2
					if p1.y > 1 then
						local line = self.lines[p1.y - 1]
						table.move(self.lines, p1.y, p2.y, p1.y - 1)
						self:setLine(line, p2.y)
						p1.y = p1.y - 1
						p2.y = p2.y - 1
						if p1.y < self.scroll.pos_y then
							self:scrollY(-1 / self.scroll.sensitivity_y)
						end
						self:moveCursorPos(preff_x, self.cursor.y - 1)
						self:invalidateCacheFrom(p1.y)
						self:cleanCache()
					end
					return true
				end
				if cp.y == 1 then return true end
				local line = self.lines[cp.y - 1]
				table.move(self.lines, cp.y, cp.y, cp.y - 1)
				self:setLine(line, cp.y)
				self:invalidateCacheFrom(cp.y - 1)
				self:cleanCache()
			end
		elseif key == keys.down then
			local cp = self.cursor
			local n = #self.lines
			if cp.y == n and cp.x ~= #self.lines[n] then cp.x = #self.lines[n] end
			if alt_held then
				if self.selected.status then
					local p1 = self.selected.pos1
					local p2 = self.selected.pos2
					local lines = self.lines
					if p2.y < #lines then
						local line = lines[p2.y + 1]
						table.move(lines, p1.y, p2.y, p1.y + 1)
						self:setLine(line, p1.y)
						p1.y = p1.y + 1
						p2.y = p2.y + 1
						if p2.y > self.h + self.scroll.pos_y then
							self:scrollY(1 / self.scroll.sensitivity_y)
						end
						self:moveCursorPos(preff_x, self.cursor.y + 1)
						self:invalidateCacheFrom(p1.y)
						self:cleanCache()
					end
					return true
				end
				if cp.y == 1 then return true end
				local line = self.lines[cp.y + 1]
				table.move(self.lines, cp.y, cp.y, cp.y + 1)
				self:setLine(line, cp.y)
				self:invalidateCacheFrom(cp.y)
				self:cleanCache()
			end
		else
			preff_x = nil
		end
		local result = temp_key(self, key, held)
		self:cleanCache()
		self:invalidateCacheFrom(_max(1, min_y - 1))
		return result
	end

	local temp_keyUp = textbox.onKeyUp
	textbox.onKeyUp = function (self, key)
		if key == keys.leftAlt then
			alt_held = false
			return true
		end
		return temp_keyUp(self, key)
	end

	UI.New_Scrollbar(textbox)
	UI.New_Scrollbar_Horizontal(textbox)

	return textbox
end

local function add_tab(name, path, pos)
	local textbox = create_textbox(path)
	tabbar:addTab(name, pos)
	if pos then table.insert(tabs, pos, textbox) return textbox end
	table.insert(tabs, textbox)
	return textbox
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
menu.pressed = function (self, id)
	if id == "New" then
		local str_new = "NEW - "..tostring(#new_tabs + 1)
		if not new_tabs[str_new] then
			new_tabs[str_new] = true
		else
			str_new = "NEW - "..tostring(#new_tabs)
			new_tabs[str_new] = true
		end
		local new_selected = tabbar.selected + 1
		add_tab(str_new, _, new_selected)
		tabbar.selected = new_selected
		tabbar:pressed(new_selected)
	elseif id == "Open" then
		local path = UI.New_DialWin(" Open ", "Enter path to file:")
		if not path then
			window:onLayout()
			return
		end
		if not fs.exists(path) then
			UI.New_MsgWin("INFO", " Error ", "File not found")
			window:onLayout()
			return
		end
		local name = path:match("([^/%\\]+)$")
		for i, v in ipairs(tabbar.tabs) do
			if v == name and tabs[i].path == path then
				tabbar.selected = i
				tabbar:pressed(i)
				return
			end
		end
		local new_selected = tabbar.selected + 1
		local box = add_tab(name, path, new_selected)
		tabbar.selected = new_selected
		tabbar:pressed(new_selected)
		local i = 1
		for line in io.lines(path) do
			box:setLine(line, i)
			i = i + 1
		end
	elseif id == "Save" then
		if tab_buffer.path then
			local file = fs.open(tab_buffer.path, "w")
			for _, v in pairs(tab_buffer.lines) do
				file.writeLine(v)
			end
			file.close()
		end
	elseif id == "Save as" then
		local path = UI.New_DialWin(" Save as ", "Enter path to save:")
		if not path then
			window:onLayout()
			return
		end
		if fs.exists(path) then
			local answ = UI.New_MsgWin("YES,NO", " Message ", "File is already exists. Do you want to override it?")
			window:onLayout()
			if not answ then return end
		end
		local name = path:match("([^/%\\]+)$")
		local file = fs.open(path, "w")
		new_tabs[tabbar.tabs[tabbar.selected]] = nil
		tabbar.tabs[tabbar.selected] = name
		for _, v in pairs(tab_buffer.lines) do
			file.writeLine(v)
		end
		file.close()
		if not tab_buffer.path then tab_buffer.path = path end
	end
end

local clicked_index
tabbar.onMouseDown = function (self, btn, x, y)
	local local_x = x - self.x + 1
	local new_index = _ceil(local_x / self.max_w)

	if new_index > #self.tabs then return end

	if local_x % self.max_w == 0 then
		if new_tabs[self.tabs[new_index]] then new_tabs[self.tabs[new_index]] = nil end

		local select_index = self.selected
		local tab = tabs[new_index]

		surface:removeChild(tab)
		surface:removeChild(tab.scrollbar_v)
		surface:removeChild(tab.scrollbar_h)
		table.remove(tabs, new_index)

		if new_index <= select_index then
			self.selected = select_index - 1
		end

		table.remove(self.tabs, new_index)
		self:pressed(self.selected)
		self.dirty = true

		return true
	end

	clicked_index = new_index

	return true
end

run.pressed = function (self)
	if not tab_buffer or tab_buffer.lines == {""} then return end

	local W, H = term.getSize()
	local T = term.current()

	local win = _win.create(T, 1, 2, W, H - 1, true)
	term.redirect(win)

	local def = term.getTextColor()
	local source = table.concat(tab_buffer.lines, "\n")
	local fn, err = load(source, "textbox", "t", _G)
	if not fn then
		term.setTextColor(colors.red)
		print(tostring(err))
	else
		fn()
	end
	term.setTextColor(colors.yellow)
	print("Press any key to continue.")
	term.setTextColor(def)
	local filter = {
		["mouse_click"] = true,
		["key"] = true
	}
	while not filter[os.pullEvent()] do end
	term.redirect(T)
end

tabbar.onMouseDrag = function (self, btn, x, y)
	local local_x = x - self.x + 1
	local new_index = _ceil(local_x / self.max_w)

	if new_index > #self.tabs then return end

	if clicked_index == new_index then return end

	self.tabs[clicked_index], self.tabs[new_index] = self.tabs[new_index], self.tabs[clicked_index]
	tabs[clicked_index], tabs[new_index] = tabs[new_index], tabs[clicked_index]

    if self.selected == clicked_index then
        self.selected = new_index
    elseif self.selected == new_index then
        self.selected = clicked_index
    end

	clicked_index = new_index
	self.dirty = true

	return true
end

tabbar.pressed = function (self, index)
	local tab = tabs[index]

	if tab_buffer and tab_buffer ~= tab then
		surface:removeChild(tab_buffer)
		surface:removeChild(tab_buffer.scrollbar_v)
		surface:removeChild(tab_buffer.scrollbar_h)
		tab_buffer = nil
	end

	if tab and not tab_buffer then
		tab_buffer = tab
		surface:addChild(tab)
		surface:addChild(tab.scrollbar_v)
		surface:addChild(tab.scrollbar_h)
		tab:onLayout()
		window.root.focus = tab
	end
end

surface.onMouseDown = function (self, btn, x, y)
	if not tab_buffer then return end
	if x < 5 and y < self.y + self.h - 1 then
		local igrik = y - self.y --[[+ 1 ]]+ tab_buffer.scroll.pos_y
		if tab_buffer.lines[igrik] then
			local selected = tab_buffer.selected
			selected.status = true

			tab_buffer.click_pos = {x = 1, y = igrik}
			selected.pos1 = {x = 1, y = igrik}
			selected.pos2 = {x = #tab_buffer.lines[igrik], y = igrik}
			if tab_buffer.lines[igrik + 1] then
				tab_buffer:moveCursorPos(1, igrik + 1)
			else
				tab_buffer:moveCursorPos(#tab_buffer.lines[igrik] + 1, igrik)
			end
			self.root.focus = tab_buffer
			tab_buffer.dirty = true
		end
		return true
	end
	return false
end

surface.onResize = function (width, height)
	for _, box in pairs(tabs) do
		box.w = width - 6
		box.h = height - 2
		box.scrollbar_v.h = height - 2
		box.scrollbar_v.local_x = width
		box.scrollbar_h.w = width - 6
		box.scrollbar_h.local_y = height
	end
	tabbar.w = width
end

local temp_pressed = window.close.pressed
window.close.pressed = function (self)
	package.loaded["/sbin/CEditor/Data/lex"] = nil
	return temp_pressed(self)
end
-----------------------------------------------------
surface:onLayout()