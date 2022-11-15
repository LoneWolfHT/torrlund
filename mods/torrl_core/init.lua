torrl_core = {}

--
--- PLAYERS
--

do
	local get_player_by_name = minetest.get_player_by_name
	function torrl_core.PlayerObj(player)
		local type = type(player)

		if type == "string" then
			return get_player_by_name(player)
		elseif type == "userdata" and player:is_player() then
			return player
		end
	end

	function torrl_core.PlayerName(player)
		local type = type(player)

		if type == "string" then
			return player
		elseif type == "userdata" and player:is_player() then
			return player:get_player_name()
		end
	end
end

--
--- CALLBACKS
--

torrl_core.registered_on_game_restart = {}

-- Return true to cancel further callbacks
function torrl_core.register_on_game_restart(func)
	table.insert(torrl_core.registered_on_game_restart, func)
end

function torrl_core.game_restart(...)
	for _, func in ipairs(torrl_core.registered_on_game_restart) do
		if func(...) then
			break
		end
	end
end
