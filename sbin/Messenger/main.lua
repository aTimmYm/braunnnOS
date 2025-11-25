------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local string_sub = string.sub
local string_gmatch = string.gmatch
local table_insert = table.insert
local table_sort = table.sort
local math_floor = math.floor
local math_ceil = math.ceil
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local system = require("braunnnsys")
local c = require("cfunc")
local UI = require("ui")
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local currentChatHeight = 1
if not fs.exists("sbin/Messenger/Data/account_key") then
    local file = fs.open("sbin/Messenger/Data/account_key","w")
    file.close()
end
local account_key = c.readFile("sbin/Messenger/Data/account_key")
if not fs.exists("sbin/Messenger/Data/friends") then
    local file = fs.open("sbin/Messenger/Data/friends","w")
    file.write("return {}")
    file.close()
end
local friends = require("sbin.Messenger.Data.friends")
local protocol = "messenger"
local friendsSort = {}
local selectedFriend = {}
local serverID = 10--rednet.lookup(protocol, "messenger_main")
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local window, surface = system.add_window("Titled", colors.black, "Messenger")

local usersList, msgScrollBox, textOut, msgLabel, timer
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
if bOS.modem then rednet.open(peripheral.getName(bOS.modem)) end

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

    local label = UI.New_Label(1, currentChatHeight, msgScrollBox.w, #lines, msg, direction, color_bg, color_txt)

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
    for i, v in pairs(friendsSort) do
        local userButton = UI.New_Button(1, i, usersList.w, 1, " "..tostring(v), "left", usersList.color_bg, colors.white)
        userButton.selectedFriend = friends[v]
        userButton.pressed = userButton_pressed
        usersList:addChild(userButton)
        usersList:onLayout()
    end
end

local function initAuthUI()
    msgLabel = UI.New_Label(1, math_floor(surface.h/2) - 3, surface.w, 1, "", "center", surface.color_bg, colors.white)
    surface:addChild(msgLabel)

    local textfieldLogin = UI.New_Textfield(math_floor((surface.w - 10)/2) + 1, msgLabel.local_y + 2, 10, 1, "Login", _, colors.gray, colors.white)
    surface:addChild(textfieldLogin)

    local textfieldPassword = UI.New_Textfield(textfieldLogin.local_x, textfieldLogin.local_y + 2, 10, 1, "Password", true, colors.gray, colors.white)
    surface:addChild(textfieldPassword)

    local buttonRegister = UI.New_Button(math_floor((surface.w - 10)/2) - 5, textfieldPassword.local_y + 2, 10, 1, "Register", _, colors.lightGray, colors.white)
    surface:addChild(buttonRegister)

    local buttonLogin = UI.New_Button(buttonRegister.local_x + buttonRegister.w + 1, textfieldPassword.local_y + 2, 10, 1, "Login", _, colors.lightGray, colors.white)
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
        msgLabel.local_y, msgLabel.w = math_floor(height/2) - 3, width
        textfieldLogin.local_x, textfieldLogin.local_y = math_floor((width - 10)/2) + 1, msgLabel.local_y + 2
        textfieldPassword.local_x, textfieldPassword.local_y = textfieldLogin.local_x, textfieldLogin.local_y + 2
        buttonRegister.local_x, buttonRegister.local_y = math_floor((width - 10)/2) - 5, textfieldPassword.local_y + 2
        buttonLogin.local_x, buttonLogin.local_y = buttonRegister.local_x + buttonRegister.w + 1, textfieldPassword.local_y + 2
    end
end

local function initMainUI()
    local buttonAddFriend = UI.New_Button(1, 1, 1, 1, "+", _, window.color_bg, colors.black)
    window:addChild(buttonAddFriend)

    local myKey = UI.New_Button(2, 1, 1, 1, "?", _, window.color_bg, colors.black)
    window:addChild(myKey)

    usersList = UI.New_ScrollBox(1,1, math_ceil(surface.w/4), surface.h, surface.color_bg)
    surface:addChild(usersList)

    msgScrollBox = UI.New_ScrollBox(usersList.w + 1, 1, surface.w - usersList.w, surface.h - 1, colors.gray)

    textOut = UI.New_Textfield(msgScrollBox.x, surface.h, msgScrollBox.w, 1, "Type message", _, colors.black, colors.white)

    buttonAddFriend.pressed = function (self)
        local friend = UI.New_DialWin(" Add a friend ", "Type user identifier")
        if friend then rednet.send(serverID,{cType = "user_add", user = account_key, added_user = friend},protocol) end
    end

    myKey.pressed = function (self)
        UI.New_MsgWin("INFO", " Your identificator ", account_key)
    end

    textOut.pressed = function (self)
        drawMessage(self.text, "right")
        rednet.send(serverID, {cType = "send", from = account_key, to = selectedFriend[1], message = self.text}, protocol)
        self.text = ""
        self:moveCursorPos(1)
    end

    msgScrollBox.onResize = function (width, _)
        for _, child in ipairs(msgScrollBox.children) do
            child.w = width
        end
    end

    surface.onResize = function (width, height)
        usersList.w, usersList.h = math_ceil(width/4), height
        msgScrollBox.local_x, msgScrollBox.w, msgScrollBox.h = usersList.w + 1, width - usersList.w, height - 1
        textOut.local_x, textOut.local_y, textOut.w = msgScrollBox.local_x, height, msgScrollBox.w
        msgScrollBox.onResize(msgScrollBox.w, msgScrollBox.h)
    end
end

local function switchToApp()
    msgLabel = nil
    surface:removeChild(true)

    if not usersList then
        initMainUI()
    end

    window:onLayout()
end

local function switchToAuth()
    surface:removeChild(true)
    initAuthUI()
    surface:onLayout()
end

local client_handler = {
    ["login"] = function (response)
        if response.login == "success" then
            local account_key_file = fs.open("sbin/Messenger/Data/account_key","w")
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
            local friendsFile = fs.open("sbin/Messenger/Data/friends","w")
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
        local friendsFile = fs.open("sbin/Messenger/Data/friends","w")
        friendsFile.write("return "..textutils.serialize(response.friends))
        friendsFile.close()
        friends = response.friends
        drawFriendsButtons()
    end,
    ["send"] = function (response)
        drawMessage(response.message,"left")
    end,
    ["lookup"] = function (response,sId)
        if response.sProtocol ~= protocol then return end
        if serverID ~= sId then serverID = sId end
    end
}
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
local temp_onEvent = window.onEvent
window.onEvent = function (self, evt)
    if evt[1] == "rednet_message" then
        local sType = evt[3].sType
        if client_handler[sType] then
            client_handler[sType](evt[3], evt[2])
            return
        end
    end
    if msgLabel and evt[1] == "timer" and evt[2] == timer then msgLabel:setText("Server do not response.") end
    --print(textutils.serialise(evt))
    return temp_onEvent(self, evt)
end

local temp_pressed = window.close.pressed
window.close.pressed = function (self)
    package.loaded["sbin.Messenger.Data.friends"] = nil
    return temp_pressed(self)
end

-----------------------------------------------------
if not account_key then
    switchToAuth()
else
    switchToApp()
    drawFriendsButtons()
end
