--CC:Tweaked Lua Minecraft CraftOS bOS™
--lib/ui.lua V3.1.2
local UI = {}

local c = require("cfunc")
local expect = require("cc.expect")
local dM = require("deskManager")
local EVENTS = require("events")

local string_rep = string.rep
local string_sub = string.sub
local string_find = string.find
local string_char = string.char

---Basic *class*. Using automatically to create all another *classes*.
---@param root table
---@param bg color|number|nil
---@param txtcol color|number|nil
---@return table object widget (bigbrother)
local function New_Widget(root,bg,txtcol)
    local instance = {}
    instance.pos = {x=1,y=1}
    instance.size = {w=1,h=1}
    instance.bg = bg or colors.black
    instance.txtcol = txtcol or colors.white
    instance.dirty = true
    instance.parent = nil
    instance.root = root

    instance.check = function(self,x,y)
        return (x >= self.pos.x and x < self.size.w + self.pos.x and
                y >= self.pos.y and y < self.size.h + self.pos.y)
    end
    instance.onKeyDown = function(self,key,held) return true end
    instance.onKeyUp = function(self,key) return true end
    instance.onCharTyped = function(self,chr) return true end
    instance.onPaste = function(self,text) return true end
    instance.onMouseDown = function(self,btn,x,y) return true end
    instance.onMouseUp = function(self,btn,x,y) return true end
    instance.onMouseScroll = function(self,dir,x,y) return true end
    instance.onMouseDrag = function(self,btn,x,y) return true end
    instance.onFocus = function(self,focused) return true end
    instance.draw = function(self) end
    instance.redraw = function(self)
        if self.dirty then self:draw() self.dirty = false end
    end
    instance.reSize = function(self) end
    instance.onLayout = function(self) self.dirty = true end
    instance.onEvent = function(self,evt)
        if evt[1] == "mouse_drag" then
            return self:onMouseDrag(evt[2],evt[3],evt[4])
        elseif evt[1] == "mouse_up" then
            return self:onMouseUp(evt[2],evt[3],evt[4])
        elseif evt[1] == "mouse_click" then
            if self.root then self.root.focus = self end
            return self:onMouseDown(evt[2],evt[3],evt[4])
        elseif evt[1] == "mouse_scroll" then
            return self:onMouseScroll(evt[2],evt[3],evt[4])
        elseif evt[1] == "char" then
            return self:onCharTyped(evt[2])
        elseif evt[1] == "key" then
            return self:onKeyDown(evt[2],evt[3])
        elseif evt[1] == "key_up" then
            return self:onKeyUp(evt[2])
        elseif evt[1] == "paste" then
            return self:onPaste(evt[2])
        end
        return false
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param bg_off color|number|nil
---@param bg_on color|number|nil
---@param switch_color color|number|nil
---@param on boolean|nil
---@return table object tumbler (switcher)
function UI.New_Tumbler(root, bg_off, bg_on, switch_color, on)
    expect(1, root, "table")
    expect(2, bg_off, "number", "nil")
    expect(3, bg_on, "number", "nil")
    expect(4, switch_color, "number", "nil")
    expect(5, on, "boolean", "nil")

    local instance = New_Widget(root)
    instance.size = {w = 2, h = 1}
    instance.on = on or false
    instance.bg_off = bg_off or colors.gray
    instance.bg_on = bg_on or colors.lime
    instance.switch_color = switch_color or colors.white
    instance.animating = false
    instance.animation_frames = {
        off = {
            {char = string_char(149), txtcol = instance.switch_color, bgcol = instance.bg_off},
            {char = " ", txtcol = instance.bg_off, bgcol = instance.bg_off}
        },
        anim1 = {
            {char = string_char(149), txtcol = instance.bg_on, bgcol = instance.switch_color},
            {char = " ", txtcol = instance.bg_off, bgcol = instance.bg_off}
        },
        anim2 = {
            {char = " ", txtcol = instance.bg_on, bgcol = instance.bg_on},
            {char = string_char(149), txtcol = instance.switch_color, bgcol = instance.bg_off}
        },
        on = {
            {char = " ", txtcol = instance.bg_on, bgcol = instance.bg_on},
            {char = string_char(149), txtcol = instance.bg_on, bgcol = instance.switch_color}
        }
    }
    instance.current_frame = instance.on and "on" or "off"
    instance.animation_speed = 0.05  -- Задержка между кадрами в секундах
    instance.timer_id = nil
    instance.animation_direction = nil  -- "to_on" или "to_off"

    instance.draw = function(self)
        local frame = self.animation_frames[self.current_frame]
        for i = 1, 2 do
            local p = frame[i]
            c.write(p.char, self.pos.x + i - 1, self.pos.y, p.bgcol, p.txtcol)
        end
    end
    instance.startAnimation = function(self,direction)
        if self.animating then return end
        self.animating = true
        self.animation_direction = direction
        self.current_frame = (direction == "to_on") and "anim1" or "anim2"
        self.dirty = true
        self.timer_id = os.startTimer(self.animation_speed)
    end
    instance.updateAnimation = function(self)
        if self.animation_direction == "to_on" then
            if self.current_frame == "anim1" then
                self.current_frame = "anim2"
                self.timer_id = os.startTimer(self.animation_speed)
            elseif self.current_frame == "anim2" then
                self.current_frame = "on"
                self.animating = false
                self.on = true
            end
        elseif self.animation_direction == "to_off" then
            if self.current_frame == "anim2" then
                self.current_frame = "anim1"
                self.timer_id = os.startTimer(self.animation_speed)
            elseif self.current_frame == "anim1" then
                self.current_frame = "off"
                self.animating = false
                self.on = false
            end
        end
        self.dirty = true
    end
    instance.onMouseDown = function(self,btn, x, y)
        if not self.animating then
            self:startAnimation(self.on and "to_off" or "to_on")
            self:pressed()
        end
        return true
    end
    local temp_onEvent = instance.onEvent
    instance.onEvent = function(self,evt)
        if evt[1] == "timer" and evt[2] == self.timer_id then
            self:updateAnimation()
            return true
        end
        return temp_onEvent(self, evt)
    end
    instance.pressed = function(self) end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param count number|nil
---@param bg color|number|nil
---@param txtcol color|number|nil
---@return table object radioButton_horizontal
function UI.New_RadioButton_horizontal(root,count,bg,txtcol)
    expect(1, root, "table")
    expect(2, count, "number", "nil")
    expect(3, bg, "number", "nil")
    expect(4, txtcol, "number", "nil")

    local instance = New_Widget(root,bg,txtcol)
    instance.count = (count and count >= 1 and count or 1)
    instance.size.w = instance.count
    instance.item = 1

    instance.draw = function(self)
        for i = 1, self.count do
            if self.item == i then
                c.write(string_char(7),self.pos.x+i-1,self.pos.y,self.bg,self.txtcol)
            else
                c.write(string_char(7),self.pos.x+i-1,self.pos.y,self.bg,colors.gray)
            end
        end
    end
    instance.changeCount = function(self,arg)
        self.count = arg
        self.size.w = arg
        self.dirty = true
    end
    instance.pressed = function(self) end
    instance.onMouseUp = function(self,btn,x,y)
        if self:check(x,y) then
            self.item = x - self.pos.x+1
            self.dirty = true
            self:pressed()
        end
        return true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param count number|nil
