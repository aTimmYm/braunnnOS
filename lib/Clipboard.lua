local _clipboard = {}
if not fs.exists("Clipboard.txt") then
    local file = fs.open("Clipboard.txt", "w")
    file.close()
end

function _clipboard.copy(arg)
    local file = fs.open("Clipboard.txt", "w")
    if type(arg) == "table" then
        for _, line in ipairs(arg) do
            file.writeLine(line)
        end
    elseif type(arg) == "string" then
        for line in arg:gmatch("[^\n]+") do
            file.writeLine(line)
        end
    end
    file.close()
end

function _clipboard.paste()
    local file = fs.open("Clipboard.txt", "r")
    local clipboard = file.readAll()
    file.close()
    return clipboard
end

return _clipboard