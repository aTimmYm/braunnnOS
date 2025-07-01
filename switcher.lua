os.loadAPI("blittle")
local width, height = term.getSize()
local mainterm = term.current()
local num
local filename = "/System/app/Settings/settings.conf"

function _G.printTable(...)
	local inp = {...}
	for	i, v in pairs(inp) do
		if type(inp[i]) == "table" then
			for i,v in pairs(inp[i]) do
				print(i,"-",v)
			end
		else
			error("The variable type 'table' is not a table")
		end
	end
end

local function readSettings(filename)
    local settings = {}
    if fs.exists(filename) then
        local file = fs.open(filename, "r")
        local line = file.readLine()
        while line do
            table.insert(settings, line)
            line = file.readLine()
        end
        file.close()
    else
        settings = {"1", "1", "1", "0", "0"} -- Default options
    end
    return settings
    --settings[1] = textscale
    --settings[2] = monitor output (swt_mon)
    --settings[3] = time format (swt_time)
    --settings[4] = minecraft time (swt_mine_time)
    --settings[5] = show seconds (swt_sec)
end

local function updateSetting(settings, lineNumber, newValue)
    if settings[lineNumber] then
        settings[lineNumber] = tostring(newValue)
    else
        print("error update file")
    end
end

local function writeSettings(filename, settings)
    local file = fs.open(filename, "w")
    for _, line in ipairs(settings) do
        file.writeLine(line)
    end
    file.close()
end

local settings = readSettings(filename)
term.setBackgroundColor(colors.lightGray)
term.clear()

local function createWindow(ter, x, y, w, h, visible, blit, tColor, bColor, text)
	local win
	if not ter then ter = term.current() end
	if not tColor then tColor = colors.black end
	if not bColor then bColor = colors.white end
	if not text then text = "" end
	if blit then win = blittle.createWindow(ter, x, y, w, h, visible)
	else win = window.create(ter, x, y, w, h, visible) end
    	win.setBackgroundColor(bColor)
    	win.setTextColor(tColor)
    	win.clear()
		win.write(text)
	return win
end

local function blittleborder(title, color)
	local window = title
    ter = term.current()
	term.redirect(window)
	local w, d = window.getSize()
	paintutils.drawBox(1, 1, w, d, color)
	term.redirect(mainterm)
end

local function animation_swt(trm, on)
  term.redirect(trm)
  local frames = 4
  if on then
      local i = 1
      while i <= frames do
        term.redirect(trm)

        paintutils.drawFilledBox(i - 1 , 1, frames - i, 3, colors.lightBlue)
        paintutils.drawFilledBox(i + 1 , 1, frames, 3, colors.white)
        paintutils.drawFilledBox(i, 1, i, 3, colors.black)

        i = i + 1
        os.sleep(0.05)
      end
  else
      local i = 4
      while i >= 1 do
        term.redirect(trm)

        paintutils.drawFilledBox(i - 1, 1, frames - i, 3, colors.lightBlue)
        paintutils.drawFilledBox(i + 1, 1, frames, 3, colors.white)
        paintutils.drawFilledBox(i, 1, i, 3, colors.black)

        i = i - 1
        os.sleep(0.05)
      end
  end
  term.redirect(mainterm)
end

local function set_1st_swt(swt, i)
  if settings[i] == "0" then
    term.redirect(swt)
    term.setBackgroundColor(colors.white)
    term.clear()
    paintutils.drawFilledBox(1,1,1,3, colors.black)
    term.redirect(mainterm)
  elseif settings[i] == "1" then
    term.redirect(swt)
    term.setBackgroundColor(colors.lightBlue)
    term.clear()
    paintutils.drawFilledBox(4,1,4,3, colors.black)
    term.redirect(mainterm)
  else
    error("file incorrect")
  end
end

local function change_swt(trm, i)
  if settings[i] == "1" then
      term.redirect(trm)
      term.clear()
      updateSetting(settings, i, 0)
      term.redirect(mainterm)
      animation_swt(trm, false)
  elseif settings[i] == "0" then
      term.redirect(trm)
      term.clear()
      updateSetting(settings, i, 1)
      term.redirect(mainterm)
      animation_swt(trm, true)
  else
      error("file 'settings.conf' incorrect")
  end
end

local function create_switcher(parent_term, xpos, ypos)
  local swt = createWindow(term.current(), 32, 1, 2, 1, true, true, colors.white, colors.lightBlue)
  set_1st_swt(swt, 1)
  return swt
end