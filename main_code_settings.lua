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
        settings = {"1", "1", "1", "0"} -- Default options
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

local function rewrite_tfield(arg)
  num = settings[1]
  local symbol = arg or string.char(31)
  local spaces = ""
  for i = 1, 3 - #num do
    spaces = spaces.." "
  end
  num = num..spaces..symbol
end
rewrite_tfield()

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

local function drawLine(mret, x, y, x2, y2, color)
    local ter = term.current()
    term.redirect(mret)
    paintutils.drawLine(x, y, x2, y2, color)
    term.redirect(ter)
end

local function click(title, parent, parent2, blittle)
    local tx1, ty1 = title.getPosition()
    local tx2, ty2 = title.getSize()
    local blittle = blittle
    local tf1, tf2 = 0, 0
    local x, y = e[3], e[4]
    if not parent2 then else tf1, tf2 = parent2.getPosition() tf1, tf2 = tf1-1, tf2-1 end
    if not parent then else
        local ft1, ft2 = parent.getPosition()
        x = x - ft1 - tf1 + 1
        y = y - ft2 - tf2 + 1
    end
    if blittle then tx2 = tx2/2 ty2 = ty2/3 end
	if x >= tx1 and x < tx2+tx1 and y >= ty1 and y < ty2+ty1 then
        title.setVisible(true)
		return true
    else
		return false
    end
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

local backgsett = createWindow(mainterm, 2, 2, width-2, height-2, true, true, colors.white, colors.lightGray)
blittleborder(backgsett, colors.gray)
term.redirect(backgsett)
paintutils.drawLine(24, 2, 24, (height-2)*3, colors.gray)
term.redirect(mainterm)

local Screen = createWindow(mainterm, 3, 3, 10, 1, true, false, colors.white, colors.gray, "Screen")
local timedate = createWindow(mainterm, 3, 4, 10, 1, true, false, colors.white, colors.lightGray, "Time&Date")

local page_parameters = {mainterm, 14, 3, width-15, height-3-1, false, false, colors.white, colors.lightGray}

local page1 = createWindow(mainterm, 14, 3, width-15, height-3-1, true, false, colors.white, colors.lightGray)
local swt_mon = createWindow(page1, 32, 1, 2, 1, true, true, colors.white, colors.lightBlue)
local text_swt_mon = createWindow(page1, 2, 1, 23, 1, true, false, colors.white, colors.lightGray, "Start system at monitor")

local tfield = createWindow(page1, 30, 3, 4, 1, true, false, colors.black, colors.white, num)
local tfieldmenu = createWindow(page1, 30, 4, 4, 10, false, false, colors.black, colors.white, nil)
local tf_0_5_menu = createWindow(tfieldmenu, 1, 1, 4, 1, true, false, colors.black, colors.white, "0.5|")
local tf_1_menu = createWindow(tfieldmenu, 1, 2, 4, 1, true, false, colors.black, colors.white, "1  |")
local tf_1_5_menu = createWindow(tfieldmenu, 1, 3, 4, 1, true, false, colors.black, colors.white, "1.5|")
local tf_2_menu = createWindow(tfieldmenu, 1, 4, 4, 1, true, false, colors.black, colors.white, "2  |")
local tf_2_5_menu = createWindow(tfieldmenu, 1, 5, 4, 1, true, false, colors.black, colors.white, "2.5|")
local tf_3_menu = createWindow(tfieldmenu, 1, 6, 4, 1, true, false, colors.black, colors.white, "3  |")
local tf_3_5_menu = createWindow(tfieldmenu, 1, 7, 4, 1, true, false, colors.black, colors.white, "3.5|")
local tf_4_menu = createWindow(tfieldmenu, 1, 8, 4, 1, true, false, colors.black, colors.white, "4  |")
local tf_4_5_menu = createWindow(tfieldmenu, 1, 9, 4, 1, true, false, colors.black, colors.white, "4.5|")
local tf_5_menu = createWindow(tfieldmenu, 1, 10, 4, 1, true, false, colors.black, colors.white, "5  |")

