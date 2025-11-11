------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local math_floor = math.floor
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local c = require("cfunc")
local UI = require("ui")
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local protocol = "messenger"
local serverID = rednet.lookup(protocol, "messenger_main")
local timer
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(root,colors.white)
root:addChild(surface)

local main_box = UI.New_Box(root,colors.black)
main_box.reSize = function(self)
    self.pos.y = 2
    self.size = {w=self.parent.size.w,h=self.parent.size.h}
end
surface:addChild(main_box)

local labelTitle = UI.New_Label(root, "Messenger",colors.white,colors.black)
labelTitle.reSize = function(self)
    self.pos.x = 2
    self.size.w = self.parent.size.w-2
end
surface:addChild(labelTitle)

local buttonClose = UI.New_Button(root,"x",colors.white,colors.black)
buttonClose.reSize = function(self)
    self.pos.x = self.parent.size.w
end
surface:addChild(buttonClose)

local msgLabel = UI.New_Label(root, "", _, _, "center")
msgLabel.reSize = function(self)
    self.size.w = self.parent.size.w
    self.pos = {x = 1, y = math_floor(self.parent.size.h/2)-2}
end
main_box:addChild(msgLabel)

local textfieldLogin = UI.New_Textfield(root, colors.gray, _, "Login")
textfieldLogin.reSize = function(self)
    self.size.w = 10
    self.pos = {x=math_floor((self.parent.size.w-self.size.w)/2),y=math_floor(self.parent.size.h/2)}
end
main_box:addChild(textfieldLogin)

local textfieldPassword = UI.New_Textfield(root, colors.gray, _, "Password", true)
textfieldPassword.reSize = function(self)
    self.size.w = 10
    self.pos = {x=math_floor((self.parent.size.w-self.size.w)/2),y=math_floor(self.parent.size.h/2)+2}
end
main_box:addChild(textfieldPassword)

local buttonRegister = UI.New_Button(root, "Register", colors.lightGray)
buttonRegister.reSize = function(self)
    self.size.w = 10
    self.pos = {x=math_floor((self.parent.size.w-self.size.w)/2)-6,y=math_floor(self.parent.size.h/2)+4}
end
main_box:addChild(buttonRegister)

local buttonLogin = UI.New_Button(root, "Login", colors.lightGray)
buttonLogin.reSize = function(self)
    self.size.w = 10
    self.pos = {x=math_floor((self.parent.size.w-self.size.w)/2)+5,y=math_floor(self.parent.size.h/2)+4}
end
main_box:addChild(buttonLogin)

local rememberMeLablel = UI.New_Label(root, "Remember Me")
rememberMeLablel.reSize = function(self)
    self.size.w = 11
    self.pos = {x=math_floor((self.parent.size.w-self.size.w)/2)+1,y=math_floor(self.parent.size.h/2)+6}
end
main_box:addChild(rememberMeLablel)

local rememberMeCheckbox = UI.New_Checkbox(root, colors.gray)
rememberMeCheckbox.reSize = function(self)
    self.pos = {x=rememberMeLablel.pos.x-2,y=math_floor(self.parent.size.h/2)+6}
end
main_box:addChild(rememberMeCheckbox)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
if bOS.modem then rednet.open(peripheral.getName(bOS.modem)) end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function(self)
    os.queueEvent("terminate")
end

buttonLogin.pressed = function(self)
    rednet.send(serverID, {cType = "login", login = textfieldLogin.text, password = textfieldPassword.text}, protocol)
    if not timer then timer = os.startTimer(5) end
end

buttonRegister.pressed = function(self)
    rednet.send(serverID, {cType = "registration", login = textfieldLogin.text, password = textfieldPassword.text}, protocol)
    if not timer then timer = os.startTimer(5) end
end

local client_type = {
    ["login"] = function (response)
        if response.login == "success" then
            local account_key = fs.open("sbin/Messenger_Data/account_key","w")
            account_key.write(response.key)
            account_key.close()
            os.queueEvent("terminate")
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
    ["lookup"] = function (response,sId)
        if response.sProtocol ~= protocol then return end
        if serverID ~= sId then serverID = sId end
    end
}

root.mainloop = function(self)
    self:show()
    while self.running_program do
        local evt = {os.pullEventRaw()}
        --print(textutils.serialise(evt))
        if evt[1] == "rednet_message" then
            local sType = evt[3].sType
            if client_type[sType] then
                os.cancelTimer(timer)
                client_type[sType](evt[3],evt[2])
            end
        end
        if evt[1] == "timer" and evt[2] == timer then msgLabel:setText("Server do not response.") end
        if evt[1] == "terminate" then
            c.termClear(self.bg)
            self.running_program = false
        end
        self:onEvent(evt)
    end
    c.termClear()
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
-----------------------------------------------------
