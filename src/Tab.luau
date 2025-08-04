local players = game:GetService("Players")

local player = players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")

local assets = script.Parent.Parent.Assets

local button = require(script.Parent.Button)

local tab = {}
tab.__index = tab
setmetatable(tab, {__index = button})

function tab.new(tab_name, env_type, callback)
    local tab_container = assets.TabContainer:Clone()
    local tab_ui = assets.Tab:Clone()

    local self = setmetatable(button.new(tab_ui, callback), tab)

    self.tab_name = tab_name
    self.container = tab_container
    self.ui = tab_ui
    self.env = env_type

    self:_Init()

    return self
end

function tab:_Init()
    local main_ui = player_gui:WaitForChild("Configify")
	local config_container = main_ui.Container.ConfigContainer
    local tab_container = main_ui.Container.TabContainer

	self.container.Name = self.tab_name
	self.container.Parent = config_container
    self.ui.Name = self.tab_name
	self.ui.Parent = tab_container[self.env]
end

function tab:SetVisible(visible)
    self.ui.Visible = visible
end

return tab