---@param text string[]|nil table of strings, example: {"string1", "string2"}
---@param bg color|number|nil
---@param txtcol color|number|nil
---@return table object radioButton
function UI.New_RadioButton(root,count,text,bg,txtcol)
    expect(1, root, "table")
    expect(2, count, "number", "nil")
    expect(3, text, "table", "nil") -- ← table of strings
    expect(4, bg, "number", "nil")
    expect(5, txtcol, "number", "nil")

    local instance = UI.New_RadioButton_horizontal(root,count,bg,txtcol)
    if text then
        instance.text = text
        instance.count = #instance.text
    else
        instance.text = {}
        for i = 1, instance.count do
            instance.text[i] = ""
        end
    end
    local t = c.findMaxLenStrOfArray(instance.text)
    instance.size = {w=(t == 0 and 1 or t+2),h=instance.count}

    instance.draw = function(self)
        for i,_ in pairs(self.text) do
            if self.item == i then
                c.write(string_char(7),self.pos.x,self.pos.y+i-1,self.bg,self.txtcol)
                c.write(string_rep(" ",math.min(#self.text[i],1))..self.text[i],self.pos.x+1,self.pos.y+i-1,self.bg,self.txtcol)
            else
                c.write(string_char(7),self.pos.x,self.pos.y+i-1,self.bg,colors.gray)
                c.write(string_rep(" ",math.min(#self.text[i],1))..self.text[i],self.pos.x+1,self.pos.y+i-1,self.bg,self.txtcol)
            end
        end
    end
    instance.onMouseUp = function(self,btn,x,y)
        if self:check(x,y) then
            self.item = y - self.pos.y+1
            self.dirty = true
            self:pressed()
        end
        return true
    end
    return instance
end


---Creating new *object* of *class*
---@param root table
---@param text string|nil
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param align string|nil
---@return table object label
function UI.New_Label(root,text,bg,txtcol,align)
    expect(1, root, "table")
    expect(2, text, "string", "nil")
    expect(3, bg, "number", "nil")
    expect(4, txtcol, "number", "nil")
    expect(5, align, "string", "nil")

    local instance = New_Widget(root,bg,txtcol)
    instance.text = text or ""
    instance.align = align or "center"

    instance.draw = function (self, bg_override, txtcol_override)
        bg_override = bg_override or self.bg
        txtcol_override = txtcol_override or self.txtcol
        local lines = {}
        if #self.text <= self.size.w then
            table.insert(lines, self.text)
        else
            local mass = {}
            for w in self.text:gmatch("%S+") do
                table.insert(mass, w)
            end
            local row_txt = ""
            local i = 1
            while i <= #mass do
                local word = mass[i]
                if #word > self.size.w then
                    local remainder = string_sub(word, self.size.w + 1)
                    if remainder ~= "" then
                        table.insert(mass, i + 1, remainder)
                    end
                    mass[i] = string_sub(word, 1, self.size.w)
                    word = mass[i]
                end
                local space_len = (row_txt == "" and 0 or 1)
                if #row_txt + space_len + #word <= self.size.w then
                    row_txt = row_txt .. (row_txt == "" and "" or " ") .. word
                    i = i + 1
                else
                    if row_txt ~= "" then
                        table.insert(lines, row_txt)
                        row_txt = ""
                    end
                end
                if #lines >= self.size.h then break end
            end
            if row_txt ~= "" and #lines < self.size.h then
                table.insert(lines, row_txt)
            end
        end

        local horiz_align = "center"
        if string_find(self.align, "left") then
            horiz_align = "left"
        elseif string_find(self.align, "right") then
            horiz_align = "right"
        end

        local num_lines = #lines
        local vert_align = "center"
        if string_find(self.align, "top") then
            vert_align = "top"
        elseif string_find(self.align, "bottom") then
            vert_align = "bottom"
        end

        local start_y = self.pos.y
        if vert_align == "top" then
            start_y = self.pos.y
        elseif vert_align == "bottom" then
            start_y = self.pos.y + self.size.h - num_lines
        else  -- center
            start_y = self.pos.y + math.floor((self.size.h - num_lines) / 2)
        end
        start_y = math.max(start_y, self.pos.y)

        for i = self.pos.y, start_y - 1 do
            c.write(string_rep(" ", self.size.w), self.pos.x, i, bg_override, txtcol_override)
        end

        for j = 1, num_lines do
            local line = lines[j]
            local line_len = #line
            local x_pos = self.pos.x
            if horiz_align == "left" then
                x_pos = self.pos.x
            elseif horiz_align == "right" then
                x_pos = self.pos.x + self.size.w - line_len
            else  -- center
                x_pos = self.pos.x + math.floor((self.size.w - line_len) / 2)
            end
            local left_pad = string_rep(" ", x_pos - self.pos.x)
            local right_pad = string_rep(" ", self.size.w - (x_pos - self.pos.x + line_len))
            local full_line = left_pad .. line .. right_pad
            c.write(full_line, self.pos.x, start_y + j - 1, bg_override, txtcol_override)
        end

        local end_y = start_y + num_lines - 1
        for i = end_y + 1, self.pos.y + self.size.h - 1 do
            c.write(string_rep(" ", self.size.w), self.pos.x, i, bg_override, txtcol_override)
        end
    end
    instance.setText = function (self, text)
        self.text = text
        self.dirty = true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param text string|nil
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param align string|nil
---@return table object button
function UI.New_Button(root,text,bg,txtcol,align)
    expect(1, root, "table")
    expect(2, text, "string", "nil")
    expect(3, bg, "number", "nil")
    expect(4, txtcol, "number", "nil")
    expect(5, align, "string", "nil")

    local instance = UI.New_Label(root,_,bg,txtcol,align)
    instance.text = text or "button"
    instance.held = false
    instance.size.w = #instance.text

    local temp_draw = instance.draw
    instance.draw = function(self)
        if self.held then
            temp_draw(self, self.txtcol, self.bg)
        else
            temp_draw(self, self.bg, self.txtcol)
        end
    end
    instance.pressed = function(self) end
    instance.onMouseDown = function(self,btn,x,y)
        self.held = true
        self.dirty = true
        return true
    end
    instance.onMouseUp = function(self,btn,x,y)
        if self:check(x,y) and self.held == true then self:pressed() end
        self.held = false
        self.dirty = true
        return true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param text string|nil
---@param filepath string
---@param icopath string
---@param bg number|nil
---@param txtcol number|nil
---@return table object shortcut
function UI.New_Shortcut(root, text, filepath, icopath,bg,txtcol)
    expect(1, root, "table")
    expect(2, text, "string", "nil")
    expect(3, filepath, "string")
    expect(4, icopath, "string")
    expect(5, bg, "number", "nil")
    expect(6, txtcol, "number", "nil")

    local instance = UI.New_Button(root,text,bg,txtcol)
    instance.icoPath = icopath or "sbin/ico/default.ico"
    instance.needArgs = {}

    if fs.exists(filepath) then
       instance.filePath = filepath
    else
        return error("File doesn't exist")
    end
    instance.blittle_img = blittle.load(instance.icoPath)
    instance.size = {w=instance.blittle_img.width,h=instance.blittle_img.height + 1}

    instance.draw = function(self)
        c.drawFilledBox(self.pos.x, self.pos.y, self.size.w + self.pos.x - 1, self.size.h + self.pos.y - 1, self.bg)

        local dX = math.floor((self.size.w-self.blittle_img.width)/2) + self.pos.x
        local dY = math.floor((self.size.h-1-self.blittle_img.height)/2) + self.pos.y
        blittle.draw(self.blittle_img, dX, dY)
        local txtcol = self.held and colors.lightGray or self.txtcol
        if #self.text >= self.size.w then
            c.write(string_sub(self.text, 1, self.size.w-2).."..",
            self.pos.x, dY + self.blittle_img.height,self.bg,txtcol)
        else
            c.write(string_rep(" ",math.floor((self.size.w-#self.text)/2))..self.text..
            string_rep(" ", self.size.w - (math.floor((self.size.w-#self.text)/2)+self.pos.x + #self.text)),
            self.pos.x, dY + self.blittle_img.height,self.bg,txtcol)
        end
    end

    instance.pressed = function(self)
        if self.needArgs[1] and not self.needArgs[2] then
            local path = self.filePath
            local args = ""
            local dial = UI.New_DialWin(self.root)
            dial:callWin(" Arguments ", "Enter arguments")
            dial.btnOK.pressed = function(self)
                args = dial.child[2].text
                self.parent:removeWin()
                c.openFile(self.root,path,args)
            end
        else
            c.openFile(self.root,self.filePath,self.needArgs[2])
        end
    end
    return instance
end

---Creating new *object* of *class* "shortcut"
---@param root table
---@param text string|nil
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param align string|nil
---@param scroll_speed number|nil
---@param gap string|nil
---@return table return Running_Label
function UI.New_Running_Label(root, text, bg, txtcol, align, scroll_speed, gap)
    expect(1, root, "table")
    expect(2, text, "string", "nil")
    expect(3, bg, "number", "nil")
    expect(4, txtcol, "number", "nil")
    expect(5, align, "string", "nil")
    expect(6, scroll_speed, "number", "nil")
    expect(7, gap, "string", "nil")

    local instance = UI.New_Label(root, text, bg, txtcol, align)
    instance.scroll_speed = scroll_speed or 0.5  -- Задержка между сдвигами в секундах (по умолчанию 0.5)
    instance.scroll_pos = 1
    instance.timer_id = nil
    instance.scrolling = false
    instance.scroll_gap = gap or " "

    instance.setText = function(self,text)
        if self.text ~= text then self.scroll_pos = 1 end
        self.text = text
        self:checkScrolling()
        self.dirty = true
    end
    instance.checkScrolling = function(self)
        if #self.text > self.size.w then
            self.scrolling = true
            self:startTimer()
        else
            self.scrolling = false
            self:stopTimer()
            self.scroll_pos = 1
        end
    end
    instance.startTimer = function(self)
        if not self.timer_id then
            self.timer_id = os.startTimer(self.scroll_speed)
        end
    end
    instance.stopTimer = function(self)
        self.timer_id = nil
    end
    local temp_draw = instance.draw
    instance.draw = function(self,bg_override, txtcol_override)
        bg_override = bg_override or self.bg
        txtcol_override = txtcol_override or self.txtcol
        self:checkScrolling()
        if not self.scrolling then
            -- Если не нужно прокручивать, рисуем как обычный label
            temp_draw(self, bg_override, txtcol_override)
            return
        end
        -- Для прокрутки: собираем visible_text по символам с модульной адресацией
        local segment = (self.text or "") .. (self.scroll_gap)
        local cycle_len = #segment
        if cycle_len == 0 then
            local visible_text = string_rep(" ", self.size.w)
            c.write(visible_text, self.pos.x, self.pos.y, bg_override, txtcol_override)
            return
        end

        -- нормалізуємо позицію в межах циклу
        local pos = ((self.scroll_pos - 1) % cycle_len) + 1

        -- будуємо видимий рядок по-символьно, щоб уникнути артефактів при обгортанні
        local visible_chars = {}
        for i = 0, self.size.w - 1 do
            local idx = ((pos - 1 + i) % cycle_len) + 1
            visible_chars[#visible_chars + 1] = string_sub(segment, idx, idx)
        end
        local visible_text = table.concat(visible_chars)

        -- Обрабатываем выравнивание (только горизонтальное, вертикальное игнорируем для простоты, так как h=1 предположительно)
        local horiz_align = "center"
        if string_find(self.align, "left") then
            horiz_align = "left"
        elseif string_find(self.align, "right") then
            horiz_align = "right"
        end

        local x_pos = self.pos.x
        if horiz_align == "left" then
            x_pos = self.pos.x
        elseif horiz_align == "right" then
            x_pos = self.pos.x + self.size.w - #visible_text
        else  -- center
            x_pos = self.pos.x + math.floor((self.size.w - #visible_text) / 2)
        end

        local left_pad = string_rep(" ", x_pos - self.pos.x)
        local right_pad = string_rep(" ", self.size.w - (x_pos - self.pos.x + #visible_text))
        local full_line = left_pad .. visible_text .. right_pad

        c.write(full_line, self.pos.x, self.pos.y, bg_override, txtcol_override)

        -- Очистка остальных строк, если h > 1 (хотя для бегущей строки обычно h=1)
        for i = self.pos.y + 1, self.pos.y + self.size.h - 1 do
            c.write(string_rep(" ", self.size.w), self.pos.x, i, bg_override, txtcol_override)
        end
    end
    local temp_onEvent = instance.onEvent
    instance.onEvent = function(self,evt)
        if evt[1] == "timer" and evt[2] == self.timer_id then
            if self.scrolling then
                self.scroll_pos = self.scroll_pos + 1
                local cycle_len = (#(self.text or "") + #(self.scroll_gap or ""))
                if cycle_len <= 0 then cycle_len = 1 end
                if self.scroll_pos > cycle_len then
                    self.scroll_pos = 1
                end
                self.dirty = true
                self.timer_id = os.startTimer(self.scroll_speed)  -- Перезапускаем таймер
            else
                self.timer_id = nil  -- Не перезапускаем, если прокрутка не нужна
            end
            return true
        end
        return temp_onEvent(self,evt)
    end
    local temp_onLayout = instance.onLayout
    instance.onLayout = function(self)
        temp_onLayout(self)
        self:checkScrolling()
    end
    return instance
end

---Creating new *object* of *class* "scrollbar" which connected at another *object*
---@param obj table *object*
---@return table return scrollbar
function UI.New_Scrollbar(obj)
    expect(1, obj, "table")

    local instance = New_Widget(obj.root, obj.bg, obj.txtcol)
    instance.obj = obj
    instance.bg = instance.obj.bg
    instance.txtcol = instance.obj.txtcol
    instance.obj.scrollbar = instance
    instance.held = 0  -- 0: none, 1: up arrow, 2: slider, 3: down arrow
    instance.drag_offset = 0

    instance.draw = function(self)
        local slider_height = self:getSliderHeight()
        local slider_offset = self:getSliderOffset()
        local slider_y_start = self.pos.y + 1 + slider_offset

        -- Фон трека
        for y = self.pos.y + 1, slider_y_start - 1 do
            c.write(" ", self.pos.x, y, self.bg, self.bg)
        end
        for y = slider_y_start + slider_height, self.pos.y + self.size.h - 2 do
            c.write(" ", self.pos.x, y, self.bg, self.bg)
        end

        -- Стрелка вверх
        local up_bg, up_fg = (self.held == 1 and self.txtcol or self.bg), (self.held == 1 and self.bg or self.txtcol)
        c.write(string_char(30), self.pos.x, self.pos.y, up_bg, up_fg)

        -- Стрелка вниз
        local down_bg, down_fg = (self.held == 3 and self.txtcol or self.bg), (self.held == 3 and self.bg or self.txtcol)
        c.write(string_char(31), self.pos.x, self.pos.y + self.size.h - 1, down_bg, down_fg)

        -- Ползунок
        for y = slider_y_start, math.min(slider_y_start + slider_height - 1, self.pos.y + self.size.h - 2) do
            c.write(" ", self.pos.x, y, self.txtcol, self.txtcol)  -- Filled pixel
        end
    end
    instance.setObj = function(self,obj)
        self.obj = obj
        self.bg = self.obj.bg
        self.txtcol = self.obj.txtcol
        self.dirty = true
    end
    instance.getTrackHeight = function(self)
        return self.size.h - 2
    end
    instance.getSliderHeight = function(self)
        local track_height = self:getTrackHeight()
        local total_items = self.obj.len or #self.obj.array
        local visible_items = self.obj.size.h
        return math.max(1, c.round(track_height * (visible_items / total_items)))
    end
    instance.getMaxSliderOffset = function(self)
        return math.max(0, self:getTrackHeight() - self:getSliderHeight())
    end
    instance.getSliderOffset = function(self)
        local max_offset = self:getMaxSliderOffset()
        local scroll_fraction = (self.obj.scrollpos - 1) / math.max(1, self.obj.scrollmax - 1)
        return c.round(scroll_fraction * max_offset)
    end
    instance.checkIn = function(self,btn, x, y)
        if y == self.pos.y then
            self.held = 1  -- Up arrow
            return true
        elseif y == self.pos.y + self.size.h - 1 then
            self.held = 3  -- Down arrow
            return true
        end
        return false
    end
    instance.isOnSlider = function(self,y)
        local slider_offset = self:getSliderOffset()
        local slider_height = self:getSliderHeight()
        local slider_y_start = self.pos.y + 1 + slider_offset
        return y >= slider_y_start and y <= slider_y_start + slider_height - 1
    end
    instance.onMouseDown = function(self,btn, x, y)
        if not self:check(x, y) then return false end
        if self:checkIn(btn, x, y) then
            -- Стрелки held set в checkIn
        elseif self:isOnSlider(y) then
            self.held = 2
            local slider_offset = self:getSliderOffset()
            local slider_y_start = self.pos.y + 1 + slider_offset
            self.drag_offset = y - slider_y_start
        else
            -- Клик на трек: jump to position
            local track_y = y - (self.pos.y + 1)
            local track_height = self:getTrackHeight()
            local adj_denominator = track_height > 0 and (track_height - 1) or 1
            local scroll_fraction = track_y / adj_denominator
            local new_scrollpos = math.floor(scroll_fraction * (self.obj.scrollmax - 1)) + 1
            self.obj.scrollpos = math.max(1, math.min(new_scrollpos, self.obj.scrollmax))
            self.obj.dirty = true
        end
        self.dirty = true
        return true
    end
    instance.onMouseDrag = function(self,btn, x, y)
        if self.held ~= 2 then return false end
        local max_offset = self:getMaxSliderOffset()
        if max_offset == 0 then return true end
        local track_height = self:getTrackHeight()
        local adj_denominator = track_height > 0 and (track_height - 1) or 1
        local relative_y = y - (self.pos.y + 1) - self.drag_offset
        local scroll_fraction = relative_y / adj_denominator
        local new_scrollpos = math.floor(scroll_fraction * (self.obj.scrollmax - 1)) + 1
        self.obj.scrollpos = math.max(1, math.min(new_scrollpos, self.obj.scrollmax))
        self.obj:onLayout()
        self.dirty = true
        return true
    end
    instance.onMouseUp = function(self,btn, x, y)
        if self.held == 1 and self:check(x, y) and y == self.pos.y then
            self.obj:onMouseScroll(-1)
        elseif self.held == 3 and self:check(x, y) and y == self.pos.y + self.size.h - 1 then
            self.obj:onMouseScroll(1)
        end
        self.held = 0
        self.dirty = true
        self.obj:updateDirty()
        return true
    end
    instance.onMouseScroll = function(self,dir, x, y)
        if self:check(x, y) then
            self.obj:onMouseScroll(dir)
            self.dirty = true
            return true
        end
        return false
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param array table|nil
---@param txtcol color|number|nil
---@param bg color|number|nil
---@return table object list
function UI.New_List(root,array,txtcol,bg)
    expect(1, root, "table")
    expect(2, array, "table", "nil")
    expect(3, txtcol, "number", "nil")
    expect(4, bg, "number", "nil")

    local instance = New_Widget(root,bg,txtcol)
    instance.array = array
    instance.item = nil
    instance.item_index = nil
    instance.scrollpos = 1
    instance.scrollmax = 0

    instance.draw = function(self)
        self.scrollmax = math.max(1, #self.array - self.size.h + 1)
        self.scrollpos = math.max(1, math.min(self.scrollpos, self.scrollmax))
        for i = self.scrollpos, math.min(self.size.h + self.scrollpos - 1, #self.array) do
            c.write(string_sub(self.array[i]..string_rep(" ",self.size.w-#self.array[i]), 1, self.size.w), self.pos.x, (i-self.scrollpos)+self.pos.y, self.bg, self.txtcol)
        end
        if self.item and self.item_index then
            if (self.pos.y + self.item_index - self.scrollpos) >= self.pos.y and (self.pos.y + self.item_index - self.scrollpos) <= (self.size.h + self.pos.y - 1) then
                c.write(string_sub(self.item..string_rep(" ",self.size.w-#self.item), 1, self.size.w), self.pos.x, self.pos.y + self.item_index - self.scrollpos, self.txtcol, self.bg)
            end
        end
            if self.size.h > #self.array then
            for i = #self.array, self.size.h-1 do
                c.write(string_sub(string_rep(" ",self.size.w), 1, self.size.w), self.pos.x, i + self.pos.y, self.bg, self.txtcol)
            end
        end
    end
    instance.updateArr = function(self,array)
        self.array = array
        self.item = nil
        self.item_index = nil
        self:updateDirty()
    end
    instance.pressed = function(self) end
    instance.onMouseScroll = function(self,dir,x,y)
        local MinMax = math.min(math.max(self.scrollpos+dir,1),self.scrollmax)
        if self.scrollpos ~= MinMax then
            self.scrollpos = MinMax
            self:updateDirty()
        end
        return true
    end
    instance.onFocus = function(self,focused)
        if not focused then
            self.item = nil
            self.item_index = nil
            self.dirty = true
        end
        return true
    end
    instance.onMouseDown = function(self,btn,x,y)
        local i = -self.pos.y + y + self.scrollpos
        if i <= #self.array then
            if self.item and self.item == self.array[i] then
                self:pressed()
            elseif not self.item or self.item ~= self.array[i] then
                self.item = self.array[i]
                self.item_index = i
            end
            self.dirty = true
        end
        return true
    end
    instance.onKeyDown = function(self,key, held)
        if self.item then
            if key == keys.up then
                self.item_index = math.max(self.item_index-1,1)
                self.item = self.array[self.item_index]
            if self.item_index < self.scrollpos then
                self:onMouseScroll(1)
            end
            elseif key == keys.down then
                self.item_index = math.min(self.item_index+1,#self.array)
                self.item = self.array[self.item_index]
            if self.item_index > math.min(self.size.h + self.scrollpos - 1, #self.array) then
                self:onMouseScroll(-1)
            end
            elseif key == keys.home then
                self.scrollpos = 1
                self.item_index = 1
                self.item = self.array[self.item_index]
            elseif key == keys['end'] then
                self.scrollpos = self.scrollmax
                self.item_index = #self.array
                self.item = self.array[self.item_index]
            end
            self:updateDirty()
        end
        return true
    end
    instance.updateDirty = function(self)
        if self.scrollbar then
            self.scrollbar.dirty = true
        end
        self.dirty = true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param hint string|nil
---@param hidden boolean|nil
---@return table object Textfield
function UI.New_Textfield(root,bg,txtcol,hint,hidden)
    expect(1, root, "table")
    expect(2, bg, "number", "nil")
    expect(3, txtcol, "number", "nil")
    expect(4, hint, "string", "nil")
    expect(5, hidden, "boolean", "nil")

    local instance = New_Widget(root,bg,txtcol)
    instance.writePos = 0
    instance.hint = hint or "Type here"
    instance.text = ""
    instance.offset = #instance.text+1
    instance.hidden = hidden or false

    instance.draw = function(self)
        term.setTextColor(colors.blue)
        local text = self.text
        if self.hidden == true then
            text = string_rep("*", #self.text)
        end
        local bX = self.pos.x+self.offset-self.writePos-1
        if self.root.focus ~= self and #self.text == 0 and #self.hint <= self.size.w then
            c.write(self.hint..string_rep(" ",self.size.w-#self.hint),self.pos.x,self.pos.y,self.bg,colors.lightGray)
        else
            term.setCursorPos(bX,self.pos.y)
            c.write(string_sub(text, self.writePos + 1, math.min(#self.text,self.writePos+self.size.w))..string_rep(" ",self.size.w-#self.text+self.writePos),self.pos.x,self.pos.y,self.bg,self.txtcol)
        end
        if bX < self.pos.x or bX > self.pos.x+self.size.w-1 then term.setCursorBlink(false)
        elseif self.root.focus == self then
            term.setCursorBlink(true)
        end
    end
    instance.moveCursorPos = function(self,pos)
        self.offset = math.min(math.max(pos,1),#self.text+1)
        if self.offset - self.writePos > self.size.w then
            self.writePos = self.offset - self.size.w
        elseif self.offset - self.writePos < 1 then
            self.writePos = self.offset - 1
        end
    end
    instance.onMouseScroll = function(self,btn,x,y)
        self.writePos = math.min(math.max(self.writePos - btn,0), #self.text-self.size.w+1)
        self.dirty = true
        return true
    end
    instance.onMouseUp = function(self,btn,x,y)
        if not self:check(x,y) then
            self.dirty = true
        end
        return true
    end
    instance.onFocus = function(self,focused)
        if focused and bOS.monitor[1] and bOS.monitor[2] then
            if self.root:addChild(self.root.keyboard) then self.root:onLayout() end
        elseif not focused and bOS.monitor[1] and bOS.monitor[2] then
            if self.root:removeChild(self.root.keyboard) then self.root:onLayout() end
        end
        term.setCursorBlink(focused)
        local bX = self.pos.x+self.offset-self.writePos-1
        term.setCursorPos(bX,self.pos.y)
        self.dirty = true
        return true
    end
    instance.onMouseDown = function(self,btn,x,y)
        self:moveCursorPos(x-self.pos.x+1+self.writePos)
        term.setCursorPos(self.pos.x+self.offset-1,self.pos.y)
        self.dirty = true
        return true
    end
    instance.onCharTyped = function(self,chr)
        self.text = string_sub(self.text, 1, self.offset - 1)..chr..string_sub(self.text, self.offset, #self.text)
        self:moveCursorPos(self.offset + 1)
        self.dirty = true
        return true
    end
    instance.onPaste = function(self,text)
        self.text = string_sub(self.text, 1, self.offset - 1)..text..string_sub(self.text, self.offset, #self.text)
        self:moveCursorPos(self.offset + #text)
        self.dirty = true
        return true
    end
    instance.onKeyDown = function(self,key,held)
        if key == keys.backspace then
            self.text = string_sub(self.text, 1, math.max(self.offset - 2, 0))..string_sub(self.text, self.offset, #self.text)
            self.writePos = math.max(self.writePos - 1,0)
            self:moveCursorPos(self.offset-1)
        elseif key == keys.delete then
            self.text = string_sub(self.text, 1, self.offset - 1) .. string_sub(self.text, self.offset + 1, #self.text)
        elseif key == keys.left then
            self:moveCursorPos(self.offset-1)
        elseif key == keys.right then
            self:moveCursorPos(self.offset+1)
        elseif key == keys.enter then
            self:pressed()
        end
        self.dirty = true
        return true
    end
    instance.pressed = function(self) self:onFocus(false) self.root.focus = nil end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param on boolean|nil
---@return table object checkbox
function UI.New_Checkbox(root, bg, txtcol, on)
    expect(1, root, "table")
    expect(2, bg, "number", "nil")
    expect(3, txtcol, "number", "nil")
    expect(4, on, "boolean", "nil")

    local instance = New_Widget(root,bg,txtcol)
    if on then instance.on = on else instance.on = false end

    instance.draw = function(self)
        local bg_override, txtcol_override
        if self.held then
            bg_override, txtcol_override = self.txtcol,self.bg
        else
            bg_override, txtcol_override = self.bg,self.txtcol
        end
        if self.on then
            c.write("x", self.pos.x, self.pos.y, bg_override, txtcol_override)
        else
            c.write(" ", self.pos.x, self.pos.y, bg_override, txtcol_override)
        end
    end
    instance.pressed = function(self) end
    instance.onMouseDown = function(self,btn, x, y)
        self.held = true
        self.dirty = true
        return true
    end
    instance.onMouseUp = function(self,btn, x, y)
        if self:check(x, y) then
            self:pressed()
            self.on = not self.on
        end
        self.held = false
        self.dirty = true
        return true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param show_seconds boolean|nil
---@return table object clock
function UI.New_Clock(root, bg, txtcol, show_seconds, is_24h)
    expect(1, root, "table")
    expect(2, bg, "number", "nil")
    expect(3, txtcol, "number", "nil")
    expect(4, show_seconds, "boolean", "nil")
    expect(5, is_24h, "boolean", "nil")

    local instance = New_Widget(root, bg or root.bg, txtcol or colors.white)
    instance.show_seconds = show_seconds ~= false
    instance.is_24h = is_24h ~= false
    instance.updt_rate = 1

    local function updateFormat()
        if instance.is_24h then
            instance.format = instance.show_seconds and "%H:%M:%S" or "%H:%M"
        else
            instance.format = instance.show_seconds and "%I:%M:%S %p" or "%I:%M %p"
        end
    end

    updateFormat()
    instance.time = os.date(instance.format)
    instance.timer = os.startTimer(instance.updt_rate)
    instance.dirty = true

    instance.updateSize = function(self)
        local len = #os.date(self.format)
        self.size = { w = len, h = 1 }
    end
    instance:updateSize()

    instance.draw = function(self)
        c.write(self.time, self.pos.x, self.pos.y, self.bg, self.txtcol)
    end

    instance.updateTime = function(self)
        self.time = os.date(self.format)
        if type(self.time) ~= "string" then
            self.time = os.date("%H:%M")
        end
        self.timer = os.startTimer(self.updt_rate)
        self.dirty = true
    end

    instance.setFormat = function(self, Show_seconds, Is_24h)
        expect(1, Show_seconds, "boolean", "nil")
        expect(2, Is_24h, "boolean", "nil")

        self.show_seconds = Show_seconds ~= false
        self.is_24h = Is_24h ~= false
        updateFormat()
        self.time = os.date(self.format)
        self:updateSize()
        self.dirty = true
        if self.parent then
            self.parent:onLayout()
        end
    end

    local temp_onEvent = instance.onEvent
    instance.onEvent = function(self, evt)
        if evt[1] == "timer" and evt[2] == self.timer then
            self:updateTime()
            return true
        end
        return temp_onEvent(self, evt)
    end

    return instance
end

---Creating new *object* of *class*
---@param root table
---@param array sting[]|nil
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param defaultValue string|nil
---@param maxSizeW number|nil
---@param orientation string|nil
---@return table object dropdown
function UI.New_Dropdown(root, array, bg, txtcol, defaultValue, maxSizeW, orientation)
    expect(1, root, "table")
    expect(2, array, "table", "nil")
    expect(3, bg, "number", "nil")
    expect(4, txtcol, "number", "nil")
    expect(5, defaultValue, "string", "nil")
    expect(6, maxSizeW, "number", "nil")
    expect(7, orientation, "string", "nil")

    local instance = New_Widget(root,bg,txtcol)
    instance.array = array or {}
    instance.item_index = 1
    if defaultValue then
        for i, v in pairs(instance.array) do
            if v == defaultValue then
                instance.item_index = i
                break
            end
        end
    end
    instance.orientation = orientation or "left"
    if type(maxSizeW) ~= "number" then maxSizeW = nil end
    instance.size.w = maxSizeW or c.findMaxLenStrOfArray(instance.array)+1
    instance.expanded = false

    instance.draw = function(self)
        if self.orientation == "left" then
            c.write(string_sub((self.array[self.item_index]), 1,self.size.w-1)..string_rep(" ", self.size.w-1-#self.array[self.item_index])..string_char(31), self.pos.x, self.pos.y, self.bg, self.txtcol)
            if self.expanded then
                for i, v in pairs(self.array) do
                    c.write(string_sub((v..string_rep(" ", self.size.w - #v)),1,self.size.w), self.pos.x, self.pos.y + i, self.bg, self.txtcol)
                end
                c.write(string_sub((self.array[self.item_index]), 1,self.size.w-1)..string_rep(" ", self.size.w-1-#self.array[self.item_index])..string_char(30), self.pos.x, self.pos.y, self.bg, self.txtcol)
                self.size.h = #self.array + 1
            else
                self.size.h = 1
            end
        elseif self.orientation == "right" then
            c.write(string_sub(self.array[self.item_index]..string_rep(" ", self.size.w-1-#self.array[self.item_index])..string_char(30),1,self.size.w), self.pos.x, self.pos.y, self.bg, self.txtcol)
            if self.expanded then
                for i, v in pairs(self.array) do
                    c.write(string_sub(string_rep(" ", self.size.w - #v)..v,1,self.size.w), self.pos.x, self.pos.y + i, self.bg, self.txtcol)
                end
                c.write(string_sub(self.array[self.item_index],1,self.size.w-1)..string_rep(" ", self.size.w-1-#self.array[self.item_index])..string_char(31), self.pos.x, self.pos.y, self.bg, self.txtcol)
                self.size.h = #self.array + 1
            else
                self.size.h = 1
            end
        else
            error("Bad argument init.dropdown(#6): " .. tostring(self.orientation))
        end
    end
    instance.onFocus = function(self,focused)
        if not focused and self.expanded then
            self.expanded = false
            self.parent:onLayout()
            self.dirty = true
        end
        return true
    end
    instance.pressed = function(self) end
    instance.onMouseDown = function(self,btn, x, y)
        if (y - self.pos.y) > 0 then self.item_index = math.min(math.max(y - self.pos.y, 1), #self.array) end
        self.expanded = not self.expanded
        if self.expanded == false then self.parent:onLayout() else self.dirty = true end
        self:pressed()
        return true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param arr number[]|nil
---@param bg color|number|nil
---@param txtcol color|number|nil
---@param defaultPosition number|nil
---@param txtcol2 color|number|nil
---@return table object slider
function UI.New_Slider(root, arr, bg, txtcol, defaultPosition, txtcol2)
    expect(1, root, "table")
    expect(2, arr, "table", "nil")
    expect(3, bg, "number", "nil")
    expect(4, txtcol, "number", "nil")
    expect(5, defaultPosition, "number", "nil")
    expect(6, txtcol2, "number", "nil")

    local instance = New_Widget(root,bg,txtcol)
    instance.arr = arr
    instance.slidePosition = defaultPosition or 1
    instance.txtcol2 = txtcol2 or instance.txtcol

    instance.draw = function(self)
        local N = #self.arr
        local W = self.size.w

        -- Calculate thumb position if N > 0
        if N > 0 then
            local i = self.slidePosition
            local offset = (N == 1) and 0 or math.floor((i - 1) / (N - 1) * (W - 1))
            local thumb_x = self.pos.x + offset
            -- Overlay thumb (use a different char, e.g., █ or slider thumb equivalent)
            c.write(" ", thumb_x, self.pos.y, self.txtcol, self.bg)
            c.write(string_rep(string_char(140), offset), self.pos.x, self.pos.y, self.bg, self.txtcol2)
            c.write(string_rep(string_char(140), self.size.w - offset - 1), thumb_x + 1, self.pos.y, self.bg, self.txtcol)
        else
            c.write(string_rep(string_char(140), W), self.pos.x, self.pos.y, self.bg, self.txtcol)
        end
    end
    instance.pressed = function(self) end
    instance.updatePos = function(self,x,y)
        local N = #self.arr

        if N > 0 and self.size.w > 1 then  -- Avoid div by zero
            local offset = x - self.pos.x
            local raw_index = math.floor((offset / (self.size.w - 1) * (N - 1)) + 0.5) + 1
            self.slidePosition = math.max(1, math.min(N, raw_index))
        end
        self.dirty = true
    end
    instance.onMouseDown = function(self,btn, x, y)
        self:updatePos(x,y)
        self:pressed(btn, x, y)
        return true
    end
    instance.onMouseDrag = function(self,btn, x, y)
        self:updatePos(x,y)
        self:pressed(btn, x, y)
        return true
    end
    instance.updateArr = function(self,array)
        self.arr = array
        self.dirty = true
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@return table object container
function UI.New_Container(root)
    local instance = New_Widget(root)
    instance.child = {}

    instance.layoutChild = function(self) end
    instance.onLayout = function(self)
        self:layoutChild()
        for _,child in pairs(self.child) do
            child:reSize()
            child:onLayout()
        end
    end
    instance.addChild = function(self,child)
        for _,v in pairs(self.child) do
            if v == child then
                return false
            end
        end
        table.insert(self.child,child)
        child.parent = self
        return true
    end
    instance.removeChild = function(self,child)
        for k,v in pairs(self.child) do
            if v == child then
                child.parent = nil
                table.remove(self.child,k)
                self:onLayout()
                return true
            end
        end
        return false
    end
    local temp_redraw = instance.redraw
    instance.redraw = function(self)
        temp_redraw(self)
        for _,child in pairs(self.child) do
            child:redraw()
        end
    end
    local temp_onEvent = instance.onEvent
    instance.onEvent = function(self,evt)
        local ret = temp_onEvent(self,evt)
        if self.modal and EVENTS.TOP[evt[1]] and (self.modal.root.keyboard:onEvent(evt) or self.modal:onEvent(evt)) then return true end
        if EVENTS.TOP[evt[1]] then
            for i=#self.child,1,-1 do
                if self.child[i]:check(evt[3],evt[4]) and self.child[i]:onEvent(evt) then
                    return true
                end
            end
        elseif not EVENTS.FOCUS[evt[1]] then
            for _,child in pairs(self.child) do
                if child:onEvent(evt) then
                    return true
                end
            end
        end
        return ret
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param string string
---@return table object MsgWin
function UI.New_MsgWin(root,string)
    expect(1, root, "table")
    expect(2, string, "string")

    local instance = UI.New_Container(root)
    instance.title = " Error "
    instance.msg = ""
    local label = UI.New_Label(root,instance.msg,instance.bg,instance.txtcol)
    label.reSize = function(self)
        self.pos = {x=self.parent.pos.x+1,y=self.parent.pos.y+1}
        self.size = {w=self.parent.size.w-2,h=self.parent.size.h-self.parent.pos.y+1}
    end
    instance:addChild(label)
    local btnOK
    if string == "INFO" then
        btnOK = UI.New_Button(root," OK ")
        btnOK.reSize = function(self)
            self.pos = {x=math.floor((self.parent.size.w-self.size.w)/2)+self.parent.pos.x,y=self.parent.size.h+self.parent.pos.y-1}
        end
        instance:addChild(btnOK)
    elseif string == "YES,NO" then
        instance.btnYES = UI.New_Button(root," YES ")
        instance.btnYES.reSize = function(self)
            self.pos = {x=math.floor((self.parent.size.w)/2)-self.size.w+self.parent.pos.x,y=self.parent.size.h+self.parent.pos.y-1}
        end
        instance:addChild(instance.btnYES)
        btnOK = UI.New_Button(root," NO ")
        btnOK.reSize = function(self)
            self.pos = {x=math.floor((self.parent.size.w)/2)+1+self.parent.pos.x,y=self.parent.size.h+self.parent.pos.y-1}
        end
        instance:addChild(btnOK)
    end

    btnOK.pressed = function(self)
        self.parent:removeWin()
    end

    instance.draw = function(self)
        for i = 1, self.size.h-2 do
            c.write(string_rep(" ",self.size.w-2)..string_char(149), self.pos.x+1, self.pos.y+i, self.bg, self.txtcol)
            c.write(string_char(149), self.pos.x, self.pos.y+i, self.txtcol, self.bg)
        end
        c.write(string_rep(string_char(140), self.size.w-2)..string_char(148), self.pos.x+1, self.pos.y,self.bg, self.txtcol)
        c.write(string_char(151), self.pos.x, self.pos.y, self.txtcol, self.bg)
        c.write(string_char(138)..string_rep(string_char(140), self.size.w-2)..string_char(133), self.pos.x, self.size.h+self.pos.y-1,self.bg, self.txtcol)
        c.write(self.title, math.floor((self.size.w - #self.title)/2) + self.pos.x, self.pos.y, self.bg, self.txtcol)
    end
    instance.callWin = function(self,title,msg)
        self.root.modal = self
        self.root.focus = self
        self.title = title
        self.child[1]:setText(msg)
        self.root:addChild(self)
        self:onLayout()
    end
    instance.removeWin = function(self)
        self.root.modal = nil
        self.root.focus = nil
        self.root:removeChild(self)
        self.root:onLayout()
    end
    local temp_onLayout = instance.onLayout
    instance.onLayout = function(self)
        self:reSize()
        self.dirty = true
        temp_onLayout(self)
    end
    instance.reSize = function(self)
        self.pos = {x=self.root.pos.x+3,y=self.root.pos.y+2}
        self.size = {w=self.root.size.w-self.pos.x-2,h=self.root.size.h-self.pos.y-2}
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@return table object DialWin
function UI.New_DialWin(root)
    expect(1, root, "table")

    local instance = UI.New_Container(root)
    instance.title = " Title "
    instance.msg = ""
    local label = UI.New_Label(root,instance.msg,instance.bg,instance.txtcol,"left")
    label.reSize = function(self)
        self.pos = {x=self.parent.pos.x+1,y=self.parent.pos.y+1}
        self.size.w = self.parent.size.w-2
    end
    instance:addChild(label)

    local textfield = UI.New_Textfield(root,instance.bg,instance.txtcol)
    textfield.reSize = function(self)
        self.pos = {x=label.pos.x,y=label.pos.y+1}
        self.size.w = self.parent.size.w-2
    end
    instance:addChild(textfield)

    instance.btnOK = UI.New_Button(root," OK ")
    instance.btnOK.reSize = function(self)
        self.pos = {x=math.floor((self.parent.size.w)/2-#self.text-1)+self.parent.pos.x,y=self.parent.size.h+self.parent.pos.y-1}
    end
    instance:addChild(instance.btnOK)

    local btnCANCEL = UI.New_Button(root," CANCEL ")
    btnCANCEL.reSize = function(self)
        self.pos = {x=math.floor(self.parent.size.w/2)+self.parent.pos.x,y=self.parent.size.h+self.parent.pos.y-1}
    end
    instance:addChild(btnCANCEL)

    btnCANCEL.pressed = function(self)
        self.parent:removeWin()
    end

    instance.draw = function(self)
        for i = 1, self.size.h-2 do
            c.write(string_rep(" ",self.size.w-2)..string_char(149), self.pos.x+1, self.pos.y+i, self.bg, self.txtcol)
            c.write(string_char(149), self.pos.x, self.pos.y+i, self.txtcol, self.bg)
        end
        c.write(string_rep(string_char(140), self.size.w-2)..string_char(148), self.pos.x+1, self.pos.y,self.bg, self.txtcol)
        c.write(string_char(151), self.pos.x, self.pos.y, self.txtcol, self.bg)
        c.write(string_char(138)..string_rep(string_char(140), self.size.w-2)..string_char(133), self.pos.x, self.size.h+self.pos.y-1,self.bg, self.txtcol)
        c.write(self.title, math.floor((self.size.w - #self.title)/2) + self.pos.x, self.pos.y, self.bg, self.txtcol)
    end
    instance.callWin = function(self,title,msg)
        self.root.modal = self
        self.root.focus = self.child[2]
        self.title = title
        self.child[1]:setText(msg)
        self.root:addChild(self)
        self:onLayout()
    end
    instance.removeWin = function(self)
        self.root.modal = nil
        self.root.focus = nil
        self.root:removeChild(self)
        self.root:onLayout()
    end
    instance.reSize = function(self)
        self.size = {w=24,h=4}
        self.pos = {x=math.floor((self.root.size.w-self.size.w)/2),y=math.floor((self.root.size.h-self.size.h)/2)}
    end
    local temp_onLayout = instance.onLayout
    instance.onLayout = function(self)
        self:reSize()
        self.dirty = true
        temp_onLayout(self)
    end
    return instance
end

function UI.New_Key_Button(root,text)
    local instance = UI.New_Button(root,text)

    instance.pressed = function(self)
        os.queueEvent("char", self.text)
        if self.parent.upper == 1 then
            for i,child in pairs (self.parent.child) do
                child:setText(EVENTS.KEYS[i])
            end
        self.parent.upper = 0
        self.parent.child[30].held = false
        self.parent.child[30].dirty = true
        end
    end
    instance.onEvent = function(self,evt)
        if evt[1] == "mouse_drag" then
            return self:onMouseDrag(evt[2],evt[3],evt[4])
        elseif evt[1] == "mouse_up" then
            return self:onMouseUp(evt[2],evt[3],evt[4])
        elseif evt[1] == "mouse_click" then
            if self.parent then self.parent.focus = self end
            return self:onMouseDown(evt[2],evt[3],evt[4])
        elseif evt[1] == "mouse_scroll" then
            return self:onMouseScroll(evt[2],evt[3],evt[4])
        elseif evt[1] == "char" then
            return self:onCharTyped(evt[2])
        elseif evt[1] == "key" then
            return self:onKeyDown(evt[2],evt[3])
        elseif evt[1] == "key_up" then
            return self:onKeyUp(evt[2])
        elseif evt[1] == "paste" then
            return self:onPaste(evt[2])
        end
        return false
    end
    return instance
end

function UI.New_Keyboard(root)
    local instance = UI.New_Container(root)
    instance.focus = nil
    -- Стани: 0=default, 1=shift, 2=caps, 3=smileys
    instance.upper = 0

    local layout_default = {
        "1","2","3","4","5","6","7","8","9","0", --10
        "q","w","e","r","t","y","u","i","o","p", --20
        "a","s","d","f","g","h","j","k","l", --29
        string_char(24)..string_char(95),"z","x","c","v","b","n","m", string_char(27).."-", --38
        " "..string_char(2).." ", ",", ".", "  SPACE",string_char(27), string_char(24), string_char(25), string_char(26), string_char(17)..string_char(172)
    }

    local layout_shift = {
        "1","2","3","4","5","6","7","8","9","0", --10 string_char(27)
        "Q","W","E","R","T","Y","U","I","O","P", --20
        "A","S","D","F","G","H","J","K","L", --29
        string_char(24)..string_char(95),"Z","X","C","V","B","N","M", string_char(27).."-", --38
        " "..string_char(2).." ", ",", ".", "  SPACE", string_char(27), string_char(24), string_char(25), string_char(26), string_char(17)..string_char(172)
    }

    local layout_smile = {
        -- Ряд 1 (індекси 1-10)
        "!", "\"", "#", ";", "%", ":", "?", "*", "(", ")",
        -- Ряд 2 (індекси 11-20)
        "~", "@", "T", "$", string_char(19), "^", "&", "=", "+", "-",
        -- Ряд 3 (індекси 21-29)
        "_", "`", "'", string_char(171), string_char(187), "{", "}", "[", "]",
        -- Ряд 4 (індекси 30-38)
        layout_default[30], -- 30: Shift (Спеціальна, залишаємо)
        string_char(177), string_char(191), "|", "/", "\\", "<", ">", -- 31-37 (z,x,c,v,b,n,m)
        layout_default[38], -- 38: Backspace (Спеціальна, залишаємо)
        -- Ряд 5 (індекси 39-45)
        "ABC",         -- 39: "Smile" button, тепер це "ABC"
        layout_default[40], -- 40: Comma (Спеціальна)
        layout_default[41], -- 41: Dot (Спеціальна)
        layout_default[42], -- 42: Space (Спеціальна)
        layout_default[43], -- 43: Left (Спеціальна)
        layout_default[44], -- 44: Up (Спеціальна)
        layout_default[45], -- 45: Down (Спеціальна)
        layout_default[46], -- 46: Right (Спеціальна)
        layout_default[47],  -- 47: Enter (Спеціальна)
    }

    local keyLayout = {
        -- Ряд 1: Цифри (y=1)
        { 1, 1, 1 }, { 2, 3, 1 }, { 3, 5, 1 }, { 4, 7, 1 }, { 5, 9, 1 }, { 6, 11, 1 }, { 7, 13, 1 }, { 8, 15, 1 }, { 9, 17, 1 }, { 10, 19, 1 },
        -- Ряд 2: QWERTY (y=2)
        { 11, 1, 2 }, { 12, 3, 2 }, { 13, 5, 2 }, { 14, 7, 2 }, { 15, 9, 2 }, { 16, 11, 2 }, { 17, 13, 2 }, { 18, 15, 2 }, { 19, 17, 2 }, { 20, 19, 2 },
        -- Ряд 3: ASDF (y=3)
        { 21, 2, 3 }, { 22, 4, 3 }, { 23, 6, 3 }, { 24, 8, 3 }, { 25, 10, 3 }, { 26, 12, 3 }, { 27, 14, 3 }, { 28, 16, 3 }, { 29, 18, 3 },
        -- Ряд 4: ZXCV (y=4)
        { 30, 1, 4, "shift" },
        { 31, 4, 4 }, { 32, 6, 4 }, { 33, 8, 4 }, { 34, 10, 4 }, { 35, 12, 4 }, { 36, 14, 4 }, { 37, 16, 4 },
        { 38, 18, 4, "backspace" },
        -- Ряд 5: Нижній (y=5)
        { 39, 1, 5, "smile" },
        { 40, 4, 5 }, -- comma
        { 41, 5, 5 }, -- dot
        { 42, 6, 5, "space" },
        { 43, 14, 5, "left" },
        { 44, 15, 5, "up"},
        { 45, 16, 5, "down"},
        { 46, 17, 5, "right" },
        { 47, 18, 5, "enter" },
    }

    local function setKeyboardLayout(keyboard, layoutTable, newUpperState)
        keyboard.upper = newUpperState
        for k, child in pairs(keyboard.child) do
            if layoutTable[k] then
                child:setText(layoutTable[k])
            end
        end
        if newUpperState == 2 then
            keyboard.child[30]:setText(string_char(23)..string_char(95))
        end
        if newUpperState == 3 then
            keyboard.child[30].held = false
        end
        if keyboard.child[30] then keyboard.child[30].dirty = true end
        if keyboard.child[39] then keyboard.child[39].dirty = true end
    end

    local specialActions = {
        backspace = function(self)
            os.queueEvent("key", keys.backspace)
        end,
        left = function(self)
            os.queueEvent("key", keys.left)
        end,
        space = function(self)
            os.queueEvent("char", " ")
        end,
        right = function(self)
            os.queueEvent("key", keys.right)
        end,
        enter = function(self)
            os.queueEvent("key", keys.enter)
        end,
        up = function(self)
            os.queueEvent("key", keys.up)
        end,
        down = function(self)
            os.queueEvent("key", keys.down)
        end,

        shift = function(self)
            local keyboard = self.parent
            if keyboard.upper == 0 then
                setKeyboardLayout(keyboard, layout_shift, 1) -- Shift
            elseif keyboard.upper == 1 then
                setKeyboardLayout(keyboard, layout_shift, 2) -- Caps
            elseif keyboard.upper == 2 then
                setKeyboardLayout(keyboard, layout_default, 0)
            elseif keyboard.upper == 3 then
                self.held = false
            end
        end,

        -- (ОНОВЛЕНО) Посилається на локальні layout_* таблиці
        smile = function(self)
            local keyboard = self.parent
            if keyboard.upper == 3 then
                setKeyboardLayout(keyboard, layout_default, 0)
            else
                setKeyboardLayout(keyboard, layout_smile, 3)
            end
        end
    }

    for _, keyDef in ipairs(keyLayout) do
        local keyIndex = keyDef[1]
        local relX = keyDef[2]
        local relY = keyDef[3]
        local actionName = keyDef[4]

        if layout_default[keyIndex] then
            local btn = UI.New_Key_Button(root, layout_default[keyIndex])

            btn.reSize = function(self)
                self.pos = { x = self.parent.pos.x + relX, y = self.parent.pos.y + relY }
            end

            if actionName and specialActions[actionName] then
                btn.pressed = specialActions[actionName]
            end

            if actionName == "shift" then
                btn.onMouseUp = function(self, btn, x, y)
                    if self:check(x, y) and self.held == true then self:pressed() end
                    if self.parent.upper == 0 then self.held = false end
                    self.dirty = true
                    return true
                end
            end

            instance:addChild(btn)
        end
    end

    instance.draw = function(self)
        for i = 1, self.size.h-2 do
            c.write(string_char(149), self.size.w+self.pos.x-1, self.pos.y+i,self.txtcol, self.bg)
            c.write(string_char(149)..string_rep(" ",self.size.w-2), self.pos.x, self.pos.y+i, self.bg, self.txtcol)
        end
        c.write(string_char(151)..string_rep(string_char(131), self.size.w-2), self.pos.x, self.pos.y,self.bg, self.txtcol)
        c.write(string_char(148), self.size.w+self.pos.x-1, self.pos.y, self.txtcol,self.bg)
        c.write(string_char(138)..string_rep(string_char(143), self.size.w-2)..string_char(133), self.pos.x, self.size.h+self.pos.y-1, self.txtcol, self.bg)
    end
    instance.reSize = function(self)
        self.size = {w=21,h=7}
        self.pos = {x=math.floor((self.root.size.w-self.size.w)/2)+1,y=self.root.size.h-self.size.h+1}
    end
    local temp_onLayout = instance.onLayout
    instance.onLayout = function (self)
        self:reSize()
        self.dirty = true
        temp_onLayout(self)
    end
    instance.onEvent = function(self,evt)
        if not self.parent then return false end
        if evt[3] and evt[4] and self:check(evt[3],evt[4]) then
            if EVENTS.TOP[evt[1]] then
                for i=#self.child,1,-1 do
                if self.child[i]:check(evt[3],evt[4]) and self.child[i]:onEvent(evt) then
                    return true
                end
            end
        elseif self.focus and EVENTS.FOCUS[evt[1]] and self.focus:onEvent(evt) then
            return true
        end
        return true
    end
    return false
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param bg color|number|nil
---@return table object box
function UI.New_Box(root,bg)
    expect(1, root, "table")
    expect(2, bg, "number", "nil")

    local instance = UI.New_Container(root)
    instance.bg = bg or instance.root.bg

    instance.draw = function(self)
        c.drawFilledBox(self.pos.x,self.pos.y,self.size.w+self.pos.x-1,self.size.h+self.pos.y-1,self.bg)
    end
    local temp_onLayout = instance.onLayout
    instance.onLayout = function(self)
        self:reSize()
        self.dirty = true
        temp_onLayout(self)
    end
    return instance
end

---Creating new *object* of *class*
---@param root table
---@param bg color|number|nil
---@return table object ScrollBox
function UI.New_ScrollBox(root,bg)
    local instance = UI.New_Container(root)
    instance.bg = bg
    instance.term = term.current()
    instance.win = window.create(instance.term, instance.pos.x, instance.pos.y, instance.size.w, instance.size.h, true)
    instance.scrollpos = 1
    instance.scrollmax = 1
    instance.len = 1
    instance.visibleChild = {}

    instance.draw = function(self)
        c.drawFilledBox(1, 1, self.pos.x+self.size.w-1, self.pos.y+self.size.h-1, self.bg)
        self.win.redraw()
    end
    instance.redraw = function(self)
        local OldCurPos = {term.getCursorPos()}
        term.redirect(self.win)
        term.setTextColor(self.term.getTextColor())
        term.setBackgroundColor(self.term.getBackgroundColor())
        term.setCursorBlink(self.term.getCursorBlink())
        if self.dirty then self:draw() self.dirty = false end
        for _,child in pairs(self.visibleChild) do
            local tempX, tempY = child.pos.x, child.pos.y
            child.pos.x = tempX - self.pos.x+1
            child.pos.y = tempY - self.pos.y+1
            child:redraw()
            child.pos.x = tempX
            child.pos.y = tempY
        end
        term.redirect(self.term)
        term.setCursorPos(OldCurPos[1], OldCurPos[2])
    end
    local temp_onLayout = instance.onLayout
    instance.onLayout = function(self)
        self.visibleChild = {}
        self:reSize()
        self.dirty = true
        temp_onLayout(self)
        for _,child in pairs(self.child) do
            self.scrollmax = math.max(math.max(self.scrollmax, child.pos.y + child.size.h-1+self.scrollpos)-self.size.h,1)
            if child.pos.y+child.size.h > self.pos.y and child.pos.y <= self.pos.y+self.size.h-1 then
                table.insert(self.visibleChild,child)
            end
        end
        self.len = self.scrollmax + self.size.h - 1
    end
    instance.onMouseScroll = function(self,dir,x,y)
        local MinMax = math.min(math.max(self.scrollpos+dir,1),self.scrollmax)
        if self.scrollpos ~= MinMax then
            self.scrollpos = MinMax
            self:updateDirty()
        end
        return true
    end
    instance.updateDirty = function(self)
        if self.scrollbar then
            self.scrollbar.dirty = true
        end
        self.dirty = true
        self:onLayout()
    end
    return instance
end

---Creating new *object* of *class* root - event handler, to use root:mainloop()
---@param bg color|number|nil
---@return table object root
function UI.New_Root(bg)
    expect(1, bg, "number", "nil")

    local instance = UI.New_Container()
    instance.focus = nil
    instance.running_program = true
    instance.modal = nil
    instance.size.w, instance.size.h = term.getSize()
    instance.bg = bg or colors.black
    instance.keyboard = UI.New_Keyboard(instance)

    instance.layoutChild = function(self)
        if #self.child >= 1 then
            self.child[1].pos = {x=1,y=1}
            self.child[1].size = {w=self.size.w,h=self.size.h}
        end
    end
    instance.show = function(self)
        c.termClear(self.bg)
        self:onLayout()
        self:redraw()
    end
    instance.tResize = function(self)
        c.termClear(self.bg)
        self.size.w, self.size.h = term.getSize()
        self:onLayout()
    end
    local tempOnEvent = instance.onEvent
    instance.onEvent = function(self,evt)
        local focus = self.focus
        local ret = tempOnEvent(self, evt)
        if self.focus and EVENTS.FOCUS[evt[1]] and self.focus:onEvent(evt) and self.keyboard:onEvent(evt) then
            ret = true
        end
        if evt[1] == "term_resize" then
            self:tResize()
        end
        if self.focus ~= focus then
            if focus then
                focus:onFocus(false)
            end
            if self.focus then
                self.focus:onFocus(true)
            end
        end
        self:redraw()
        return ret
    end
    instance.mainloop = function(self)
        self:show()
        while self.running_program do
            local evt = {os.pullEventRaw()}
            --dbg.print(textutils.serialize(evt))
            --print(textutils.serialize(self.size))
            if evt[1] == "terminate" then
                c.termClear(self.bg)
                self.running_program = false
            end
            self:onEvent(evt)
        end
        c.termClear()
    end
    return instance
end

return UI