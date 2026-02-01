local Popup = {}
local rep = string.rep
local screen_w, screen_h = term.getSize()

local function calc_width(items)
	local mw = 0
	for _, it in ipairs(items) do
		local l = #tostring(it.text or "")
		if l > mw then mw = l end
	end
	return mw + 2
end

local function fit_on_screen(x, y, w, h)
	local nx, ny = x, y
	if nx + w - 1 > screen_w then nx = math.max(1, screen_w - w + 1) end
	if ny + h - 1 > screen_h then ny = math.max(1, screen_h - h + 1) end
	return nx, ny
end

-- items: { { text = "...", onClick = fn, submenu = { ... } }, ... }
function Popup.create(items, x, y, width, opts, term)
	opts = opts or {}
	width = width or calc_width(items)
	local height = #items
	local p = {}
	p.x, p.y = x, y
	p.w, p.h = width, height
	p.items = items
	p.selected = 0
	p.closed = false
	p.child = nil
	p.term = window.create(term, x, y, width, height, false)
	p.bg = opts.bgColor or colors.black
	p.fg = opts.text or colors.white
	p.sel_bg = opts.selBg or colors.lightGray
	p.sel_fg = opts.selText or colors.black
	p.border = opts.border or false

	local function redraw_self(self)
		if self.closed then return end
		local t = self.term
		t.setVisible(true)
		t.setBackgroundColor(self.bg)
		t.clear()
		for i, it in ipairs(self.items) do
			t.setCursorPos(1, i)
			if i == self.selected then
				t.setBackgroundColor(self.sel_bg)
				t.setTextColor(self.sel_fg)
			else
				t.setBackgroundColor(self.bg)
				t.setTextColor(self.fg)
			end
			local txt = tostring(it.text or "")
			t.write(txt .. rep(" ", self.w - #txt))
			if it.submenu then
				t.setCursorPos(self.w, i)
				t.write("\16")
			end
		end
		t.setVisible(false)
	end

	function p:draw()
		redraw_self(self)
	end

	function p:close()
		if self.closed then return end
		self.closed = true
		if self.child then
			self.child:close()
			self.child = nil
		end
		p.term.setVisible(false)
		if self.onClose then self.onClose(self) end
	end

	function p:activate(index)
		local it = self.items[index]
		if it then
			if it.onClick then it.onClick(it) end
			if not it.submenu then
				self:close()
			end
		end
	end

	function p:handleEvent(evt)
		if self.closed then return {consumed = false} end
		local et = evt[1]
		if et == "mouse_click" then
			local cx, cy = evt[3], evt[4]
			if cx >= self.x and cx < self.x + self.w and cy >= self.y and cy < self.y + self.h then
				local ry = cy - self.y + 1
				local it = self.items[ry]
				if it then
					if it.submenu then
						local sx = self.x + self.w
						local sy = self.y + ry - 1
						local sw = calc_width(it.submenu)
						local sh = #it.submenu
						sx, sy = fit_on_screen(sx, sy, sw, sh)
						local child = Popup.create(it.submenu, sx, sy, sw, { bgColor = self.bg, text = self.fg }, term)
						self.child = child
						return { consumed = true, open = child }
					else
						if it.onClick then it.onClick(it) end
						self:close()
						return { consumed = true, close = true }
					end
				end
				return { consumed = true }
			else
				self:close()
				return { consumed = true, close = true }
			end
		elseif et == "mouse_move" then
			local cx, cy = evt[3], evt[4]
			if cx >= self.x and cx < self.x + self.w and cy >= self.y and cy < self.y + self.h then
				local ry = cy - self.y + 1
				if ry ~= self.selected then
					self.selected = math.max(1, math.min(#self.items, ry))
					local it = self.items[self.selected]
					if it and it.submenu then
						local sx = self.x + self.w
						local sy = self.y + self.selected - 1
						local sw = calc_width(it.submenu)
						local sh = #it.submenu
						sx, sy = fit_on_screen(sx, sy, sw, sh)
						local child = Popup.create(it.submenu, sx, sy, sw, { bgColor = self.bg, text = self.fg }, term)
						self.child = child
						return { consumed = true, open = child }
					else
						if self.child then
							self.child:close()
							self.child = nil
						end
					end
				end
				return { consumed = true }
			else
				return { consumed = false }
			end
		elseif et == "key" then
			local key = evt[2]
			if key == keys.up then
				self.selected = math.max(1, self.selected - 1)
				return { consumed = true }
			elseif key == keys.down then
				self.selected = math.min(#self.items, self.selected + 1)
				return { consumed = true }
			elseif key == keys.enter or key == keys.space then
				local it = self.items[self.selected]
				if it then
					if it.submenu then
						local sx = self.x + self.w
						local sy = self.y + self.selected - 1
						local sw = calc_width(it.submenu)
						local sh = #it.submenu
						sx, sy = fit_on_screen(sx, sy, sw, sh)
						local child = Popup.create(it.submenu, sx, sy, sw, { bgColor = self.bg, text = self.fg }, term)
						self.child = child
						return { consumed = true, open = child }
					else
						if it.onClick then it.onClick(it) end
						self:close()
						return { consumed = true, close = true }
					end
				end
			elseif key == keys.left or key == keys.esc then
				self:close()
				return { consumed = true, close = true }
			end
		end
		return { consumed = false }
	end

	return p
end

return Popup