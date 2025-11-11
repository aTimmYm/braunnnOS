------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local table_unpack = table.unpack
local coroutine_resume = coroutine.resume
local coroutine_create = coroutine.create
local coroutine_status = coroutine.status
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local UI = require("ui")
local c = require("cfunc")
local EVENTS = require("events")
local root = UI.New_Root()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
if bOS.shell then return end
bOS.shell = true

local args = {...}

local shellWindow = window.create(term.current(),1,2,root.size.w,root.size.h-1,true)
local shellFunc = loadfile("rom/programs/shell.lua", _ENV)
local prev_term = term.redirect(shellWindow)
root.coroutine = coroutine_create(shellFunc)
term.redirect(prev_term)
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Box(root)
surface.draw = function(self) end
root:addChild(surface)

local label = UI.New_Label(root,"shell",colors.white,colors.black)
label.reSize = function(self)
    self.pos.x = 2
    self.size.w = self.parent.size.w-self.pos.x
end
surface:addChild(label)

local buttonClose = UI.New_Button(root,"x",colors.white,colors.black)
buttonClose.reSize = function(self)
    self.pos.x = self.parent.size.w
end
surface:addChild(buttonClose)

local buttonKeyboard = UI.New_Button(root,"K",colors.white,colors.black)
surface:addChild(buttonKeyboard)
-----------------------------------------------------
--table_unpack(shell_evt)
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function resume_coroutine(co,...)
    term.redirect(shellWindow)
    local success, err = coroutine_resume(co,...)
    if not success then
        error("Coroutine error: "..tostring(err))
    elseif coroutine_status(co) == "dead" then
        root.coroutine = nil
        root.running_program = false
    end
    term.redirect(prev_term)
end
-----------------------------------------------------
--| СЕКЦИЯ ПЕРЕОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНЫХ МЕТОДОВ |--
buttonClose.pressed = function(self)
    self.root.running_program = false
end

buttonKeyboard.pressed = function(self)
    if self.root:removeChild(self.root.keyboard) then shellWindow.redraw() return end
    self.root:addChild(self.root.keyboard)
    self.root.keyboard:onLayout()
end

root.tResize = function(self)
    c.termClear(self.bg)
    self.size.w, self.size.h = term.getSize()
    self:onLayout()
    shellWindow.redraw()
    shellWindow.reposition(1,2,root.size.w,root.size.h-1)
end

root.mainloop = function(self)
    self:show()
    resume_coroutine(self.coroutine,table_unpack(args))
    while self.running_program do
        local evt = {os.pullEventRaw()}
        --dbg.print(textutils.serialise(evt))
        local shell_evt = {table_unpack(evt)}
        if EVENTS.TOP[shell_evt[1]] then
            shell_evt[4] = shell_evt[4]-1
        end
        if self.keyboard:onEvent(evt) then
            resume_coroutine(self.coroutine)
        else
            resume_coroutine(self.coroutine,table_unpack(shell_evt))
        end
        if evt[1] == "terminate" then
            c.termClear(self.bg)
            self.running_program = false
        end
        self:onEvent(evt)
        self.keyboard:onLayout()
    end
    c.termClear()
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
bOS.shell = false
-----------------------------------------------------
