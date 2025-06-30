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
    process.event_filter = nil -- Сбрасываем фильтр после получения события
    return unpack(event)
end

-- Функция для задержки (сна) процесса
function kernelSleep(seconds)
    local process = current_process
    process.timer_id = os.startTimer(seconds)
    local _, timer_id = kernelWait("timer")
    if timer_id == process.timer_id then
        process.timer_id = nil
        return true
    end
    return false
end

-- Основной цикл ядра
local function kernel_run()
    while true do
        local event = {os.pullEventRaw()} -- Используем os.pullEventRaw для обработки всех событий, включая terminate
        local event_type = event[1]

        -- Обработка события terminate (временное решение)
        if event_type == "terminate" then
            break
        end

        -- Обрабатываем все процессы
        for i = #processes, 1, -1 do -- Идем в обратном порядке, чтобы корректно удалять процессы
            local process = processes[i]
            if process.status == "ready" or (process.status == "waiting" and (process.event_filter == nil or process.event_filter == event_type)) then
                if event_type == "timer" and process.timer_id and process.timer_id ~= event[2] then
                    -- Пропускаем таймер, не предназначенный для этого процесса
                    goto continue
                end

                current_process = process
                process.status = "running"
                local success, error = coroutine.resume(process.co, unpack(event))
                if not success then
                    print("Ошибка в процессе: " .. tostring(error))
                    table.remove(processes, i) -- Удаляем процесс при ошибке
                elseif coroutine.status(process.co) == "dead" then
                    table.remove(processes, i) -- Удаляем завершившийся процесс
                end
                ::continue::
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
