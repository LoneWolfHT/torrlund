local min, max = math.min, math.max

local flinging = {}
local clicked = {}

minetest.register_on_dieplayer(function(player)
	local name = player:get_player_name()

	if flinging[name] then
		player:set_physics_override({gravity = 1})
		flinging[name] = nil
	end
end)

local RECHARGE_TIME = 1.5 * 2 -- 2 second cooldown
minetest.register_tool("torrl_tools:hammer", {
	description = "Hammer Of Power \n" ..
		"Powers: Digging, Fling",
	inventory_image = "torrl_tools_hammer.png",
	wield_scale = {x = 1, z = 3, y = 1},
	tool_capabilities = {
		full_punch_interval = 1,
		max_drop_level = 1,
		punch_attack_uses = 0,
		groupcaps = {
			breakable = {times={[1] = 0.2}, uses = 0, maxlevel = 1},
			blastable = {times={[1] = 7.0}, uses = 0, maxlevel = 1},
		},
		damage_groups = {alien = 4},
	},
	after_use = function(_, user)
		if user and user:is_player() then
			local name = user:get_player_name()

			if not clicked[name] then
				torrl_voiceover.say_abilities(name)
			end
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local meta = user:get_meta()
		local name = user:get_player_name()

		clicked[name] = true

		if meta:get_string("torrl_player:trec_unit_status") ~= "placed" then
			minetest.sound_play({name = "torrl_tools_error"}, {
				to_player = name,
				gain = 1,
			}, true)

			torrl_voiceover.say_abilities_trec(name)

			return
		end

		if pointed_thing and pointed_thing.type == "object" then
			if not flinging[name] then
				itemstack:set_wear(0)
			end

			return itemstack
		end

		if not flinging[name] then
			flinging[name] = true

			local ypos = user:get_pos().y
			local vel = user:get_look_dir():multiply(28)
			if ypos >= 50 then
				vel.y = max(min(vel.y, 12), -12)
			elseif ypos <= -9 then
				vel.y = max(min(vel.y, 28), -28)
			else
				vel.y = max(min(vel.y, 24), -24)
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

			minetest.sound_play({name = "torrl_tools_woosh"}, {
				object = user,
				gain = 1.1,
				max_hear_distance = 12
			}, true)

			itemstack:set_wear(65535)
			torrl_tools.update_wear.start_update(name, "torrl_tools:hammer", 65535/RECHARGE_TIME - 1, true, function()
				local player = minetest.get_player_by_name(name)

				if player then
					player:set_physics_override({gravity = 1})

					minetest.after(0.2, torrl_voiceover.say_tools, name)

					minetest.sound_play({name = "torrl_tools_charged"}, {
						to_player = name,
						gain = 0.8,
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

	if reason.type == "fall" then
		if flinging[name] then
			return 0, true
		elseif player:get_wielded_item():get_name() == "torrl_tools:hammer" then
			torrl_voiceover.say_hammer(name)
		end
	end

	return hp_change
end, true)
