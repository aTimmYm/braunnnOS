local screen = window.create(term.current(), 1, 1, term.getSize())
screen.setVisible(false)
term.redirect(screen)

local sys = require "syscalls"
local UI = require "ui2"
local c = require "cfunc"
local conf = c.readConf("usr/settings.conf")
local Popup = require "Popup"

local desktop_mode = conf["DesktopMode"]
local _WM = {}
local _rep = string.rep
-- local to_blit = colors.toBlit
local windows_visible = {}
local windows = {}
local popup_windows = {}
local need_resize = nil
local win_held = nil
local window_focus = nil

local DEFAULT_X, DEFAULT_Y = 1, 1
local DEFAULT_W, DEFAULT_H = 20, 9
local MAXIMIZE_W, MAXIMIZE_H = screen.getSize()
local MIN_W, MIN_H = 10, 3

local EVENTS = {
	MOUSE = {
		["mouse_click"] = true,
		["mouse_scroll"] = true,
		["mouse_drag"] = true,
		["mouse_move"] = true,
		["mouse_up"] = true,
	},
	TOP = {
		["mouse_click"] = true,
		["mouse_scroll"] = true,
	},
	FOCUS = {
		["char"] = true,
		["key"] = true,
		["key_up"] = true,
		["paste"] = true,
	},
	WM = {
		["wm_reposition"] = true,
		["wm_restore"] = true
	}
}

local COLORS = {
	BUTTONS = {
		desktop_mode and colors.red or colors.black,
		colors.orange,
		colors.green
	},
	TITLE = {
		desktop_mode and colors.gray or colors.white,
		desktop_mode and colors.white or colors.black
	}
}

local function check(win, x, y)
	return (x >= win.x and x < win.w + win.x and
		y >= win.y and y < win.h + win.y)
end

local function term_check(win, x, y)
	local top = win.y + (win.border and 1 or 0)
	return (x >= win.x and x < win.w + win.x and
		y >= top and y < win.h + win.y)
end


