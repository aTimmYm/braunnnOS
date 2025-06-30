-- Таблица для хранения всех процессов
local processes = {}
local current_process = nil

-- Функция для создания нового процесса
function kernelSpawn(func)
    local co = coroutine.create(func)
    local process = {
        co = co,
        status = "ready",
        event_filter = nil,
        timer_id = nil
    }
    table.insert(processes, process)
    return process
end

-- Функция ожидания события
function kernelWait(event_type)
    local process = current_process
    process.status = "waiting"
    process.event_filter = event_type
    local event = {coroutine.yield()}
    process.status = "running"
    return unpack(event)
end

-- Функция для задержки (сна) процесса
function kernelSleep(seconds)
    local process = current_process
    process.timer_id = os.startTimer(seconds)
    kernelWait("timer")
end

-- Основной цикл ядра
local function kernel_run()
    print("Start kernel")
    while true do
        local event = {os.pullEventRaw()}
        local event_type = event[1]

        -- Проверяем, есть ли процесс, ожидающий это событие
        for i, process in ipairs(processes) do
            if process.status == "waiting" and process.event_filter == event_type then
                if event_type == "timer" and process.timer_id == event[2] then
                    current_process = process
                    process.status = "running"
                    local success, error = coroutine.resume(process.co, unpack(event))
                    if not success then
                        print("Ошибка в процессе: " .. error)
                    end
                    if coroutine.status(process.co) == "dead" then
                        table.remove(processes, i)
                    end
                    break
                elseif event_type ~= "timer" then
                    current_process = process
                    process.status = "running"
                    local success, error = coroutine.resume(process.co, unpack(event))
                    if not success then
                        print("Ошибка в процессе: " .. error)
                    end
                    if coroutine.status(process.co) == "dead" then
                        table.remove(processes, i)
                    end
                    break
                end
            end
        end
    end
end

-- Пример использования: запуск двух процессов
kernelSpawn(function()
    while true do
        print("Hello")
        os.sleep(1)
    end
end)

kernelSpawn(function()
    while true do
        print("World")
        os.sleep(2)
    end
end)

-- Старт ядра
kernel_run()
