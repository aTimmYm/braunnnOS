local width, height = term.getSize()
local a = 1
local e = {}
local key = {
  "1","2","3","4","5","6","7","8","9","0",
  "Q","W","E","R","T","Y","U","I","O","P",
  "A","S","D","F","G","H","J","K","L",
  "/\\","Z","X","C","V","B","N","M","<=",
  "SPACE", "Enter"
}
local l_key = {
  "1","2","3","4","5","6","7","8","9","0",
  "q","w","e","r","t","y","u","i","o","p",
  "a","s","d","f","g","h","j","k","l",
  "/\\","z","x","c","v","b","n","m","<=",
  "SPACE", "Enter"
}
local layout = key

local txt = {}
term.clear()
term.setTextColor(colors.white)
term.setBackgroundColor(colors.white)
local wKeyboard = window.create(term.current(), 1, 1, 23, 7, true)
wKeyboard.setBackgroundColor(colors.white)
wKeyboard.setTextColor(colors.black)
wKeyboard.clear()

local function draw_keyboard(table)
  for j = 1, 7 do
    local b = 0
    local dx = 10
    if j >= 3 and j <= 5 then dx = dx - 1 end
    if j == 3 then b = 1 end
    for i = 1, dx do
      if a <= #table-2 then
        wKeyboard.setCursorPos(i+2+b,j+1)
        wKeyboard.write(table[a])
        b = b + (string.len(table[a]))
        a = a + 1
      end
    end
    wKeyboard.setCursorPos(10,6)
    wKeyboard.write(table[39])
    wKeyboard.setCursorPos(18,6)
    wKeyboard.write(table[40])
  end
  a = 1

end

local function clickEffect(table)
  local x, y = e[3], e[4]
  if table == "/\\" then
    x, y = 3, 5
  elseif table == "<=" then
    x, y = 20, 5
  elseif table == "SPACE" then
    x, y = 10, 6
  elseif table == "Enter" then
    x, y = 18, 6
  end
  term.setCursorPos(x, y)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.write(table)
  sleep(0.1)
  term.setCursorPos(x, y)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.write(table)
end

local function checkKey(table)
  local bx, by = 1, 1
  local nline = 10

  for j = 1, 3 do
    by = by + 1
    bx = 1
    if j == 3 then
      nline = 9
      bx = 2
    end
    for i = 1, nline do
      bx = bx + 2
      if e[3] == bx and e[4] == by then
        return table[((j-1)*10 + i)]
      end
    end
  end
  by = 5
  bx = 6-2
  for i = 1, 7 do
    bx = bx + 2
    if e[3] == bx and e[4] == by then
      return table[(30 + i)]
    end
  end
  if e[3] >= 3 and e[3] <= 4 and e[4] == 5 then
    return table[30]
  elseif e[3] >= 20 and e[3] <= 21 and e[4] == 5 then
    return table[38]
  elseif e[3] >= 10 and e[3] < 15 and e[4] == 6 then
    return table[39]
  elseif e[3] >= 18 and e[3] < 23 and e[4] == 6 then
    return table[40]
  end
  return nil
end

draw_keyboard(layout)
wKeyboard.setCursorPos(1,1)
while true do
  wKeyboard.setCursorBlink(true)
  e = {os.pullEvent("mouse_click")}
  if checkKey(layout) ~= nil then
    clickEffect(checkKey(layout))
    if checkKey(layout) == key[30] then
      --shift
      if layout == key then
        layout = l_key
      else
        layout = key
      end
      wKeyboard.clear()
      draw_keyboard(layout)
      wKeyboard.redraw()
    elseif checkKey(layout) == key[38] then
      --backspace
      table.remove(txt)
      wKeyboard.setCursorPos(1,1)
      wKeyboard.clearLine()
    elseif checkKey(layout) == layout[39] then
      table.insert(txt, " ")
    elseif checkKey(layout) == layout[40] then
      --enter
    else
      table.insert(txt, checkKey(layout))
    end
    wKeyboard.setCursorPos(1, 1)
    for i,_ in ipairs(txt) do
      wKeyboard.setCursorPos(i,1)
      wKeyboard.write(txt[i])
    end
  end
  os.sleep(0)
end
