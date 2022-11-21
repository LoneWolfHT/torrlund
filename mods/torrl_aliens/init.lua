torrl_aliens = {
	target_list = {},
	target_list_trecs = {},
}

local modpath = minetest.get_modpath(minetest.get_current_modname()) .. "/"
local schempath = modpath .. "schematics/"

dofile(modpath .. "aliens.lua")

minetest.register_node("torrl_aliens:ship_armor", {
	description = "Alien Ship Armor",
	drop = "",
	tiles = {"torrl_aliens_ship_armor.png"},
	light_source = 3,
	groups = {blastable = 1},
})

minetest.register_node("torrl_aliens:ship_core", {
	description = "Alien Ship Core",
	drop = "",
	tiles = {"torrl_aliens_ship_core.png"},
	paramtype = "light",
	light_source = 8,
	groups = {breakable = 1},
	explosive = 4,
	explosion_type = torrl_effects.type.alien,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		torrl_effects.explosion(pos, 4, torrl_effects.type.alien)
	end
})

minetest.register_node("torrl_aliens:ship_turret", {
	description = "Alien Ship Turret",
	drop = "",
	drawtype = "mesh",
	mesh = "torrl_aliens_ship_turret.obj",
	paramtype = "light",
	use_texture_alpha = "clip",
	light_source = 4,
	tiles = {"torrl_aliens_ship_turret.png"},
	groups = {blastable = 1},
	explosive = 1,
	explosion_type = torrl_effects.type.alien,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		torrl_effects.explosion(pos, 1, torrl_effects.type.alien)
	end
})

minetest.register_entity("torrl_aliens:laser_beam", {
	initial_properties = {
		physical = false,
		pointable = false,
		visual = "cube",
		visual_size = {x = 0.1, y = 0.1, z = 0.1},
		textures = string.split(("torrl_aliens_laser_beam.png"):rep(6, ","), ","),

		backface_culling = false,
		is_visible = true,
		glow = 14,
		static_save = false,
		shaded = false,
	},
	on_step = function(self, dtime)
		self.timer = (self.timer or 0) + dtime

		if self.timer >= 1 then
			self.object:remove()
		end
	end
})

