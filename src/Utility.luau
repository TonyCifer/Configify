local const = require(script.Parent.Constants)

local cfg_util = {}

function cfg_util.SerializeConfigs()
    
end

function cfg_util.DeserializeConfigs()
    
end

function cfg_util.GetTabName(depth)
    local num_attempts = 10

	local module = nil
	local path = nil

	for i = 1, num_attempts do
		local succ, err = pcall(function()
			path = string.split(debug.info(depth + 2, "s"), ".") -- +2 because of added scope from loop and pcall
			module = game[path[1]]

			for j = 2, #path do
				module = module[path[j]]
			end
		end)

		if succ then
			break
		else
			warn(err)
		end

		task.wait()
	end

	return module.Name
end

function cfg_util.IsWhitelisted(player: Player)
    local group_id = const.WHITELIST.GROUP_ID
    local group_min_rank = const.WHITELIST.GROUP_MIN_RANK
    local user_ids = const.WHITELIST.USERS

	if not const.WHITELIST_ENABLED then
		return true
	end

    if table.find(user_ids, player.UserId) then
        return true
    elseif group_id and group_id ~= "" then
		if not group_min_rank then
			warn(`[Configify]: GroupID is provided but no MinRank is provided.`)
			return false
		end

        if player:GetRankInGroup(group_id) >= group_min_rank then
            return true
        end
    end

    return false
end

return cfg_util
