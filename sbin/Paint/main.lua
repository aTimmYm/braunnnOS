local sys = require 'syscalls'
local c = require 'cfunc'
local UI = require 'ui2'
local S_WIDTH, S_HEIGHT = sys.screen_get_size()
local global_menu = UI.Menu()

sys.register_window('Paint', math.floor((S_WIDTH - 34) / 2) + 1, math.floor((S_HEIGHT - 14) / 2) + 1, 34, 14, true, _, global_menu)
local self_pid = sys.getpid()

local tw, th = term.getSize()

local cur_l_col, cur_r_col = colors.white, _
local image = {}
local col_toBlit = {}
for i = 0, 15 do
	col_toBlit[2 ^ i] = string.format("%x", i)
end

local col_fromBlit = {}
for n = 1, 16 do
	col_fromBlit[string.byte("0123456789abcdef", n, n)] = 2 ^ (n - 1)
end

local root = UI.Root()

local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.gray,
	fc = colors.white
})

root:addChild(surface)

local scrollBox = UI.ScrollBox({
	x = 1, y = 2,
	w = root.w - 1, h = root.h - 2,
	bc = colors.gray,
	fc = colors.white,
})

surface:addChild(scrollBox)

local v_scroll = UI.Scrollbar(scrollBox)
surface:addChild(v_scroll)

local h_scroll = UI.Scrollbar_Horizontal(scrollBox)
surface:addChild(h_scroll)

local paintBox = UI.Box({
	x = 1, y = 1,
	w = 20, h = 10,
	bc = colors.gray,
	fc = colors.lightGray
})
scrollBox:addChild(paintBox)

local textfield = UI.Textfield({
	x = 20, y = 1,
	w = surface.w - 20, h = 1,
	hint = "write here",
	bc = colors.gray,
	fc = colors.white,
})
surface:addChild(textfield)

local function getPixel(x, y)
	if image[y] then
		return image[y][x]
	end
	return
end

local function getCharOf(color)
	if type(color) == "number" then
		local value = math.floor(math.log(color) / math.log(2)) + 1
		if value >= 1 and value <= 16 then
			return string.sub("0123456789abcdef", value, value)
		end
	end
	return " "
end

local function open(args)

end

local function drawLine(self, line)
	local text, fc, bc = "", "", ""
	for x = 1, self.w do
		local pixel = getPixel(x, line)
		if pixel then
			text = text .. " "
			fc = fc .. "0"
			bc = bc .. col_toBlit[pixel or self.bc]
		else
			text = text .. "\127"
			fc = fc .. col_toBlit[self.fc]
			bc = bc .. col_toBlit[self.bc]
		end
	end

	term.setCursorPos(self.x, self.y + line - 1)
	term.blit(text, fc, bc)
end

local function paint_drawPixel(self, btn, x, y)
	local color
	if btn == 1 then color = cur_l_col
	elseif btn == 2 then color = cur_r_col end
	if self:check(x, y) then
		local lx, ly = x - self.x + 1, y - self.y + 1
		if not image[ly] then image[ly] = {} end
		image[ly][lx] = color
		-- local old = term.redirect(scrollBox.win)
		drawLine(paintBox, ly)
		-- term.redirect(old)
		-- self.dirty = true
	end
end

surface.draw = function (self)
	paintutils.drawFilledBox(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1, self.bc)
	term.setCursorPos(self.x, self.y)
	local l_col = col_toBlit[cur_l_col] or col_toBlit[self.bc]
	local r_col = col_toBlit[cur_r_col] or col_toBlit[self.bc]
	local l_bg = (cur_l_col == self.bc) and col_toBlit[colors.lightGray] or col_toBlit[self.bc]
	local r_bg = (cur_r_col == self.bc) and col_toBlit[colors.lightGray] or col_toBlit[self.bc]
	term.blit("\4\4", l_col .. r_col, l_bg .. r_bg)
	term.blit(string.rep("\143", 16), "0123456789abcdef", string.rep(col_toBlit[self.bc], 16))
	term.blit("\127", col_toBlit[paintBox.bc], col_toBlit[paintBox.fc])
