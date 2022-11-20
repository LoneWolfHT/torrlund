local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"

dofile(modpath.."comp_unit.lua")

local function newplayer(player)
	local inv = player:get_inventory()

	inv:add_item("main", "torrl_tools:hammer")
	inv:add_item("main", "torrl_nodes:trec_unit")

	player:get_meta():set_string("torrl_player:trec_unit_status", "inv")
end

minetest.register_on_newplayer(newplayer)

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

	if status == "dead" or status == "inv" then
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

		gameover_huds[name] = player:hud_add({
			position = {x = 0.5, y = 0.5},
			scale = {x = 100, y = 100},
			text = "Game Over. A restart will happen when all players are dead",
			number = 0xFF0000,
			alignment = {x = 0, y = -1},
			offset = {x = 0, y = -12},
			size = {x = 2},
		})

		player:get_inventory():set_list("main", {})
	end

	if status == "placed" or status == "dead" then
		player:set_pos(minetest.string_to_pos(meta:get_string("torrl_player:trec_unit_pos")):offset(0, 1, 0))
		return true
	end

	player:set_pos(vector.new(0, 9, 0))

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

	newplayer(player)
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer >= 5 then
		timer = 0
		local players = minetest.get_connected_players()
		local found = false

		for _, player in pairs(players) do
			if player:get_meta():get_int("torrl_player:dead") ~= 1 then
				found = true
				break
			end
		end

		if not found then
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

	player:set_armor_groups({fleshy = 100})

	if meta:get_int("torrl_player:dead") > 0 then
		resurrect(player, name, meta)
	end

	if status == "placed" then
		local pos = minetest.string_to_pos(meta:get_string("torrl_player:trec_unit_pos"))

		place_trec_unit(pos, player:get_player_name())

		trec_unit.add_hud(player, pos)

		return
	end

	minetest.sound_play({name = "welcome_message" .. (math.random(15) == 1 and "_rare" or "")}, {
		to_player = name,
		gain = 1.2,
	}, true)

	minetest.chat_send_player(name, minetest.colorize(
		"cyan",
		"<C.O.M.P Unit> Greetings, your ship is badly damaged. "..
		"Use your T.R.E.C Unit to synthesize the materials needed to repair it"
	))

	player:set_pos(vector.new(0, 9, 0))
	player:set_look_horizontal(math.pi) -- Face the mountain across the spawn ravine
end)

torrl_core.register_on_game_restart(function()
	minetest.set_timeofday(0.2)
end)

minetest.after(0, torrl_core.game_restart)
