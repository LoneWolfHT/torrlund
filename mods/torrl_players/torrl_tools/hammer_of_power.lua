local min, max = math.min, math.max

local flinging = {}

local RECHARGE_TIME = 1.5 * 2 -- steps are in half-seconds
minetest.register_tool("torrl_tools:hammer", {
	description = "Hammer Of Power \n" ..
		"Powers: Digging, Fling",
	inventory_image = "torrl_tools_hammer.png",
	wield_scale = {x = 1, z = 3, y = 1},
	tool_capabilities = {
		full_punch_interval = 0.1,
		max_drop_level = 1,
		groupcaps = {
			breakable = {times={[1] = 0.1}, uses = 0, maxlevel = 1},
			blastable = {times={[1] = 7.0}, uses = 0, maxlevel = 1},
		},
		damage_groups = {fleshy = 4},
	},
	on_secondary_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()

		if not flinging[name] then
			flinging[name] = true

			local ypos = user:get_pos().y
			local vel = user:get_look_dir():multiply(28)
			if ypos >= 50 then
				vel.y = max(min(vel.y, 10), -10)
			elseif ypos <= -9 then
				vel.y = max(min(vel.y, 24), -24)
			else
				vel.y = max(min(vel.y, 20), -20)
			end

			user:add_velocity(vel)
			user:set_physics_override({gravity = 0.4})

			torrl_effects.particle_effect(user, {
				type = torrl_effects.type.fire,
				amount = 30,
				duration = 0.7,
				particle_life_min = 1,
				particle_life_max = 5,
				pos = {x = 0, y = 0, z = 0}
			})

			minetest.sound_play({name = "torrl_tools_hammer_woosh"}, {
				object = user,
				gain = 1.1,
				max_hear_distance = 12
			}, true)

			itemstack:set_wear(65535)
			torrl_tools.update_wear.start_update(name, "torrl_tools:hammer", 65535/RECHARGE_TIME - 1, true, function()
				local player = minetest.get_player_by_name(name)

				if player then
					player:set_physics_override({gravity = 1})

					minetest.sound_play({name = "torrl_tools_charged"}, {
						to_player = name,
						gain = 0.8,
						max_hear_distance = 12
					}, true)
				end

				flinging[name] = nil
			end)

			return itemstack
		end
	end,
})

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	local name = player:get_player_name()

	if reason.type == "fall" and flinging[name] then
		return 0, true
	else
		return hp_change
	end
end, true)

-- torrl_tools.update_wear.start_update(pname, item, step, down, finish_callback, cancel_callback)
