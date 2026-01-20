local modem
if periphemu then periphemu.create("top", "modem"); modem = peripheral.find("modem") end
rednet.open(peripheral.getName(modem))
------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_sub = string.sub
local string_gmatch = string.gmatch
local table_insert = table.insert
local table_sort = table.sort
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local sys = require "sys"
local c = require "cfunc"
local UI = require "ui2"
-----------------------------------------------------
sys.register_window("Messenger", 1, 2, 39, 14, true)
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local function create_file(path, text)
	local f = fs.open(path, "w")
	if text then f.writeLine(text) end
	f.close()
end

local function file_exists(path, text)
	if not fs.exists(path) then
		create_file(path, text)
	end
end
file_exists("sbin/Messenger/Data/account_key")
file_exists("sbin/Messenger/Data/friends", "return {}")

local currentChatHeight = 1

local account_key = c.readFile("sbin/Messenger/Data/account_key")
local friends = dofile("sbin/Messenger/Data/friends")
local protocol = "messenger"
local friendsSort = {}
local selectedFriend = {}
local serverID = rednet.lookup(protocol, "messenger_main")
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local root = UI.Root()

local surface = UI.Box(1, 1, root.w, root.h, colors.black, colors.white)
root:addChild(surface)

local usersList, msgScrollBox, textOut, msgLabel, timer
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function drawMessage(msg, direction)
	if not selectedFriend[2] then return end
	local isRight = (direction == "right")
	local color_bg = isRight and msgScrollBox.color_bg or colors.lightGray
	local color_txt = isRight and colors.lightGray or colors.white


	local lines = {}
	if #msg <= msgScrollBox.w then
		table_insert(lines, msg)
	else
		local mass = {}
		for w in string_gmatch(msg, "%S+") do
			table_insert(mass, w)
		end
		local row_txt = ""
		local i = 1
		while i <= #mass do
			local word = mass[i]
			if #word > msgScrollBox.w then
				local remainder = string_sub(word, msgScrollBox.w + 1)
				if remainder ~= "" then
					table_insert(mass, i + 1, remainder)
				end
				mass[i] = string_sub(word, 1, msgScrollBox.w)
				word = mass[i]
			end
			local space_len = (row_txt == "" and 0 or 1)
			if #row_txt + space_len + #word <= msgScrollBox.w then
				row_txt = row_txt .. (row_txt == "" and "" or " ") .. word
				i = i + 1
			else
				if row_txt ~= "" then
					table_insert(lines, row_txt)
					row_txt = ""
				end
			end
		end
	end

	local label = UI.Label(1, currentChatHeight, msgScrollBox.w, #lines, msg, direction, color_bg, color_txt)

	msgScrollBox:addChild(label)
	msgScrollBox:onLayout()

	currentChatHeight = currentChatHeight + #lines

	if currentChatHeight > msgScrollBox.h then
		msgScrollBox:onMouseScroll(currentChatHeight)
	end
end

local function userButton_pressed(self)
	if selectedFriend[1] == self.selectedFriend then return end
	selectedFriend[1] = self.selectedFriend
	selectedFriend[2] = msgScrollBox
	surface:addChild(msgScrollBox)
	surface:addChild(textOut)
	surface:onLayout()
	rednet.send(serverID, {cType = "get_chat_history", from = account_key, to = selectedFriend[1]}, protocol)
end

local function drawFriendsButtons()
	friendsSort = {}
	for k,_ in pairs(friends) do
		table_insert(friendsSort, k)
	end
	table_sort(friendsSort)
	usersList.children = {}
	for i, v in ipairs(friendsSort) do
		local userButton = UI.Button(1, i, usersList.w, 1, " "..tostring(v), "left", _, usersList.color_bg, colors.white)
		userButton.selectedFriend = friends[v]
		userButton.pressed = userButton_pressed
		usersList:addChild(userButton)
		usersList:onLayout()
	end
end

local function switchToAuth()
	surface:removeChild(true)

	msgLabel = UI.Label(1, math.floor(surface.h/2) - 3, surface.w, 1, "", "center", surface.color_bg, colors.white)
	surface:addChild(msgLabel)

	local textfieldLogin = UI.Textfield(math.floor((surface.w - 10)/2) + 1, msgLabel.local_y + 2, 10, 1, "Login", _, colors.gray, colors.white)
	surface:addChild(textfieldLogin)

	local textfieldPassword = UI.Textfield(textfieldLogin.local_x, textfieldLogin.local_y + 2, 10, 1, "Password", true, colors.gray, colors.white)
	surface:addChild(textfieldPassword)

	local buttonRegister = UI.Button(math.floor((surface.w - 10)/2) - 5, textfieldPassword.local_y + 2, 10, 1, "Register", _, _, colors.lightGray, colors.white)
	surface:addChild(buttonRegister)

	local buttonLogin = UI.Button(buttonRegister.local_x + buttonRegister.w + 1, textfieldPassword.local_y + 2, 10, 1, "Login", _, _, colors.lightGray, colors.white)
	surface:addChild(buttonLogin)

	buttonLogin.pressed = function (self)
		if textfieldLogin.text == "" then msgLabel:setText("The login field is empty") return end
		if textfieldPassword.text == "" then msgLabel:setText("The password field is empty") return end
		rednet.send(serverID, {cType = "login", login = textfieldLogin.text, password = textfieldPassword.text}, protocol)
		if not timer then timer = os.startTimer(5) end
	end

	buttonRegister.pressed = function (self)
		if textfieldLogin.text == "" then msgLabel:setText("The login field is empty") return end
		if textfieldPassword.text == "" then msgLabel:setText("The password field is empty") return end
		rednet.send(serverID, {cType = "registration", login = textfieldLogin.text, password = textfieldPassword.text}, protocol)
		if not timer then timer = os.startTimer(5) end
	end

	surface.onResize = function (width, height)
		surface.w, surface.h = width, height
		msgLabel.local_y, msgLabel.w = math.floor(height/2) - 3, width
		textfieldLogin.local_x, textfieldLogin.local_y = math.floor((width - 10)/2) + 1, msgLabel.local_y + 2
		textfieldPassword.local_x, textfieldPassword.local_y = textfieldLogin.local_x, textfieldLogin.local_y + 2
		buttonRegister.local_x, buttonRegister.local_y = math.floor((width - 10)/2) - 5, textfieldPassword.local_y + 2
		buttonLogin.local_x, buttonLogin.local_y = buttonRegister.local_x + buttonRegister.w + 1, textfieldPassword.local_y + 2
	end
end

local function switchToApp()
	surface.color_bg = colors.gray
	surface.dirty = true
	surface:removeChild(true)

	usersList = UI.ScrollBox(1, 1, math.ceil(surface.w/4), surface.h, colors.black)
	surface:addChild(usersList)

	msgScrollBox = UI.ScrollBox(usersList.w + 1, 1, surface.w - usersList.w, surface.h - 1, colors.gray)

	textOut = UI.Textfield(msgScrollBox.x, surface.h, msgScrollBox.w, 1, "Type message", _, colors.black, colors.white)

	textOut.pressed = function (self)
		drawMessage(self.text, "right")
		rednet.send(serverID, {cType = "send", from = account_key, to = selectedFriend[1], message = self.text}, protocol)
		self.text = ""
		self:moveCursorPos(1)
	end

	usersList.onResize = function (width, height)
		for _, child in ipairs(usersList.children) do
			child.w = width
		end
		-- usersList:onLayout()
	end

	msgScrollBox.onResize = function (width, _)
		for _, child in ipairs(msgScrollBox.children) do
			child.w = width
		end
	end

	surface.onResize = function (width, height)
		-- log(width)
		surface.w, surface.h = width, height
		usersList.w, usersList.h = math.ceil(width/4), height
		usersList.win.reposition(usersList.x, usersList.y, usersList.w, usersList.h)
		msgScrollBox.local_x, msgScrollBox.w, msgScrollBox.h = usersList.w + 1, width - usersList.w, height - 1
		msgScrollBox.win.reposition(msgScrollBox.x, msgScrollBox.y, msgScrollBox.w, msgScrollBox.h)
		textOut.local_x, textOut.local_y, textOut.w = msgScrollBox.local_x, height, msgScrollBox.w
		msgScrollBox.onResize(msgScrollBox.w, msgScrollBox.h)
		usersList.onResize(usersList.w, usersList.h)
	end

	drawFriendsButtons()
end

local client_handler = {
	["login"] = function (response)
		if response.login == "success" then
			local account_key_file = fs.open("sbin/Messenger/Data/account_key", "w")
			account_key_file.write(response.key)
			account_key_file.close()
			account_key = response.key
			rednet.send(serverID, {cType = "get_friends", user = account_key}, protocol)
			switchToApp()
		elseif response.login == "failure" then
			msgLabel:setText(response.error)
		end
	end,
	["registration"] = function (response)
		if response.register == "success" then
			msgLabel:setText("Registration successfully.")
		elseif response.register == "failure" then
			msgLabel:setText(response.error)
		end
	end,
	["user_add"] = function (response)
		if response.add == "failure" then
			print(response.error)
		elseif response.add == "success" then
			friends[response.username] = response.key
			local friendsFile = fs.open("sbin/Messenger/Data/friends", "w")
			friendsFile.write("return "..textutils.serialize(friends))
			friendsFile.close()
			drawFriendsButtons()
		end
	end,
	["get_chat_history"] = function (response)
		if not response then --[[Сделать обработку ошибки]] end
		currentChatHeight = 1
		msgScrollBox.children = {}
		for _, msg in pairs(response.history) do
			local dir = "left"
			if msg.from == account_key then dir = "right" end
			drawMessage(msg.message, dir)
		end
	end,
	["get_friends"] = function (response)
		local friendsFile = fs.open("sbin/Messenger/Data/friends", "w")
		friendsFile.write("return "..textutils.serialize(response.friends))
		friendsFile.close()
		friends = response.friends
		drawFriendsButtons()
	end,
	["send"] = function (response)
		drawMessage(response.message, "left")
	end,
	["lookup"] = function (response, sId)
		if response.sProtocol ~= protocol then return end
		if serverID ~= sId then serverID = sId end
	end
}
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
local surface_onEvent = surface.onEvent
surface.onEvent = function (self, evt)
	local event_name = evt[1]
	if evt[event_name] == "rednet_message" then
		local sType = evt[3].sType
		if client_handler[sType] then
			client_handler[sType](evt[3], evt[2])
			return true
		end
	end
	if msgLabel and evt[event_name] == "timer" and evt[2] == timer then msgLabel:setText("Server do not response.") return true end
	return surface_onEvent(self, evt)
end
-----------------------------------------------------
if not account_key then switchToAuth() else switchToApp() end

root:mainloop()
