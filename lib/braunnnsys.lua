local UI = require("UI")
local dM = require("deskManager")
local _system = {}

local root

function _system.set_root(r)
    root = r
end

function _system.dekstop_manager()
    local desktop = UI.New_Box(1, 1, root.w, root.h, colors.green)
    root:addChild(desktop)
    local radioButton_horizontal = UI.New_RadioButton_horizontal(math.floor(root.w/2), root.h, 1, colors.black, colors.white)
    desktop:addChild(radioButton_horizontal)
    dM.setObjects(root, desktop, radioButton_horizontal)
    --dM.readShortcuts()
    dM.makeDesktops()
    dM.makeShortcuts()
    radioButton_horizontal:changeCount(dM.updateNumDesks())
    desktop.onResize = function (width, height)
        desktop.w, desktop.h = width, height
        radioButton_horizontal.local_x, radioButton_horizontal.local_y = math.floor(root.w/2), root.h
        dM.makeDesktops()
        dM.makeShortcuts()
        radioButton_horizontal:changeCount(dM.updateNumDesks())
        radioButton_horizontal.item = dM.getCurrdesk()
        for _, child in ipairs(desktop.children) do
            if child.onResize then
                child.onResize(width, height)
            end
        end

    end
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
            window.label.local_x = math.floor((width - #window.label.text)/2)
            window.close.local_x = width
            window.surface.w, window.surface.h = width, height - 1
            window.surface.onResize(width, height)
        end
        return window, window.surface
    elseif mode == "UnTitled" then
        window = UI.New_Box(1, 1, root.w, root.h, color_bg)
        root:addChild(window)
        return window
    end
end

return _system