torrl_player = {
	won = false,
}

local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

dofile(modpath.."comp_unit.lua")

torrl_core.register_on_game_restart(function()
	minetest.log("action", "Game Restarting...")
	minetest.set_timeofday(0.22)
	torrl_player.won = false
end)

local function reset_inv(player)
	local inv = player:get_inventory()
	local pos = player:get_pos()
	local meta = player:get_meta()

	for _, i in pairs(inv:get_list("main")) do
		if i:get_definition().droppable then
			minetest.after(0.1, minetest.add_item, pos, i)
		end
	end

	player:get_inventory():set_list("main", {})

	inv:add_item("main", "torrl_tools:hammer")

	if meta:get_string("torrl_player:trec_unit_status") ~= "placed" then
		inv:add_item("main", "torrl_nodes:trec_unit")

		meta:set_string("torrl_player:trec_unit_status", "inv")
	end
end

minetest.register_on_newplayer(reset_inv)

local function place_trec_unit(pos, oname)
	if minetest.get_node(pos).name == "ignore" then
		minetest.after(1, place_trec_unit, pos, oname)
	else
		local player = minetest.get_player_by_name(oname)

		if player then
			minetest.swap_node(pos, {name = "torrl_nodes:trec_unit"})
			minetest.get_meta(pos):set_string("owner", oname)
			player:set_pos(pos:offset(0, 1, 0))
		end
	end
end

local gameover_huds = {}
minetest.register_on_respawnplayer(function(player)
	local meta = player:get_meta()
	local status = meta:get_string("torrl_player:trec_unit_status")

	if torrl_player.won or status == "dead" or status == "inv" then
		local name = player:get_player_name()

		meta:set_int("torrl_player:dead", 1)
		player:set_properties({visible = false})
		player:set_nametag_attributes({
			text = "",
			color = "#00000000",
			bgcolor = "#00000000",
		})
		player:set_armor_groups({immortal = 1})

		local privs = minetest.get_player_privs(name)

		privs.interact = nil
		privs.fly = true
		privs.fast = true
		privs.noclip = true
		minetest.set_player_privs(name, privs)

		if not torrl_player.won then
			gameover_huds[name] = player:hud_add({
				position = {x = 0.5, y = 0.5},
				scale = {x = 100, y = 100},
				text = "Game Over. It will restart when everyone is dead",
				number = 0xFF0000,
				alignment = {x = 0, y = -1},
				offset = {x = 0, y = -12},
				size = {x = 2},
			})
		else
			gameover_huds[name] = player:hud_add({
				position = {x = 0.5, y = 0.5},
				scale = {x = 100, y = 100},
				text = "Game Won! It will restart when all players exit the ship",
				number = 0x00FF00,
				alignment = {x = 0, y = -1},
				offset = {x = 0, y = -12},
				size = {x = 2},
			})
		end

		player:get_inventory():set_list("main", {})
	else
		reset_inv(player)
	end

	if status == "placed" then
		player:set_pos(minetest.string_to_pos(meta:get_string("torrl_player:trec_unit_pos")):offset(0, 1, 0))
		return true
	end

	if torrl_player.won then
		player:set_pos(vector.new(0, 10001, 0))
	else
		player:set_pos(vector.new(0, 9, 0))
	end

	return true
end)

local function resurrect(player, name, meta)
	meta:set_int("torrl_player:dead", 0)

	player:set_hp(20)
	player:set_properties({visible = true})
	player:set_nametag_attributes({
		text = name,
		color = "#ffffff",
		bgcolor = false,
	})
	player:set_armor_groups({alien = 100})

	local privs = minetest.get_player_privs(name)

	privs.interact = true
	privs.fly = nil
	privs.fast = nil
	privs.noclip = nil
	minetest.set_player_privs(name, privs)

	if gameover_huds[name] then
		player:hud_remove(gameover_huds[name])
	end

	reset_inv(player)
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer >= 5 then
		timer = 0
		local players = minetest.get_connected_players()

		if #players <= 0 then return end

		local found = false

		for _, player in pairs(players) do
			local hp = player:get_hp()

			if hp > 0 and hp < 20 then
				player:set_hp(hp + math.random(1, 2)) -- ## Health Regen ##
			end

			if player:get_meta():get_int("torrl_player:dead") ~= 1 then
				found = true
				break
			end
		end

		if not found then
			if torrl_player.won then
				minetest.log("action", "Game Won, Restarting...")
				minetest.request_shutdown("Resetting Map...", true)
				return
			end

			torrl_core.game_restart()

			for _, player in pairs(players) do
				resurrect(player, player:get_player_name(), player:get_meta())
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local status = meta:get_string("torrl_player:trec_unit_status")
	local name = player:get_player_name()

	torrl_voiceover.say_greeting(name)

	reset_inv(player)

	if meta:get_int("torrl_player:dead") > 0 then
		resurrect(player, name, meta)
	end

	if status == "placed" then
		local pos = minetest.string_to_pos(meta:get_string("torrl_player:trec_unit_pos"))

		place_trec_unit(pos, player:get_player_name())

		trec_unit.add_hud(player, pos)

		return
	end

	player:set_pos(vector.new(0, 9, 0))
	player:set_look_horizontal(math.pi) -- Face the mountain across the spawn ravine
end)

minetest.after(0, torrl_core.game_restart)
