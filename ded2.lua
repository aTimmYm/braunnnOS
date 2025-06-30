-- Глобальные переменные
local term = term
windows = {}  -- Список всех окон
local sWidth, sHeight = term.getSize()
local taskbar = window.create(term.current(), 1, sHeight, sWidth, 1)  -- Панель задач внизу

-- Функция создания окна
function createWindow(title, x, y, width, height)
    local win = {
        title = title,
        x = x,
        y = y,
        width = width,
        height = height,
        visible = true,
        active = false,
        buttons = {},
        term = window.create(term.current(), x, y, width, height)
    }
    table.insert(windows, win)
    return win
end

-- Функция активации окна
function activateWindow(win)
    for _, w in ipairs(windows) do
        w.active = false
    end
    win.active = true
    -- Перемещаем окно в конец списка (на передний план)
    for i, w in ipairs(windows) do
        if w == win then
            table.remove(windows, i)
            table.insert(windows, win)
            break
        end
    end
end

-- Функция добавления кнопки в окно
function addButton(win, label, x, y, width, height, action)
    local button = {
        label = label,
        x = x,
        y = y,
        width = width,
        height = height,
        action = action
    }
    table.insert(win.buttons, button)
end

-- Отрисовка окна
function drawWindow(win)
    if not win.visible then return end
    local wterm = win.term
    wterm.clear()
    wterm.setCursorPos(1, 1)
    wterm.write(win.title)
    for i = 2, win.height do
        wterm.setCursorPos(1, i)
        wterm.write("|")
        wterm.setCursorPos(win.width, i)
        wterm.write("|")
    end
    wterm.setCursorPos(1, win.height)
    wterm.write(string.rep("-", win.width))
    for _, btn in ipairs(win.buttons) do
        wterm.setCursorPos(btn.x, btn.y)
        wterm.write(btn.label)
    end
end

-- Отрисовка панели задач
function drawTaskbar()
    taskbar.clear()
    local x = 1
    for i, win in ipairs(windows) do
        if win.visible then
            taskbar.setCursorPos(x, 1)
            taskbar.write("[" .. win.title .. "]")
            x = x + #win.title + 3
        end
    end
end

-- Универсальная обработка кликов
function handleClick(x, y)
    -- Проверка клика по панели задач
    local termWidth, termHeight = term.getSize()
    if y == termHeight then
        local pos = 1
        for i, win in ipairs(windows) do
            if win.visible then
                local titleWidth = #win.title + 2  -- Учитываем скобки []
                if x >= pos and x < pos + titleWidth then
                    activateWindow(win)
                    redrawDesktop()
                    return
                end
                pos = pos + titleWidth + 1
            end
        end
        return
    end

    -- Проверка клика по окнам (сверху вниз)
    for i = #windows, 1, -1 do
        local win = windows[i]
        if win.visible and x >= win.x and x < win.x + win.width and y >= win.y and y < win.y + win.height then
            activateWindow(win)
            -- Проверка клика по кнопкам внутри окна
            for _, btn in ipairs(win.buttons) do
                local btnX, btnY = win.x + btn.x - 1, win.y + btn.y - 1
                if x >= btnX and x < btnX + btn.width and y >= btnY and y < btnY + btn.height then
                    btn.action()
                    redrawDesktop()
                    return
                end
            end
            redrawDesktop()
            return
        end
    end
end

-- Перерисовка рабочего стола
function redrawDesktop()
    term.clear()
    for _, win in ipairs(windows) do
        drawWindow(win)
    end
    drawTaskbar()
end

-- Пример использования
local win1 = createWindow("Window 1", 2, 2, 20, 5)
addButton(win1, "Close", 2, 3, 5, 1, function() win1.visible = false end)
local win2 = createWindow("Window 2", 5, 4, 15, 6)
addButton(win2, "Hi!", 2, 3, 4, 1, function() print("Hello!") end)
activateWindow(win1)
redrawDesktop()

-- Основной цикл событий
while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "mouse_click" then
        handleClick(p2, p3)
    end
end