local function win_draw(self)
	if not self.border then return end
	local btns = #self.children
	local center = math.floor((self.w - btns - #self.title) / 2) + 1
	term.setBackgroundColor(window_focus == self and COLORS.TITLE[1] or colors.lightGray)
	term.setCursorPos(self.x, self.y)
	term.write(_rep(" ", self.w))
	term.setTextColor(COLORS.TITLE[2])
	term.setCursorPos(center + self.x, self.y)
	term.write(self.title)
	for i, child in ipairs(self.children) do
		child.fc = window_focus == self and COLORS.BUTTONS[i] or colors.gray
		child.bc = window_focus == self and COLORS.TITLE[1] or colors.lightGray
		child:draw()
	end
end

function sys.create_popup(items, x, y, width, opts)
	opts = opts or { bgColor = colors.gray, selText = colors.white, selBg = colors.blue }
	local p = Popup.create(items, x, y, width, opts, screen)
	table.insert(popup_windows, p)
	return p
end

-- function sys.create_popup(object)
-- 	_G.context = object
-- 	table.insert(popup_windows, object)
-- 	if _WM.uiserver_pid then
-- 		sys.ipc(_WM.uiserver_pid, "popup_add")
-- 	end
-- 	return p
-- end

local function window_reposition(win, x, y, w, h)
	local n_x = desktop_mode and x or (w or win.w) + x - 1
	for i, child in ipairs(win.children) do
		child.x, child.y = n_x + i - 1, y
	end

	win.x, win.y = x, y
	if w and h then win.w, win.h = w, h end
	y = win.border and y + 1 or y
	h = (h and win.border) and h - 1 or h
	win.term.reposition(x, y, w, h)
	if _WM.docker_pid and windows[_WM.docker_pid] == win then return end
	if win.h + win.y - 1 >= MAXIMIZE_H - 1 then
		if _WM.docker_pid then _WM.close_window(_WM.docker_pid, true) end
	elseif _WM.docker_pid then
		for i,v in ipairs(windows_visible) do
			if v == windows[_WM.docker_pid] then
				return
			end
		end
		table.insert(windows_visible, windows[_WM.docker_pid])
	end
end

local function window_set_focus(win)
	if window_focus == win then return end

	window_focus = win

	for i = #windows_visible, 1, -1 do
		local win_v = windows_visible[i]
		if win_v == win then
			table.remove(windows_visible, i)
			break
		end
	end

	table.insert(windows_visible, win)
	if _WM.panel_pid then sys.ipc(_WM.panel_pid, "menu_add", win.id) end
end

local function title_handler(win, evt)
	if evt[1] == "mouse_move" then return false end
	for _, child in ipairs(win.children) do
		if child:check(evt[3], evt[4]) or child.held then
			window_set_focus(win)
			child:onEvent(evt)
			return true
		end
	end
	-- if self.focus then
	-- 	self.focus:onEvent(evt)
	-- 	-- elem_focus = nil
	-- 	self.focus = nil
	-- 	-- return true
	-- end
end

local function close_pressed(self)
	sys.process_end(self.root.id)
	for i,v in ipairs(windows_visible) do
		if v == windows[_WM.docker_pid] then
			return
		end
	end
	table.insert(windows_visible, windows[_WM.docker_pid])
end

local function minimize_pressed(self)
	_WM.close_window(self.root.id, true)
end

--СОГЛАСИЕ СОЗДАТЕЛЯ BRAUNNOS
--Я РАЗРЕШАЮ НИКИТЕ ТРЕТЬЯКОВУ, ВНОСИТЬ ИЗМЕНЕНИЯ В КОД ПРОЕКТА WMANAGER
--ПОДПИСЬ: Артём

local function maximize_pressed(self, c_x)
	local win = self.root
	if win.maximize then
		if c_x then win.offset_x = math.floor((win.old_w / win.w) * c_x) end
		window_reposition(win, win.old_x, win.old_y, win.old_w, win.old_h)
		win.maximize = false
		win.old_x, win.old_y = nil, nil
		win.old_w, win.old_h = nil, nil
		need_resize = true
		return
	end
	win.old_x, win.old_y = win.x, win.y
	win.old_w, win.old_h = win.w, win.h
	local n_w, n_h = MAXIMIZE_W, MAXIMIZE_H
	window_reposition(win, 1, desktop_mode and 2 or 1, n_w, desktop_mode and n_h - 1 or n_h)
	win.maximize = true
	need_resize = true
end

local function title_fill(win, menu)
	if not win.border then return end
	local btn_ico = desktop_mode and "\7" or "x"
	local x = desktop_mode and win.x or win.w + win.x - 1
	local lightGray = desktop_mode and colors.lightGray or nil

	-- local close = UI.Button(x, win.y, 1, 1, btn_ico, _, {font2 = lightGray, bg = COLORS.TITLE[1], font = colors.red})
	local close = UI.Button({
		x = x, y = win.y,
		w = 1, h = 1,
		fc_cl = lightGray,
		bc_cl = gray,
		bc = COLORS.TITLE[1],
		fc = colors.red,
		text = btn_ico,
	})
	close.pressed = close_pressed
	close.root = win

	if not desktop_mode then
		if menu then
			menu.x = win.x
			menu.y = win.y
			menu.color_bg = colors.white
			menu.color_txt = colors.black
			menu.parent = win
			menu.root = win
		end
		return close, menu
	end

	-- local minimize = UI.Button(x + 1, win.y, 1, 1, btn_ico, _, {font2 = lightGray, bg = colors.gray, font = colors.orange})
	local minimize = UI.Button({
		x = x + 1, y = win.y,
		w = 1, h = 1,
		fc_cl = lightGray,
		bc_cl = gray,
		bc = COLORS.TITLE[1],
		fc = colors.orange,
		text = btn_ico,
	})

	minimize.pressed = minimize_pressed
	minimize.root = win


	-- local maximize = UI.Button(x + 2, win.y, 1, 1, btn_ico, _, {font2 = lightGray, bg = colors.gray, font = colors.green})
	local maximize = UI.Button({
		x = x + 2, y = win.y,
		w = 1, h = 1,
		fc_cl = lightGray,
		bc_cl = gray,
		bc = COLORS.TITLE[1],
		fc = colors.green,
		text = btn_ico,
	})
	maximize.pressed = maximize_pressed
	maximize.root = win

	return close, minimize, maximize
end

-- local function addChild(self, child)
-- 	table.insert(self.children, child)
-- end

function _WM.create(title, x, y, w, h, border, id, order, menu)
	x = desktop_mode and x or DEFAULT_X
	y = desktop_mode and y or DEFAULT_Y
	w = desktop_mode and w or MAXIMIZE_W
	h = desktop_mode and h or MAXIMIZE_H
	local win = {}

	win.x, win.y = x, y
	win.w, win.h = w, h
	win.title = title
	-- win.border = desktop_mode and border or true
	win.border = border
	-- win.border = false
	y = border and y + 1 or y
	h = border and h - 1 or h
	win.term = window.create(screen, x, y, w, h, false)
	win.id = id
	win.is_draggable = desktop_mode
	win.maximize = (not desktop_mode)
	win.children = { title_fill(win, menu) }
	win.order = order or 2

	windows[id] = win
	_G.global_menu = menu
	window_set_focus(win)
	-- table.insert(windows_visible, win)
	if _WM.docker_pid then sys.ipc(_WM.docker_pid, "docker_add", id) end

	return win
end

function _WM.minimize_window(win)
	for i = #windows_visible, 1, -1 do
		if windows_visible[i] == win then
			table.remove(windows_visible, i)
			break
		end
	end
end

function _WM.close_window(pid, bool)
	if not windows[pid] then return end
	for i = #windows_visible, 1, -1 do
		if windows_visible[i].id == pid then
			table.remove(windows_visible, i)
			break
		end
	end
	window_set_focus(windows_visible[#windows_visible])
	if bool then return end
	windows[pid] = nil
	if _WM.docker_pid then sys.ipc(_WM.docker_pid, "docker_remove", pid) end
end

local function visible_sort()
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

function _WM.redraw_all()
	visible_sort()

	for _, win in ipairs(windows_visible) do
		local win_term = win.term
		win_draw(win)
		win_term.setVisible(true)
		win_term.setVisible(false)
	end

	for i = 1, #popup_windows do
		local p = popup_windows[i]
		if p and not p.closed then p:draw() end
	end

	-- for i = 1, #popup_windows do
	-- 	local p = popup_windows[i]
	-- 	if p then
	-- 		p:onLayout()
	-- 		p:redraw()
	-- 	end
	-- end

	screen.setVisible(true)
	screen.setVisible(false)
	if window_focus then
		local native = term.native()
		local cursor = window_focus.term.getCursorBlink()
		local txtCol = window_focus.term.getTextColor()
		local x, y = window_focus.term.getCursorPos()
		local t_x, t_y = window_focus.term.getPosition()
		native.setCursorBlink(cursor)
		native.setTextColor(txtCol)
		native.setCursorPos(t_x + x - 1, t_y + y - 1)
	end
end

function _WM.dispatch_event(evt)
	local event_name = evt[1]

	if #popup_windows > 0 then
		for i = #popup_windows, 1, -1 do
			local p = popup_windows[i]
			if not p then
				table.remove(popup_windows, i)
			else
				local res = p:handleEvent(evt)
				if res and res.consumed then
					if res.open then
						table.remove(popup_windows, i + 1)
						table.insert(popup_windows, i + 1, res.open)
					end
					if p.closed then table.remove(popup_windows, i) end
					return true
				end
				if p.closed then table.remove(popup_windows, i) end
			end
		end
	end

	-- if event_name == "wm_popup_close" then
	-- 	popup_windows = {}
	-- end

	-- if #popup_windows > 0 then
	-- 	if _WM.uiserver_pid then
	-- 		sys.ipc(_WM.uiserver_pid, table.unpack(evt))
	-- 		return true
	-- 	end
	-- end

	if EVENTS.MOUSE[event_name] then
		local c_x, c_y = evt[3], evt[4]
		if not (c_x and c_y) then return true end

		if win_held and win_held.is_draggable then
			if event_name == "mouse_up" then
				win_held.offset_x = nil
				win_held.offset_y = nil
				win_held = nil
			elseif event_name == "mouse_drag" then
				if win_held.maximize then
					win_held.children[3]:pressed(c_x)
					return { win_held.id, { "term_resize", win_held.w, win_held.h - 1 } }
				end
				window_reposition(win_held, c_x - win_held.offset_x, math.max(2, c_y), win_held.w, win_held.h)
			end
			return true
		end

		if window_focus and window_focus.resizing then
			if event_name == "mouse_up" then
				window_focus.resizing = false
			elseif event_name == "mouse_drag" then
				local new_w = math.max(MIN_W, c_x - window_focus.x + 1)
				local new_h = math.max(MIN_H, c_y - window_focus.y + 1)
				if new_w ~= window_focus.w or new_h ~= window_focus.h then
					window_reposition(window_focus, window_focus.x, window_focus.y, new_w, new_h)
					return { window_focus.id, { "term_resize", window_focus.w, window_focus.h - 1 } }
				end
			end
		end

		if EVENTS.TOP[event_name] then
			for i = #windows_visible, 1, -1 do
				local win = windows_visible[i]
				if win.border and title_handler(win, evt) then
					return true
				end
				if check(win, c_x, c_y) then
					if not (event_name == "mouse_move" or event_name == "mouse_drag") then window_set_focus(win) end
					local resize_zone = (c_x >= win.x + win.w - 1 and c_y >= win.y + win.h - 1)
					if resize_zone and win.border and event_name == "mouse_click" then
						win.resizing = true
					end
					if term_check(win, c_x, c_y) then
						local rel_x = c_x - win.x + 1
						local rel_y = c_y - win.y + (win.border and 0 or 1)
						evt[3], evt[4] = rel_x, rel_y
						return { win.id, evt }
					end

					if not win.border then return true end
					if event_name == "mouse_click" then
						win.offset_x = c_x - win.x
						win_held = win
					end
					return true
				end
			end
		else
			if window_focus then
				if window_focus.border and title_handler(window_focus, evt) then
					if need_resize then
						need_resize = nil
						return { window_focus.id, { "term_resize", window_focus.w, window_focus.h - 1 } }
					end
				end
				local rel_x = c_x - window_focus.x + 1
				local rel_y = c_y - window_focus.y + (window_focus.border and 0 or 1)
				evt[3], evt[4] = math.max(0, rel_x), math.max(0, rel_y)
				return { window_focus.id, evt }
			end
		end
		return true
	elseif EVENTS.FOCUS[event_name] then
		if window_focus then
			return { window_focus.id, evt }
		end
		-- return true
	elseif event_name == "term_resize" then
		local w, h = evt[2], evt[3]
		MAXIMIZE_W, MAXIMIZE_H = w, h
		screen.reposition(1, 1, w, h)
		for i = #windows_visible, 1, -1 do
			local win = windows_visible[i]

			if win.maximize then
				local n_h = win.border and 1 or 0
				window_reposition(win, 1, win.y, w, h - win.y + 1)
				sys.ipc(win.id, "term_resize", w, win.h - n_h)
			elseif win.x > w or win.y > h then
				local x = win.x > w and win.x - w or win.x
				local y = win.y > h and math.max(2, win.y - h) or win.y
				window_reposition(win, x, y)
			end
		end

		if _WM.panel_pid then sys.ipc(_WM.panel_pid, "term_resize", w, h) end
		if _WM.docker_pid then sys.ipc(_WM.docker_pid, "term_resize", w, h) end
		if _WM.desktop_pid then sys.ipc(_WM.desktop_pid, "term_resize", w, h) end
		return true
	elseif EVENTS.WM[event_name] then
		if event_name == "wm_reposition" then
			local win = windows[evt[2]]
			local old_w, old_h = win.w, win.h

			window_reposition(win, evt[3], evt[4], evt[5], evt[6])

			if win.w ~= old_w or win.h ~= old_h then
				return { win.id, { "term_resize", MAXIMIZE_W, MAXIMIZE_H } }
			end
		elseif event_name == "wm_restore" then
			local win = windows[evt[2]]
			window_set_focus(win)
		-- elseif event_name == "wm_minimize" then
		-- 	_WM.close_window(evt[2], true)
		end
		return true
	end
end

return _WM
