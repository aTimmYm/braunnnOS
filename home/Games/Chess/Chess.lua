--local obj = require("Chess_data.obj_classes")
local ui = require("Chess_data.interface_classes")
local c = require("Chess_data.cfunc")

local interface = {}
local running_simulation = true

local button = ui.New_Button("test",colors.yellow, colors.black)

local function addChild(tbl,child)
    table.insert(tbl,child)
end

local function onEvent(evt)

end

addChild(interface,button)

while running_simulation do
    local evt = {os.pullEventRaw()}
    --c.printTable(interface[1])
    if evt[1] == "terminate" then
        term.clear()
        running_simulation = false
    end
    onEvent(evt)
end