local SHIP_SHOOT_INTERVAL = 30
local ALIEN_SHIP_INTERVAL = function()
	return math.random(60, math.max(60 * (5 - #minetest.get_connected_players()), 90))
end
local ALIEN_LASER_RADIUS = function()
	return math.ceil(#minetest.get_connected_players()/2)
end
local ALIEN_SHIP_YPOS = 66
local ALIEN_SHIP_PR = 40
local SHIP_SIZE = 20
local MAX_ALIEN_COUNT = 8

local current_ships = {}

local function delete_ships()
	if #current_ships > 0 then
		for i, pos in pairs(current_ships) do
			minetest.delete_area(pos:subtract(SHIP_SIZE), pos:add(SHIP_SIZE))
		end

		current_ships = {}
	end
end

torrl_core.register_on_game_restart(delete_ships)

local function shoot(ship)
	if #torrl_aliens.target_list >= 1 then
		local ppos = torrl_aliens.target_list[math.random(#torrl_aliens.target_list)]
		if type(ppos) ~= "table" then
			ppos = ppos:get_pos():offset(0, 1, 0)
		end

		minetest.after(1, function()
			local pos
			local i
			local nname

			repeat
				if i then table.remove(ship.turrets, i) end
				if #ship.turrets < 1 or #current_ships < 1 then return end -- ship is dead

				i = math.random(#ship.turrets)

				pos = ship.turrets[i]
				nname = minetest.get_node(pos).name
			until nname == "torrl_aliens:ship_turret" or nname == "ignore"

			if nname == "ignore" then
				minetest.emerge_area(pos, pos, function(_, _, remaining)
					if remaining <= 0 then
						shoot(ship)
					end
				end)

				return
			end

			local time = minetest.get_timeofday()
			if time <= 0.82 and time >= 0.18 then
				return delete_ships()
			end

			local dir = pos:direction(ppos)

			ppos = ppos:add(dir:multiply(5))
			pos = pos:copy():offset(0, -2, 0)

			for t=0, math.random(MAX_ALIEN_COUNT-1) do
				minetest.after(t, minetest.add_entity, pos, "torrl_aliens:alien_mini")
			end

			local ray = minetest.raycast(pos, ppos, true, false)

			for pointed_thing in ray do
				if pointed_thing and pointed_thing.intersection_point then
					local hitpos = pointed_thing.intersection_point
					dir = hitpos:direction(pos)
					local dist = hitpos:distance(pos)

					-- Laser wouldn't load if player had a small viewing range
					for _, obj in pairs({
						minetest.add_entity(hitpos:add(dir:multiply(dist * 0.75)), "torrl_aliens:laser_beam"),
						minetest.add_entity(hitpos:add(dir:multiply(dist * 0.25)), "torrl_aliens:laser_beam"),
					}) do
						obj:set_rotation(vector.dir_to_rotation(dir))
						obj:set_properties({visual_size = {x = 0.2, y = 0.2, z = math.round(dist/2)}})
					end

					minetest.sound_play({name = "torrl_aliens_laser"}, {
						pos = pointed_thing.intersection_point,
						gain = 1.3,
						max_hear_distance = 40,
					}, true)
					minetest.sound_play({name = "torrl_aliens_laser"}, {
						pos = pos,
						gain = 1,
						max_hear_distance = 20,
					}, true)

					if pointed_thing.above then
						torrl_effects.explosion(pointed_thing.above, ALIEN_LASER_RADIUS(), torrl_effects.type.alien)
					elseif pointed_thing.type == "object" and pointed_thing.ref then
						pointed_thing.ref:punch(
							minetest.add_entity(vector.new(0, 0, 0), "torrl_aliens:laser_beam"),
							nil, {damage_groups = {fleshy = 8}}, dir
						)
					end

					break
				end
			end

			minetest.after(SHIP_SHOOT_INTERVAL, shoot, ship)
		end)
	end
end

local timer = 0
local target_timer = 0
local creative = minetest.settings:get_bool("creative_mode", false)
local target_interval = 20
minetest.register_globalstep(function(dtime)
	target_timer = target_timer + dtime

	if target_timer >= 5 then
		target_timer = 0
		torrl_aliens.target_list = {}
		torrl_aliens.target_list_trecs = {}

		local players = minetest.get_connected_players()

		for _, p in pairs(players) do
			local meta = p:get_meta()

			if p:get_hp() > 0 and p:get_pos().y <= ALIEN_SHIP_YPOS - 10 and not p:get_armor_groups().immortal then
				table.insert(torrl_aliens.target_list, p)
			end

			if meta:get_string("torrl_player:trec_unit_status") == "placed" then
				local trecpos = minetest.string_to_pos(meta:get_string("torrl_player:trec_unit_pos"))

				table.insert(torrl_aliens.target_list, trecpos)
				table.insert(torrl_aliens.target_list_trecs, trecpos)
			end
		end
	end

	if creative then return end

	local time = minetest.get_timeofday()
	if time >= 0.82 or time <= 0.18 then
		torrl_voiceover.say_followed()

		timer = timer + dtime
		if timer >= target_interval then
			target_interval = ALIEN_SHIP_INTERVAL()
			timer = 0

			local players = minetest.get_connected_players()

			if #players >= 1 then
				local pos = players[math.random(#players)]:get_pos():offset(
					math.random(-ALIEN_SHIP_PR, ALIEN_SHIP_PR),
					0,
					math.random(-ALIEN_SHIP_PR, ALIEN_SHIP_PR)
				)

				pos.y = ALIEN_SHIP_YPOS

				torrl_voiceover.say_detected()

				local pos1, pos2 = pos:add(SHIP_SIZE), pos:subtract(SHIP_SIZE)
				minetest.emerge_area(pos:add(SHIP_SIZE), pos:subtract(SHIP_SIZE), function(_, _, remaining)
					if remaining <= 0 then
						torrl_effects.explosion(pos, SHIP_SIZE/1.5, torrl_effects.type.alien, function()
							minetest.after(4, function()
								minetest.place_schematic(pos, schempath .. "torrl_aliens_ship.mts", "random", nil, false, {
									place_center_x = true, place_center_y = true, place_center_z = true
								})

								local nodes = minetest.find_nodes_in_area(pos1, pos2, "torrl_aliens:ship_turret")

								table.insert(current_ships, pos)
								shoot({turrets = nodes})
							end)
						end)
					end
				end)
			end
		end
	end
end)
