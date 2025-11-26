if bOS.shell then return end
bOS.shell = true
------------| СЕКЦИЯ ЛОКАЛИЗАЦИИ ФУНКЦИЙ |-----------
local table_unpack = table.unpack
local coroutine_resume = coroutine.resume
local coroutine_create = coroutine.create
local coroutine_status = coroutine.status
-----------------------------------------------------
-------| СЕКЦИЯ ПОДКЛЮЧЕНИЯ БИБЛИОТЕК И ROOT |-------
local system = require("braunnnsys")
local UI = require("ui")
local c = require("cfunc")
local root = UI.New_Root()
root.keyboard = system.get_keyboard()
-----------------------------------------------------
-----| СЕКЦИЯ ОБЪЯВЛЕНИЯ ПЕРЕМЕННЫХ ПРОГРАММЫ |------
local args = {...}

local shell_window = window.create(term.current(), 1, 2, root.w, root.h - 1, true)
local shell_function = loadfile("rom/programs/shell.lua", _ENV)

local prev_term = term.redirect(shell_window)
root.coroutine = coroutine_create(shell_function)
term.redirect(prev_term)
-----------------------------------------------------
----------| СЕКЦИЯ ИНИЦИАЛИЗАЦИИ ОБЪЕКТОВ |----------
local surface = UI.New_Container(1, 1, root.w, root.h)
root:addChild(surface)

local label = UI.New_Label(2, 1, root.w - 1, 1, "Shell", "center", colors.white, colors.black)
surface:addChild(label)

local buttonClose = UI.New_Button(root.w, 1, 1, 1, "x", "center", colors.white, colors.black)
surface:addChild(buttonClose)

local buttonKeyboard = UI.New_Button(1, 1, 1, 1, "K", _, colors.white, colors.black)
surface:addChild(buttonKeyboard)
-----------------------------------------------------
------| СЕКЦИЯ ОБЪЯВЛЕНИЯ ФУНКЦИЙ ПРОГРАММЫ |--------
local function resume_coroutine(co, ...)
    term.redirect(shell_window)
    local success, err = coroutine_resume(co, ...)
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
buttonClose.pressed = function (self)
    self.root.running_program = false
end

local keyboard_bool = false
buttonKeyboard.pressed = function (self)
    -- if self.root:removeChild(self.root.keyboard) then shell_window.redraw() return end
    -- self.root:addChild(self.root.keyboard)
    -- self.root.keyboard:onLayout()
    if not keyboard_bool then system.call_keyboard(root) end
    if keyboard_bool then system.remove_keyboard(root) shell_window.redraw() end
    keyboard_bool = not keyboard_bool
end

surface.onResize = function (width, height)
    label.w = width - 1
    buttonClose.local_x = width
end

local temp_tResize = root.tResize
root.tResize = function (self)
    temp_tResize(self)
    shell_window.reposition(1, 2, self.w, self.h - 1)
    shell_window.redraw()
end

root.mainloop = function (self)
    self:show()
    resume_coroutine(self.coroutine,table_unpack(args))
    while self.running_program do
        local evt = {os.pullEventRaw()}
        resume_coroutine(self.coroutine, table_unpack(evt))
        if evt[1] == "terminate" then
            c.termClear(self.bg)
            self.running_program = false
        end
        self:onEvent(evt)
        self.keyboard:onLayout()
    end
end
-----------------------------------------------------
---------| MAINLOOP И ДЕЙСТВИЯ ПОСЛЕ НЕГО |----------
root:mainloop()
term.setCursorBlink(false)
os.queueEvent("term_resize")
bOS.shell = false
-----------------------------------------------------
