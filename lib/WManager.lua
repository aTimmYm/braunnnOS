local screen = window.create(term.current(), 1, 1, term.getSize())
screen.setVisible(false)
term.redirect(screen)

local sys = require "sys"
local UI = require "ui2"
-- local dm = dofile("lib/DManager.lua")
local dm = require "DManager"
-- local docker = require "docker"
local c = require "cfunc"
local conf = c.readConf("usr/settings.conf")

local desktop_mode = conf["DesktopMode"]
local _wmanager = {}
local _rep = string.rep
-- local to_blit = colors.toBlit
local windows_visible = {}
local windows = {}
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
		["mouse_up"] = true,
		["mouse_drag"] = true,
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
	local center = math.floor((self.w - btns - #self.title)/2) + 1
	term.setBackgroundColor(window_focus == self and COLORS.TITLE[1] or colors.lightGray)
	term.setCursorPos(self.x, self.y)
	term.write(_rep(" ",self.w))
	term.setTextColor(COLORS.TITLE[2])
	term.setCursorPos(center + self.x, self.y)
	term.write(self.title)
	for i, child in ipairs(self.children) do
		child.color_txt = window_focus == self and COLORS.BUTTONS[i] or colors.gray
		child.color_bg = window_focus == self and COLORS.TITLE[1] or colors.lightGray
		child:draw()
	end
end

local function window_reposition(win, x, y, w, h)
	local n_x = desktop_mode and x or (w or win.w) + x - 1
	for i, child in ipairs(win.children) do
		child.x, child.y = n_x + i - 1, y
	end

	win.x, win.y = x, y
	if w and h then win.w, win.h = w, h end
	y = win.border and y + 1 or y
	h = win.border and h - 1 or h
	win.term.reposition(x, y, w, h)
	-- if win.h + win.y - 1 >= MAXIMIZE_H - 1 then
	-- 	docker.hide(true)
	-- else
	-- 	docker.hide(false)
	-- end
end

local function visible_sort()
	local buffer = {table.unpack(windows_visible)}
	local count = #buffer
	local k = 0
	windows_visible = {}
	while true do
		for _, win in ipairs(buffer) do
			if win.order == k then
				table.insert(windows_visible, win)
				count = count - 1
			end
		end
		k = k + 1
		if count < 1 then break end
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
end

local function title_handler(win, evt, id)
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
end

local function minimize_pressed(self)
	_wmanager.close_window(self.root.id, true)
end

--СОГЛАСИЕ СОЗДАТЕЛЯ BRAUNNOS
--Я РАЗРЕШАЮ НИКИТЕ ТРЕТЬЯКОВУ, ВНОСИТЬ ИЗМЕНЕНИЯ В КОД ПРОЕКТА WMANAGER ПОДПИСЬ: Артём

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
	local btn_ico = desktop_mode and string.char(7) or "x"
	local x = desktop_mode and win.x or win.w + win.x - 1
	local lightGray = desktop_mode and colors.lightGray or nil

	local close = UI.Button(x, win.y, 1, 1, btn_ico, _, lightGray, COLORS.TITLE[1], colors.red)
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

	local minimize = UI.Button(x + 1, win.y, 1, 1, btn_ico, _, lightGray, colors.gray, colors.orange)
	minimize.pressed = minimize_pressed
	minimize.root = win

	local maximize = UI.Button(x + 2, win.y, 1, 1, btn_ico, _, lightGray, colors.gray, colors.green)
	maximize.pressed = maximize_pressed
	maximize.root = win

	-- sys.ipc(_wmanager.panel_pid, "global_menu", )
	-- dm.set_global_menu(menu)

	return close, minimize, maximize
end

local function addChild(self, child)
	table.insert(self.children, child)
end

function _wmanager.create(title, x, y, w, h, border, id, order)
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
	win.offset_x = 0
	win.offset_y = 0
	win.maximize = (not desktop_mode)
	win.children = {title_fill(win, menu)}
	win.order = order or 1

	windows[id] = win
	window_set_focus(win)
	-- table.insert(windows_visible, win)
	if _wmanager.docker_pid then sys.ipc(_wmanager.docker_pid, "docker_add", id) end

	return win
end

function _wmanager.minimize_window(win)
	for i = #windows_visible, 1, -1 do
		if windows_visible[i] == win then
			table.remove(windows_visible, i)
			break
		end
	end
end

function _wmanager.close_window(pid, bool)
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
	if _wmanager.docker_pid then sys.ipc(_wmanager.docker_pid, "docker_remove", pid) end
end

function _wmanager.redraw_all()
	visible_sort()
	dm.draw()
	-- term.setBackgroundColor(colors.lightBlue)
	-- term.clear()
	for _, win in ipairs(windows_visible) do
		local win_term = win.term
		win_draw(win)
		win_term.setVisible(true)
		win_term.setVisible(false)
	end

	screen.setVisible(true)
	screen.setVisible(false)
end

function _wmanager.dispatch_event(evt)
	local event_name = evt[1]

	if EVENTS.MOUSE[event_name] then
		local c_x, c_y = evt[3], evt[4]

		if win_held and win_held.is_draggable and event_name == "mouse_drag" then
			if win_held.maximize then
				win_held.children[3]:pressed(c_x)
				return {win_held.id, {"term_resize", win_held.w, win_held.h - 1}}
			end
			window_reposition(win_held, c_x - win_held.offset_x, math.max(2, c_y), win_held.w, win_held.h)
			return true
		end

		if window_focus and window_focus.resizing then
			if event_name == "mouse_drag" then
				local new_w = math.max(MIN_W, c_x - window_focus.x + 1)
				local new_h = math.max(MIN_H, c_y - window_focus.y + 1)
				if new_w ~= window_focus.w or new_h ~= window_focus.h then
					window_reposition(window_focus, window_focus.x, window_focus.y, new_w, new_h)
					return {window_focus.id, {"term_resize", window_focus.w, window_focus.h - 1}}
				end
			elseif event_name == "mouse_up" then
				window_focus.resizing = false
			end
		end

		for i = #windows_visible, 1, -1 do
			local win = windows_visible[i]
			if win.border and title_handler(win, evt, i) then
				if need_resize then
					need_resize = nil
					return {win.id, {"term_resize", win.w, win.h - 1}}
				end
				return true
			end
			if check(win, c_x, c_y) then
				window_set_focus(win)
				local resize_zone = (c_x >= win.x + win.w - 1 and c_y >= win.y + win.h - 1)
				if resize_zone and win.border and event_name == "mouse_click" then
					win.resizing = true
				end
				if term_check(win, c_x, c_y) then
					local rel_x = c_x - win.x + 1
					local rel_y = c_y - win.y + (win.border and 0 or 1)
					evt[3], evt[4] = rel_x, rel_y
					return {win.id, evt}
				end

				if not win.border then return true end
				if event_name == "mouse_click" then
					win.offset_x = c_x - win.x
					win_held = win
				elseif event_name == "mouse_up" then
					win_held = nil
				end
				return true
			end
		end
		dm.event_handler(evt)
		return true
	elseif EVENTS.FOCUS[event_name] then
		if window_focus then
			return {window_focus.id, evt}
		end
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
		dm.resize(w, h)

		if _wmanager.panel_pid then sys.ipc(_wmanager.panel_pid, "term_resize", w, h) end
		if _wmanager.docker_pid then sys.ipc(_wmanager.docker_pid, "term_resize", w, h) end
		return true
	elseif EVENTS.WM[event_name] then
		if event_name == "wm_reposition" then
			local win = windows[evt[2]]
			local old_w, old_h = win.w, win.h

			window_reposition(win, evt[3], evt[4], evt[5], evt[6])

			if win.w ~= old_w or win.h ~= old_h then
				return {win.id, {"term_resize", MAXIMIZE_W, MAXIMIZE_H}}
			end
		elseif event_name == "wm_restore" then
			local win = windows[evt[2]]
			window_set_focus(win)
		end
		return true
	end
end

return _wmanager