local tfmbtns = {tf_0_5_menu, tf_1_menu, tf_1_5_menu, tf_2_menu, tf_2_5_menu, tf_3_menu, tf_3_5_menu, tf_4_menu, tf_4_5_menu, tf_5_menu}

local text_tfield = createWindow(page1, 2, 3, 23, 1, true, false, colors.white, colors.lightGray, "Textscale")

local page2 = createWindow(unpack(page_parameters))
local swt_time = createWindow(page2, 32, 1, 2, 1, true, true, colors.white, colors.lightBlue)
local text_swt_time = createWindow(page2, 2, 1, 23, 1, true, false, colors.white, colors.lightGray, "Enable 24h format")
local swt_minetime = createWindow(page2, 32, 3, 2, 1, true, true, colors.white, colors.lightBlue)
local text_swt_minetime = createWindow(page2, 2, 3, 23, 1, true, false, colors.white, colors.lightGray, "Enable minecraft time")
local swt_sec = createWindow(page2, 32, 5, 2, 1, true, true, colors.white, colors.lightBlue)
local text_swt_sec = createWindow(page2, 2, 5, 23, 1, true, false, colors.white, colors.lightGray, "Show seconds")

local wins = {text_swt_mon, swt_mon, text_tfield, tfield, tfieldmenu, --page1
              swt_time, text_swt_time, swt_minetime, text_swt_minetime, swt_sec, text_swt_sec} --page2

local pages = {page1, page2}

local Btns = {Screen, timedate}

local function  redraw_tfmbtns()
  for i = 1, #tfmbtns do
    tfmbtns[i].redraw()
  end
end

local function redrawBtns()
  for i = 1, #Btns do
    Btns[i].redraw()
  end
end

local function redrawPages()
  for i = 1, #pages do
    pages[i].clear()
    pages[i].redraw()
  end
end

local function writenumtotfield()
  local trm = term.current()
  term.redirect(tfield)
  term.setCursorPos(1, 1)
  term.clear()
  write(num)
  term.redirect(trm)
  tfield.redraw()
end

local function redrawWins()
  term.clear()
  backgsett.redraw()
  for i = 1, #wins do
    wins[i].redraw()
  end
end
redrawWins()

local function clickEffect(win)
	local _, nHeight = win.getSize()
	local text = {}
	for i = 1, nHeight do
		text = {win.getLine(i)}
		if type(text[1]) == "string" then
			break
		end
	end
  win.setCursorPos(1,1)
  win.blit(text[1],text[3], text[2])
  sleep(0.1)
  win.setCursorPos(1,1)
  win.blit(text[1],text[2],text[3])
end

local function opentfmenu()
  tfieldmenu.setVisible(true)
  tfieldmenu.setBackgroundColor(colors.white)
  tfieldmenu.redraw()
  redraw_tfmbtns()
  rewrite_tfield(string.char(30))
  writenumtotfield()
end

local function closetfmenu()
  tfieldmenu.setBackgroundColor(colors.lightGray)
  tfieldmenu.clear()
  tfieldmenu.setVisible(false)
  rewrite_tfield(string.char(31))
  writenumtotfield()
end

local function tfb_clicked()
  for i,_ in ipairs(tfmbtns) do
    if click(tfmbtns[i], tfieldmenu, page1) then
      clickEffect(tfmbtns[i])
      return updateSetting(settings, 1, (i/2))
    end
  end
end

