local players = game:GetService("Players")

local const = require(script.Constants)
local interface = require(script.Interface)
local util = require(script.Utility)

type ValidConfig = number | string | boolean | (...any) -> any

local configify = {}
configify.__index = configify

function configify.new()
	local self = setmetatable({}, configify)

	self._configs = {}

	self:_Init()

	return self
end

function configify:_Init()
	if const.IS_CLIENT then
		if const.WHITELIST_ENABLED and not util.IsWhitelisted(players.LocalPlayer) then
			return
		end

		self.local_plr = players.LocalPlayer
		self._interface = interface.new()

		if script:FindFirstChild("ConfigifyCommunication") then
			self:_ListenForComm()
		else
			local check
			check = script.ChildAdded:Connect(function(child)
				if not (child.Name == "ConfigifyCommunication") then
					return
				end

				check:Disconnect()
				check = nil

				self:_ListenForComm()
			end)
		end
	elseif const.IS_SERVER then
		self.comm = Instance.new("RemoteEvent")
		self.comm.Name = "ConfigifyCommunication"
		self.comm.Parent = script

		self.comm.OnServerEvent:Connect(function(player, ...)
			self:_HandleConfigChangeRequest(player, ...)
		end)

		self:_UpdateClients(players:GetPlayers())

		players.PlayerAdded:Connect(function(player)
			self:_UpdateClients{player}
		end)
	end

	_G.Configify = self
	_G.Cfg = self
end

function configify:Set(name: string, tip: string, initial: ValidConfig, min, max)
	local val_t = typeof(initial)

	self._configs[name] = {
		value = initial,
		tab = util.GetTabName(3),
		tip = tip,
		min = min,
		max = max
	}

	if const.IS_CLIENT then
		self._interface:CreateConfig(name)
	elseif const.IS_SERVER then
		self:_UpdateClients(players:GetPlayers())
	end
	
	return function()
		if val_t == "string" then
			return tostring(self._configs[name].value)
		elseif val_t == "number" then
			return tonumber(self._configs[name].value)
		elseif val_t == "boolean" then
			return self._configs[name].value
		elseif val_t == "function" then
			return self._configs[name].value
		end
	end
end

if const.IS_SERVER then
	-- sync all clients with the same configs
	function configify:_UpdateClients(players_list: {Player})
		for _, player in players_list do
			if const.WHITELIST_ENABLED and not util.IsWhitelisted(player) then
				continue
			end

			self.comm:FireClient(player, util.SerializeConfigs(self._configs))
		end
	end
	
	-- listen to clients requesting config changes
	function configify:_HandleConfigChangeRequest(player)
		if const.WHITELIST_ENABLED and not util.IsWhitelisted(player) then
			return
		end

	end
elseif const.IS_CLIENT then
	function configify:_ListenForComm()
		self.comm = script:FindFirstChild("ConfigifyCommunication")
		self.comm.OnClientEvent:Connect(function(serialized_configs)
			local configs = util.DeserializeConfigs(serialized_configs)

			print(configs)
		end)
	end
end

return _G.Configify or configify.new()
