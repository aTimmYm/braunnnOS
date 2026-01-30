local sys = require "syscalls"
local UI = require "ui2"

local root = UI.Root()

local surface = UI.Container({
    x = 1, y = 1,
    w = root.w, h = root.h
})
root:addChild(surface)

surface.onResize = function (width, height)
    surface.w, surface.h = width, height
end

function surface.custom_handlers.popup_add()
    surface:addChild(_G.context)
    _G.context = nil
    return true
end

root:mainloop()