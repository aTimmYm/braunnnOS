local PixelEngine = {}
PixelEngine.__index = PixelEngine

local CHAR_EVEN = "\131"
local CHAR_ODD  = "\143"

function PixelEngine.new(w, h)
    local self = setmetatable({}, PixelEngine)

    self.w = w
    self.h = h
    self.pixelsY = math.floor((3/2) * h)

    local bc, fc = {}, {}
    for x = 1, w do
        local bc_col, fc_col = {}, {}
        for y = 1, self.pixelsY do
            bc_col[y] = colors.black
            fc_col[y] = colors.black
        end
        bc[x] = bc_col
        fc[x] = fc_col
    end

    self.bc = bc
    self.fc = fc

    return self
end


function PixelEngine:setPixel(x, y, color)
    local Y = math.floor((2 * y) / 3 + 0.5)

    local bc_col = self.bc[x]
    if not bc_col then return end
    local fc_col = self.fc[x]

    local isOdd = (Y % 2 == 1)
    local isTrip = ((y + 1) % 3 == 0)

    if isOdd then
        if isTrip then
            bc_col[Y] = color
            local ny = Y + 1
            if fc_col[ny] ~= nil then fc_col[ny] = color end
        else
            fc_col[Y] = color
        end
    else
        bc_col[Y] = color
    end
end


function PixelEngine:draw(mon)
    for x = 1, self.w do
        local bc_col = self.bc[x]
        local fc_col = self.fc[x]

        for y = 1, self.pixelsY do
            mon.setCursorPos(x, y)
            mon.setBackgroundColor(bc_col[y])
            mon.setTextColor(fc_col[y])
            mon.write((y % 2 == 0) and CHAR_EVEN or CHAR_ODD)
        end
    end
end

return PixelEngine
