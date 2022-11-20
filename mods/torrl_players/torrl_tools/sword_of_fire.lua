local levitating = {}

minetest.register_on_dieplayer(function(player)
	levitating[player:get_player_name()] = nil
end)

local RECHARGE_TIME = 1.5 * 10 -- 10 second cooldown
local SMASH_RADIUS = 4
local SMASH_DAMAGE = 15
local SMASH_KNOCKBACK = 15
local function power_func(itemstack, user, pointed_thing)
	local name = user:get_player_name()

	if pointed_thing and pointed_thing.type == "object" then
		if not levitating[name] then
			itemstack:set_wear(0)
		end

		return itemstack
	end

	if not levitating[name] then
		local vel = vector.new(0, 16, 0)

		user:add_velocity(vel)
		user:set_physics_override({gravity = 0.5})

		torrl_effects.particle_effect(user, {
			type = torrl_effects.type.fire,
			amount = 30,
			duration = 0.7,
			particle_life_min = 1,
			particle_life_max = 5,
			pos = {x = 0, y = 0, z = 0}
		})

		minetest.sound_play({name = "torrl_tools_woosh"}, {
			object = user,
			gain = 1.1,
			pitch = 1.3,
			max_hear_distance = 12
		}, true)

		levitating[name] = minetest.after(2.5, function()
			local player = minetest.get_player_by_name(name)

			if player then
				player:set_physics_override({gravity = 1})

				minetest.sound_play({name = "torrl_tools_error"}, {
					to_player = name,
					gain = 1,
				}, true)
			end

			levitating[name] = "done"
		end)

		itemstack:set_wear(65535)
		torrl_tools.update_wear.start_update(name, "torrl_tools:sword", (65535/RECHARGE_TIME) - 1, true, function()
			local player = minetest.get_player_by_name(name)

			if player then
				minetest.sound_play({name = "torrl_tools_charged"}, {
					to_player = name,
					gain = 0.8,
				}, true)
			end

			levitating[name] = nil
		end)

		return itemstack
	elseif type(levitating[name]) ~= "string" then
		local pos = user:get_pos()
		local target = pos:add(user:get_look_dir():multiply(20))
		local pointed = minetest.raycast(user:get_pos(), target, false):next()

		if pointed then
			user:set_pos(pointed.above)

			minetest.sound_play({name = "torrl_tools_woosh"}, {
				object = user,
				gain = 1.1,
				pitch = 2,
				max_hear_distance = 12
			}, true)

			torrl_effects.particle_effect(nil, {
				type = torrl_effects.type.fire,
				amount = 24,
				duration = 0.1,
				collision_removal = false,
				spread_vel = 17,
				pos = pointed.above,
				particle_life_min = 2,
				particle_life_max = 3,
			})

			for _, obj in pairs(minetest.get_objects_inside_radius(pointed.above, SMASH_RADIUS)) do
				if not obj:is_player() then
					local luaent = obj:get_luaentity()

					if luaent.alien then
						torrl_aliens.temp_braindead(luaent, 3)

						local dir = pointed.above:direction(obj:get_pos())

						obj:punch(obj, nil, {damage_groups = {alien = SMASH_DAMAGE}}, dir)
						obj:add_velocity(dir:multiply(SMASH_KNOCKBACK))
					end
				end
			end

			user:set_physics_override({gravity = 1})

			levitating[name]:cancel()
			levitating[name] = "done"
		else
			minetest.sound_play({name = "torrl_tools_error"}, {
				to_player = name,
				gain = 1,
				pitch = 2,
			}, true)
		end
	end
end

minetest.register_tool("torrl_tools:sword", {
	description = "Sword of Fire\n" ..
		"Powers: Melting, Area Damage",
	inventory_image = "torrl_tools_sword.png",
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level = 1,
		punch_attack_uses = 0,
		groupcaps = {
			breakable = {times={[1] = 0.5}, uses = 0, maxlevel = 1},
			blastable = {times={[1] = 5.0}, uses = 0, maxlevel = 1},
			meltable  = {times={[1] = 1.0}, uses = 0, maxlevel = 1},
		},
		damage_groups = {alien = 7},
	},
	on_place = power_func,
	on_secondary_use = power_func,
})

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	local name = player:get_player_name()

	if reason.type == "fall" and type(levitating[name]) == "table" then
		return 0, true
	else
		return hp_change
	end
end, true)
