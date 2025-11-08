local expect = require("cc.expect")
local _interface = {}

local function New_Widget(bg,txtcol)
    local widget = {}
    widget.pos = {x=1,y=1}
    widget.size = {w=1,h=1}
    widget.bg = bg or colors.black
    widget.txtcol = txtcol or colors.white
    widget.dirty = true
    widget.parent = nil

    widget.check = function(self,x,y)
        return (x >= self.pos.x and x < self.size.w + self.pos.x and
                y >= self.pos.y and y < self.size.h + self.pos.y)
    end
    widget.onKeyDown = function(self,key,held) return true end
    widget.onKeyUp = function(self,key) return true end
    widget.onCharTyped = function(self,chr) return true end
    widget.onPaste = function(self,text) return true end
    widget.onMouseDown = function(self,btn,x,y) return true end
    widget.onMouseUp = function(self,btn,x,y) return true end
    widget.onMouseScroll = function(self,dir,x,y) return true end
    widget.onMouseDrag = function(self,btn,x,y) return true end
    widget.onFocus = function(self,focused) return true end
    widget.draw = function(self) end
    widget.redraw = function(self)
        if self.dirty then self:draw() self.dirty = false end
    end
    widget.reSize = function(self) end
    widget.onLayout = function(self) self.dirty = true end
    widget.onEvent = function(self,evt)
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
    return widget
end

function _interface.New_Button(text,bg,txtcol)
    expect(1, text, "string", "nil")
    expect(2, bg, "number", "nil")
    expect(3, txtcol, "number", "nil")
    expect(4, align, "string", "nil")
    local Button = New_Widget(bg,txtcol)
    Button.text = text or "button"
    Button.held = false
    Button.size.w = #Button.text

    Button.draw = function(self)
        c.write(self.text,self.pos.x,self.pos.y,self.txtcol)
    end
    Button.pressed = function(self) end
    Button.onMouseDown = function(self,btn,x,y)
        self.held = true
        self.dirty = true
        return true
    end
    Button.onMouseUp = function(self,btn,x,y)
        if self:check(x,y) and self.held == true then self:pressed() end
        self.held = false
        self.dirty = true
        return true
    end
    return Button
end

return _interface