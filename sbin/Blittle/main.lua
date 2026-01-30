local sys = require "syscalls"
local blittle = require "blittle_extended"
local UI = require "ui2"

sys.register_window("Blittle", 1, 2, 39, 14, true)

local root = UI.Root()

-- local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
local surface = UI.Box({
	x = 1, y = 1,
	w = root.w, h = root.h,
	bc = colors.black,
	fc = colors.white,
})
root:addChild(surface)

-- local pole1 = UI.Textfield(2, 2, 37, 1, "Path to the Image.nfp", false, colors.gray, colors.lightBlue)
local pole1 = UI.Textfield({
	x = 2, y = 2,
	w = 37, h = 1,
	hint = "Path to the Image.nfp",
	bc = colors.gray,
	fc = colors.lightBlue,
})
surface:addChild(pole1)

-- local pole2 = UI.Textfield(2, 5, 37, 1, "Path to Save", false, colors.gray, colors.lightBlue)
local pole2 = UI.Textfield({
	x = 2, y = 5,
	w = 37, h = 1,
	hint = "Path to Save",
	bc = colors.gray,
	fc = colors.lightBlue,
})
surface:addChild(pole2)

-- local knopkacheck = UI.Button(2, 7, 9, 3, "Check", "center", _, colors.white, colors.black)
local knopkacheck = UI.Button({
	x = 2, y = 7,
	w = 9, h = 3,
	text = "Check",
	align = "center",
	bc = colors.white,
	fc = colors.black,
})
surface:addChild(knopkacheck)

local imageCheck

-- local knopkasave = UI.Button(12, 7, 9, 3, "Save", "center", _, colors.white, colors.black)
local knopkasave = UI.Button({
	x = 12, y = 7,
	w = 9, h = 3,
	text = "Save",
	align = "center",
	bc = colors.white,
	fc = colors.black,
})
surface:addChild(knopkasave)

knopkacheck.pressed = function(self)
	if pole1.text == "" or not fs.exists(pole1.text) then return end
	imageCheck = blittle.shrink(paintutils.loadImage(pole1.text))
	--blittle.draw(imageCheck, knopkasave.x + knopkasave.w + 10, 7)
	surface:onLayout()
end

knopkasave.pressed = function(self)
	if pole2.text =="" or not imageCheck then return end
	blittle.save(imageCheck, pole2.text)
end

surface.draw = function (self)
	paintutils.drawFilledBox(self.x, self.y, self.w + self.x - 1, self.h + self.y - 1, self.bc)
	if imageCheck then
		blittle.draw(imageCheck, knopkasave.x + knopkasave.w + 10, 7)
	end
end

-- local text = UI.Label(14, 13, 12, 1,"BI BASNIPE", "center", colors.lightGray, colors.gray)
local text = UI.Label({
	x = 14, y = 13,
	w = 12, h = 1,
	text = "BI BASNIPE",
	align = "center",
	bc = colors.lightGray,
	fc = colors.gray,
})
surface:addChild(text)

surface.onResize = function(w, h)
	text.local_y = h - 1
	text.local_x = (w - text.w) * 0.5
	surface.w = w
	surface.h = h
	pole1.w = w - pole1.x - 1
	pole2.w = w - pole2.x - 1
	knopkacheck.w = w * 0.25
	knopkacheck.h = h * 0.3
	knopkacheck.local_y = 7
	knopkacheck.local_x = 2
	knopkasave.local_y = knopkacheck.local_y
	knopkasave.local_x = knopkacheck.local_x + knopkacheck.w + 1
	knopkasave.w = knopkacheck.w
	knopkasave.h = knopkacheck.h
end

root:mainloop()