local function centerText(text, y)
  local w, h = term.getSize()
  local txt = text
  term.setCursorPos((w / 2 - math.floor(#txt / 2) + 1), y)
  write(txt)
end

local function surewin()
  local swin = createWindow(mainterm, 12, 4, 26, 12, true, false, colors.white, colors.red)
  local trm = term.current()
  term.redirect(swin)
  centerText("WARNING!", 2)
  centerText("Setting textscale 3+", 4)
  centerText("can to broke your system.", 5)
  centerText("Are you sure to do it?", 6)

  local blittleyes = createWindow(swin, 5, 9, 7, 3, true, true, colors.black, colors.red)
  term.redirect(blittleyes)
  paintutils.drawBox(1*2, 1*3, 7*2-1, 2*3+1, colors.white)

  local yes = createWindow(swin, 6, 10, 5, 1, true, false, colors.white, colors.red)
  term.redirect(yes)
  centerText("Yes", 1)

  local blittleno = createWindow(swin, 16, 9, 6, 3, true, true, colors.black, colors.red)
  term.redirect(blittleno)
  paintutils.drawBox(1*2, 1*3, 6*2-1, 2*3+1, colors.white)

  local no = createWindow(swin, 17, 10, 4, 1, true, false, colors.white, colors.red)
  term.redirect(no)
  centerText("No", 1)
  term.redirect(trm)

  while true do
    e = {os.pullEvent()}
    if e[1] == "mouse_click" or e[1] == "monitor_touch" then
      if click(yes, swin) then
        clickEffect(yes, swin)
        return true
      elseif click(no, swin) then
        clickEffect(no, swin)
        return false
      end
    end
  end
  e = {}
end

local function setVisibleAllPagesFalse()
    for i = 1, #pages do
      pages[i].setVisible(false)
      pages[i].clear()
    end
end

local function setAllBtnsDisabled()
  local txt
    for i = 1, #Btns do
        Btns[i].setBackgroundColor(colors.lightGray)
        txt = {Btns[i].getLine(1)}
        Btns[i].clear()
        Btns[i].setCursorPos(1, 1)
        Btns[i].write(unpack(txt))
        Btns[i].redraw()
    end
end

function BtnsEnable(button_name)
  local txt
  button_name.setBackgroundColor(colors.gray)
  txt = {button_name.getLine(1)}
  button_name.clear()
  button_name.setCursorPos(1,1)
  button_name.write(unpack(txt))
end

local function redrawAll()
  redrawPages()
  redrawWins()
  redraw_tfmbtns()
  redrawBtns()
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

set_1st_swt(swt_mon, 2)
set_1st_swt(swt_time, 3)
set_1st_swt(swt_minetime, 4)
set_1st_swt(swt_sec, 5)

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

local function pageOpen(page, btn)
  clickEffect(btn)
  setVisibleAllPagesFalse()
  page.setVisible(true)
  redrawWins()
  setAllBtnsDisabled()
  redrawPages()
  BtnsEnable(btn)
end

redrawAll()
while true do
  e = {os.pullEvent()}
  if e[1] == "mouse_click" or e[1] == "monitor_touch" then
    if not page1.isVisible() and click(Screen) then
      pageOpen(page1, Screen)
    end
    if not page2.isVisible() and click(timedate) then
      pageOpen(page2, timedate)
    end
    if page1.isVisible() then
      if click(swt_mon, page1, _, true) then
        change_swt(swt_mon, 2)
      end
      if click(tfield, page1) then
      if not tfieldmenu.isVisible() then
        opentfmenu()
      else
        closetfmenu()
      end
      end
      if tfieldmenu.isVisible() and click(tfieldmenu, page1) then
      local set1 = settings[1]
      tfb_clicked()
      closetfmenu()
      if tonumber(settings[1]) >= 3 then
        local sure = surewin()
        if not sure then
          settings[1] = set1
          closetfmenu()
        end
      end
      elseif tfieldmenu.isVisible() and not click(tfieldmenu, page1) and not click(tfield, page1) then
        closetfmenu()
      end
      e = {}

    end
    if page2.isVisible() then
      if click(swt_time, page2, _, true) then
        change_swt(swt_time, 3)
      end
      if click (swt_minetime, page2, _, true) then
        change_swt(swt_minetime, 4)
      end
      if click (swt_sec, page2, _, true) then
        change_swt(swt_sec, 5)
      end
    end

    --TO DO: clock options: UTC???;

    writeSettings(filename, settings)
    redrawWins()
  end
  redrawAll()
  os.sleep(0)
end
