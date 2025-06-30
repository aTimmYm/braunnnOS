local processes = {}
local num 

local function crPr(func)
    local co = coroutine.create(func)
    local process = {co = co}
    table.insert(processes, process)
end

local function start()
    while true do
        local event = {os.pullEventRaw()}
        for i, process in ipairs(processes) do
            local status, arg = coroutine.resume(process.co, unpack(event))
        end
        if event[1] == "terminate" then
            break
        end
    end
end

crPr(function()
    while true do
        os.pullEvent()
        print("1")
    end
end)

crPr(function()
    while true do
        print("2")
        os.sleep(0)
    end
end)

start()