end

paintBox.draw = function(self)
	for y = 1, self.h do
		drawLine(self, y)
	end
	term.setCursorPos(self.w + self.x, self.h + self.y)
	term.blit("\129", "0", col_toBlit[self.bc])
end

local file_items = {
	{text = "New", onClick = function(args)
		image = {}
		paintBox.w = 20
		paintBox.h = 10
		scrollBox:onLayout()
		sys.ipc(self_pid, {"redraw_meow"})
	end},
	{text = "Open", onClick = function(args)
		local path = args.tf.text
		if (fs.isDir(path) or not fs.exists(path)) then
			args.tf.text = "File not found"
			args.tf.dirty = true
			sys.ipc(self_pid, {"redraw_meow"})
			return
		end
		local lines = {}
		local i = 1
		image = {}
		for line in io.lines(path) do
			table.insert(lines, line)
			image[i] = {}
			for x = 1, #line do
				image[i][x] = col_fromBlit[string.byte(line, x, x)]
			end
			i = i + 1
		end
		paintBox.w = c.findMaxLenStrOfArray(lines)
		paintBox.h = #lines
		scrollBox:onLayout()
		sys.ipc(self_pid, {"redraw_meow"})
	end, tf = textfield},
	{text = "Save", onClick = function(args)
		local file = fs.open(args.tf.text, 'w')
		for y = 1, paintBox.h do
			for x = 1, paintBox.w do
				file.write(getCharOf(getPixel(x, y)))
			end
			if y ~= paintBox.h then
				file.write("\n")
			end
		end
		file.close()
	end, tf = textfield},
	{text = "Save as", onClick = function ()

	end},
}
local edit_items = {
	{text = "Clear", onClick = function ()
		image = {}
		paintBox.dirty = true
		sys.ipc(self_pid, {"redraw_meow"})
	end},
}

global_menu:add_context("File").pressed = function (self)
	sys.create_popup(file_items, self.x, self.y + 1)
end

global_menu:add_context("Edit").pressed = function (self)
	sys.create_popup(edit_items, self.x, self.y + 1)
end

paintBox.onMouseDown = function(self, btn, x, y)
	paint_drawPixel(self, btn, x, y)
	return true
end

paintBox.onMouseDrag = function(self, btn, x, y)
	paint_drawPixel(self, btn, x, y)
	return true
end

scrollBox.onMouseDown = function(self, btn, x, y)
	if (x == paintBox.x + paintBox.w) and (y == paintBox.y + paintBox.h) then
		self.resize = true
	end
	return true
end

scrollBox.onMouseUp = function(self, btn, x, y)
	self.resize = false
	return true
end

scrollBox.onMouseDrag = function(self, btn, x, y)
	if self.resize then
		paintBox.w = x - self.x + self.scroll.pos_x
		paintBox.h = y - self.y + self.scroll.pos_y
		paintBox.dirty = true
		self.dirty = true
	end
	return true
end

surface.onMouseDown = function(self, btn, x, y)
	local function func(p)
		if btn == 1 then
			cur_l_col = p
		elseif btn == 2 then
			cur_r_col = p
		end
	end

	if x >= self.x - 1 + 3 and x <= self.x - 1 + 18 then -- (3, 18)
		func(2 ^ (x - 2 - self.x))
	elseif x == self.x - 1 + 19 then -- 19
		func()
	end
	surface:onLayout()
	return true
end

surface.onResize = function(W, H)
	surface.w, surface.h = W, H
	scrollBox.w, scrollBox.h = W - 1, H - 2
	v_scroll.local_x, v_scroll.h = W, H - 2
	h_scroll.local_y, h_scroll.w = H, W - 1
	textfield.w = W - 20
	-- paintBox.w, paintBox.h = scrollBox.w, scrollBox.h - 1
end

root:mainloop()
