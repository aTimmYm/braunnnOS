------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local table_insert = table.insert
local table_sort = table.sort
local table_unpack = table.unpack
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
--package.path = package.path .. ";/sbin/Messenger_data/?" .. ";/sbin/Messenger_data/?.lua"
local c = require("cfunc")
local UI = require("ui")
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local texts = {}
if not fs.exists("sbin/Messenger_Data/account_key") then
    local file = fs.open("sbin/Messenger_Data/account_key","w")
    file.close()
end
local account_key = c.readFile("sbin/Messenger_Data/account_key")
if not fs.exists("sbin/Messenger_Data/friends") then
    local file = fs.open("sbin/Messenger_Data/friends","w")
    file.write("return {}")
    file.close()
end
local friends = require("friends")
local protocol = "messenger"
local friendsSort = {}
local selectedFriend = {}
local a = 1000
local serverID = rednet.lookup(protocol, "messenger_main")
-----------------------------------------------------
if not account_key then
    local func = loadfile("sbin/Messenger_Data/register.lua", _ENV)
    local ret, exec_err = pcall(func)

    if not ret then
        print(exec_err)
        --read()
        return
    end
    account_key = c.readFile("sbin/Messenger_Data/account_key")
    rednet.send(serverID,{cType = "get_friends", user = account_key},protocol)
end
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(root,colors.white)
root:addChild(surface)

local buttonClose = UI.New_Button(root,"x",colors.white,colors.black)
buttonClose.reSize = function (self)
    self.pos.x = self.parent.size.w
end
surface:addChild(buttonClose)

local labelTitle = UI.New_Label(root, "Messenger",colors.white,colors.black)
labelTitle.reSize = function (self)
    self.pos.x = 2
    self.size.w = self.parent.size.w-2
end
surface:addChild(labelTitle)

local buttonAddFriend = UI.New_Button(root,"+",colors.white,colors.black)
surface:addChild(buttonAddFriend)

local usersList = UI.New_ScrollBox(root)
usersList.reSize = function (self)
    self.pos = {x = self.parent.pos.x, y = self.parent.pos.y + 1}
    self.size = {w = 15, h = self.parent.size.h-1}
    self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
    self.win.redraw()
end
surface:addChild(usersList)

local msgScrollBox = UI.New_ScrollBox(root,colors.gray)
msgScrollBox.reSize = function (self)
    self.pos = {x = usersList.pos.x+usersList.size.w, y = self.parent.pos.y + 1}
    self.size = {w = self.parent.size.w - self.pos.x+1, h = self.parent.size.h - 2}
    self.win.reposition(self.pos.x, self.pos.y, self.size.w, self.size.h)
    self.win.redraw()
end

local textOut = UI.New_Textfield(root,colors.lightGray)
textOut.reSize = function (self)
    self.pos = {x = msgScrollBox.pos.x, y = msgScrollBox.pos.y + msgScrollBox.size.h}
    self.size = {w = msgScrollBox.size.w, h = 1}
end
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
if bOS.modem then rednet.open(peripheral.getName(bOS.modem)) end

local function drawMessage(msg,direction)
    if not selectedFriend[2] then return end
    local txtcol = colors.white
    if direction == "right" then txtcol = colors.lightGray end
    local label = UI.New_Label(root, msg, colors.gray, txtcol, direction)

    local yT = #texts + 1

    label.reSize = function (self)
        self.pos = {x = self.parent.pos.x, y = self.parent.pos.y + yT - self.parent.scrollpos}
        self.size.w = self.parent.size.w
    end

    table_insert(texts, label)
    msgScrollBox:addChild(label)
    msgScrollBox:onLayout()

    -- Автоскролл вниз, если сообщений больше высоты
    if #texts > msgScrollBox.size.h then
        msgScrollBox:onMouseScroll(1)
    end
end

local function drawFriendsButtons()
    friendsSort = {}
    for k,_ in pairs(friends) do
        table_insert(friendsSort, k)
    end
    table_sort(friendsSort)
    usersList.child = {}
    for i,v in pairs(friendsSort) do
        local userButton = UI.New_Button(root," "..tostring(v),colors.black,colors.white,"left")
        userButton.selectedFriend = friends[v]
        userButton.reSize = function (self)
            self.pos = {x = self.parent.pos.x, y = i+self.parent.pos.y-1-self.parent.scrollpos+1}
            self.size.w = self.parent.size.w
        end
        userButton.pressed = function (self)
            if selectedFriend[1] == self.selectedFriend then return end
            selectedFriend[1] = self.selectedFriend
            selectedFriend[2] = msgScrollBox
            surface:addChild(msgScrollBox)
            msgScrollBox:reSize()
            surface:addChild(textOut)
            textOut:reSize()
           rednet.send(serverID,{cType = "get_chat_history", from = account_key,to = selectedFriend[1]},protocol)
        end
        usersList:addChild(userButton)
        usersList:onLayout()
    end
end
drawFriendsButtons()
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function (self)
    self.root.running_program = false
end

buttonAddFriend.pressed = function (self)
    local addWin = UI.New_DialWin(root)
    addWin:callWin("Add a friends","Type user identifier")
    function addWin.btnOK:pressed()
        rednet.send(serverID,{cType = "user_add", user = account_key, added_user = addWin.child[2].text},protocol)
        addWin:removeWin()
    end
end

textOut.pressed = function (self)
    drawMessage(self.text,"right")
    rednet.send(serverID, {cType = "send", from = account_key, to = selectedFriend[1], message = self.text}, protocol)
    self.text = ""
    self:moveCursorPos(1)
end

local client_type = {
    ["user_add"] = function (response)
        if response.add == "failure" then
            print(response.error)
        elseif response.add == "success" then
            friends[response.username] = response.key
            local friendsFile = fs.open("sbin/Messenger_Data/friends","w")
            friendsFile.write("return "..textutils.serialize(friends))
            friendsFile.close()
            drawFriendsButtons()
        end
    end,
    ["get_chat_history"] = function (response)
        if not response then --[[Сделать обработку ошибки]] end
        texts = {}
        msgScrollBox.child = {}
        for _,v in pairs(response.history) do
            local dir = "left"
            if v.from == account_key then dir = "right" end
            drawMessage(v.message,dir)
        end
    end,
    ["get_friends"] = function (response)
        local friendsFile = fs.open("sbin/Messenger_Data/friends","w")
        friendsFile.write("return "..textutils.serialize(response.friends))
        friendsFile.close()
        friends = {table_unpack(response.friends)}
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

root.mainloop = function (self)
    self:show()
    c.drawFilledBox(usersList.size.w+1,usersList.pos.y,surface.size.w,surface.size.h,colors.gray)
    while self.running_program do
        local evt = {os.pullEventRaw()}
        --print(serverID)
        if evt[1] == "rednet_message" then
            --print(textutils.serialise(evt)) os.sleep(10)
            local sType = evt[3].sType
            if client_type[sType] then
                client_type[sType](evt[3],evt[2])
            end
            goto continue
        end
        if evt[1] == "terminate" then
            c.termClear(self.bg)
            self.running_program = false
        end
        self:onEvent(evt)
        ::continue::
    end
    c.termClear()
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------
