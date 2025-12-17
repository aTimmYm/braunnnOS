local UI_PATH = "https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/installer/ui_installer.lua"
local response, err = http.get(UI_PATH)
local UI_FILE = fs.open("temp.lua", "w")
if err then error(tostring(err)) return end
UI_FILE.write(response.readAll())
UI_FILE.close()

package.path = package.path .. ";/?" .. ";/?.lua"
local UI = require "temp"
fs.delete("temp.lua")

local next, release, terM = false, "RELEASE", _

local win = window.create(term.current(), 1, 1, term.getSize())
term.redirect(win)

local root = UI.New_Root()

local surface = UI.New_Box(1, 1, root.w, root.h, colors.gray)
root:addChild(surface)

local user_agreement_term = window.create(win, 2, 2, root.w - 3, root.h - 6, true)
local user_agreement_box = UI.New_ScrollBox(2, 2, root.w - 3, root.h - 6, user_agreement_term, colors.lightGray)
surface:addChild(user_agreement_box)
local scrollbar = UI.New_Scrollbar(user_agreement_box)
surface:addChild(scrollbar)

user_agreement_box:addChild(UI.New_Label(1, 1, user_agreement_box.w, 1, "USER AGREEMENTS", _, user_agreement_box.color_bg))
user_agreement_box:addChild(UI.New_Label(1, 3, user_agreement_box.w, 12, [[-- braunnnOS - TEST
-- Copyright (C) 2025 braunnnOS
-- SPDX-License-Identifier: GPL-3.0-or-later

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
]], "left top", user_agreement_box.color_bg))

local checkbox = UI.New_Checkbox(2, root.h - 2, _, colors.black, colors.white)
surface:addChild(checkbox)

local label_checkbox = UI.New_Label(checkbox.x + 2, checkbox.y, 20, 2, "I agree to the terms and conditions", "left", surface.color_bg, colors.white)
surface:addChild(label_checkbox)

local inst_next = UI.New_Button(root.w - 7 - 3 - 6 - 2, root.h - 3, 9, 3, "Next")
surface:addChild(inst_next)

local canc = UI.New_Button(root.w - 6 - 2, root.h - 3, 8, 3, "Cancel")
surface:addChild(canc)

local function install(url)
	local manifest_url = url.."manifest.txt"

	local function write_f(path, data)
		local file = fs.open(path, "w")
		file.write(data)
		file.close()
	end

	local response, err = http.get(manifest_url)
	if response then
		local temp = response.readAll()
		response.close()
		for line in temp:gmatch("([^\n]+)\n?") do
			local value = line:sub(36)
			local request = http.get(url..value)
			if request then
				print("Downloading "..value)
				write_f(value,request.readAll())
				request.close()
			end
		end
		local file = fs.open("manifest.txt","w")
		file.write(temp)
		file.close()
		print("Installing success. Rebooting")
		os.sleep(2)
		os.reboot()
	else
		print(err)
	end
end

inst_next.pressed = function (self)
	if next then
		term.redirect(terM)
		win.setVisible(true)
		if release == "RELEASE" then
			install("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/main/")
		elseif release == "DEV" then
			install("https://raw.githubusercontent.com/aTimmYm/braunnnOS/refs/heads/dev/")
		end
		term.redirect(win)
		return
	end

	if not checkbox.on then return end
	self:setText("Install")
	next = true
	surface:removeChild(label_checkbox)
	surface:removeChild(user_agreement_box)
	surface:removeChild(user_agreement_box.scrollbar_v)
	surface:removeChild(checkbox)

	local drop_label = UI.New_Label(2, 2, 15, 1, "Choose version:", "left", colors.gray, colors.white)
	surface:addChild(drop_label)

	local dropdown = UI.New_Dropdown(root.w - 10, 2, {"DEV", "RELEASE"}, "RELEASE", 10, _, colors.white, colors.black)
	dropdown.pressed = function (self, name)
		release = name
	end
	surface:addChild(dropdown)
	surface:draw()
	canc.dirty = true
	terM = window.create(win, 2, 4, root.w - 2, root.h - 8, true)
	terM.setBackgroundColor(colors.lightGray)
	terM.setTextColor(colors.white)
	terM.clear()
end

canc.pressed = function (self)
	root.running_program = false
end

root:mainloop()