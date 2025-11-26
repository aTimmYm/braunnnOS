local UI = require("ui")
local dM = require("deskManager")
local _system = {}

local keyboard
local root

function _system.set_root(r)
    root = r
end

function _system.set_keyboard(k)
    keyboard = k
end

function _system.get_keyboard()
    return keyboard
end

function _system.call_keyboard(r)
    r = r or root
    r:addChild(keyboard)
    keyboard:onLayout()
end

function _system.remove_keyboard(r)
    r = r or root
    r:removeChild(keyboard)
end

function _system.execute(path, ...)
    local func, load_err = loadfile(path, _ENV)  -- "t" для text, или "bt" если нужно
    if not func then
        print(load_err) os.sleep(2)
    else
        local ret, exec_err = pcall(func, ...)
        if not ret then
            print(exec_err)
            os.pullEvent("key")
        end
    end
end

function _system.dekstop_manager()
    local surface = UI.New_Box(1, 1, root.w, root.h, colors.black)
    root:addChild(surface)
    local radioButton_horizontal = UI.New_RadioButton_horizontal(math.floor(root.w/2), root.h, 1, colors.black, colors.white)
    surface:addChild(radioButton_horizontal)
    local btnReboot = UI.New_Button(surface.w - 5, 1, 6, 1, "REBOOT", _, colors.black, colors.lightGray)
    surface:addChild(btnReboot)
    local btnExit = UI.New_Button(btnReboot.x - 9, 1, 8, 1, "SHUTDOWN", _, colors.black, colors.lightGray)
    surface:addChild(btnExit)
    local btnSpeaker = UI.New_Button(btnExit.x - 8, 1, 7, 1, "SPEAKER", _, colors.black, colors.lightGray)
    surface:addChild(btnSpeaker)
    local btnDebug = UI.New_Button(btnSpeaker.x - 9, 1, 8, 1, "DEBUGGER", _, colors.black, colors.lightGray)
    surface:addChild(btnDebug)
    local btnModem = UI.New_Button(btnDebug.x - 6, 1, 5, 1, "MODEM", _, colors.black, colors.lightGray)
    surface:addChild(btnModem)
    dM.setObjects(root, surface, radioButton_horizontal)
    dM.makeDesktops()
    dM.makeShortcuts()
    radioButton_horizontal:changeCount(dM.updateNumDesks())
    radioButton_horizontal.pressed = function(self)
        dM.selectDesk(self.item)
        self.parent:onLayout()
    end
    btnReboot.pressed = function(self)
        term.setCursorPos(1,1)
        term.clear()
        print("Rebooting...")
        os.sleep(0.1)
        term.clear()
        os.reboot()
    end
    btnExit.pressed = function(self)
        root.running_program = false
    end
    btnSpeaker.pressed = function(self)
        if periphemu then periphemu.create("right", "speaker") end
        bOS.speaker = peripheral.find("speaker")
    end
    btnDebug.pressed = function(self)
        if periphemu then periphemu.create("left", "debugger") end
    end
    btnModem.pressed = function(self)
        if periphemu then periphemu.create("top", "modem") end
    end
    surface.onResize = function (width, height)
        surface.w, surface.h = width, height
        radioButton_horizontal.local_x, radioButton_horizontal.local_y = math.floor(root.w/2), root.h
        btnReboot.local_x = surface.w - 5
        btnExit.local_x = btnReboot.local_x - 9
        btnSpeaker.local_x = btnExit.local_x - 8
        btnDebug.local_x = btnSpeaker.local_x - 9
        btnModem.local_x = btnDebug.local_x - 6
        dM.makeDesktops()
        dM.makeShortcuts()
        radioButton_horizontal:changeCount(dM.updateNumDesks())
        radioButton_horizontal.item = dM.getCurrdesk()
        for _, child in ipairs(surface.children) do
            if child.onResize then
                child.onResize(width, height)
            end
        end

    end
end

function _system.call_dialWin(title, msg)
    local addWin = UI.New_DialWin()
    addWin:callWin(title, msg)
end

function _system.add_window(mode, color_bg, title)
    local window
    if mode == "Titled" then
        window = UI.New_Window(1, 1, root.w, root.h, color_bg, title)
        root:addChild(window)

        window.close.pressed = function (self)
            root:removeChild(window)
            root:onLayout()
        end

        window.onResize = function (width, height)
            window.w, window.h = width, height
            window.label.local_x = math.floor((width - #window.label.text)/2) + 1
            window.close.local_x = width
            window.surface.w, window.surface.h = width, height - 1
            if window.surface.onResize then window.surface.onResize(window.surface.w, window.surface.h) end
        end
        return window, window.surface
    elseif mode == "UnTitled" then
        window = UI.New_Box(1, 1, root.w, root.h, color_bg)
        root:addChild(window)
        return window
    end
end

return _system