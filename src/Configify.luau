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

	_G.Configify = self
	_G.Cfg = self

	return self
end

-- TODO: Finish Interface.lua + cfg:Set()

function configify:Set(config_name)
	self.interface:AddConfig(config_name)
end

-- function configify:Set(name: string, tip: string, initial: ValidConfig, min, max)
-- 	local val_t = typeof(initial)

-- 	self._configs[name] = {
-- 		value = initial,
-- 		tab = util.GetTabName(3),
-- 		tip = tip,
-- 		min = min,
-- 		max = max
-- 	}

-- 	if const.IS_CLIENT then
-- 		self._interface:CreateConfig(name)
-- 	elseif const.IS_SERVER then
-- 		self:_UpdateClients(players:GetPlayers())
-- 	end
	
-- 	return function()
-- 		if val_t == "string" then
-- 			return tostring(self._configs[name].value)
-- 		elseif val_t == "number" then
-- 			return tonumber(self._configs[name].value)
-- 		elseif val_t == "boolean" then
-- 			return self._configs[name].value
-- 		elseif val_t == "function" then
-- 			return self._configs[name].value
-- 		end
-- 	end
-- end

if const.IS_CLIENT then
	-- check whitelist, create interface, setup client/server architecture
	function configify:_Init()
		if not util.IsWhitelisted(players.LocalPlayer) then
			return
		end

		self.interface = interface.new()

		task.spawn(function()
			local comm = script:FindFirstChild("CfgComm") or script:WaitForChild("CfgComm", 60)
			if not comm then
				return -- no comm remote in 60s, not using configify on the server
			end

			self:_ListenForComm(comm)	
		end)
	end

	-- listen to server config changes (all clients synced)
	function configify:_ListenForComm(comm: RemoteEvent)
		self.comm = comm
		self.comm.OnClientEvent:Connect(function(serialized_configs)
			local configs = util.DeserializeConfigs(serialized_configs)
			print(configs)
		end)
	end
elseif const.IS_SERVER then
	-- create client/server bridge
	-- handle init/update for current/future clients
	function configify:_Init()
		self.comm = Instance.new("RemoteEvent")
		self.comm.Name = "CfgComm"
		self.comm.Parent = script

		self.comm.OnServerEvent:Connect(function(player, ...)
			self:_HandleConfigChangeRequest(player, ...)
		end)

		self:_UpdateClients(players:GetPlayers())

		players.PlayerAdded:Connect(function(player)
			self:_UpdateClients{player}
		end)
	end

	-- listen to clients requesting config changes
	function configify:_HandleConfigChangeRequest(player, ...)
		if not util.IsWhitelisted(players.LocalPlayer) then
			return
		end

		print(`Client: {player.Name} has requested a config change: {...}`)
	end

	-- sync all clients with the same configs
	function configify:_UpdateClients(players_list: {Player})
		for _, player in players_list do
			if not util.IsWhitelisted(players.LocalPlayer) then
				return
			end

			self.comm:FireClient(player, util.SerializeConfigs(self._configs))
		end
	end
end

return _G.Configify or configify.new()
