local const = require(script.Parent.Parent.Constants)

local function hover(toggle, ui_obj)
    for _, v in ui_obj:GetDescendants() do
        if v:IsA("UIStroke") then
        v.Color = toggle and const.UI.COLOR_E or const.UI.COLOR_D
        end
    end
end

local button = {}
button.__index = button

function button.new(ui_obj, callback, ...)
    local self = setmetatable({}, button)
   
    self.ui = ui_obj
    self.callback = callback
    self.args = {...}

    self:_BtnInit()

    return self
end

function button:_BtnInit()
    self.ui.MouseEnter:Connect(function()
        hover(true, self.ui)
    end)

    self.ui.MouseLeave:Connect(function()
        hover(false, self.ui)
    end)

    if self.callback then
        self.ui.MouseButton1Click:Connect(function()
            self.callback(table.unpack(self.args))
        end)
    end
end

return button
