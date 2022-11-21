local timer = 0

local function spawn_meteors()
	local connected = minetest.get_connected_players()

	if #connected >= 1 then
		local pos = connected[math.random(#connected)]:get_pos():offset(math.random(-30, 30), 0, math.random(-30, 30))
		local offset = math.max(100, pos.y+50)
		pos.y = offset

		minetest.emerge_area(pos:offset(20, 6, 20), pos:offset(-20, -offset, -20), function(_, _, remaining)
			if remaining <= 0 then
				minetest.add_entity(pos, "torrl_meteors:meteor")
			end
		end)
	end
end

if not minetest.settings:get_bool("creative_mode", false) then
	local target_time = 10
	minetest.register_globalstep(function(dtime)
		local time = minetest.get_timeofday()

		if time >= 0.82 or time <= 0.18 then
			timer = timer + (dtime * 2)
		else
			timer = timer + dtime
		end

		if timer >= target_time then
			timer = 0

			target_time = 60 * math.random(2, 5)

			spawn_meteors()
		end
	end)
end

minetest.register_node("torrl_meteors:meteorite", {
	description = "Meteorite",
	tiles = {"torrl_meteors_meteorite.png"},
	light_source = 5,
	droppable = true,
	groups = {meltable = 1, blastable = 1, falling_node = 1, compressable = 1},
	after_dig_node = function(_, _, _, digger)
		if digger and digger:is_player() then
			torrl_voiceover.say_meteorite(digger:get_player_name())
		end
	end
})

local fall_speed = 40
minetest.register_entity("torrl_meteors:meteor", {
	initial_properties = {
		is_visible = true,
		physical = true,
		collide_with_objects = true,
		collisionbox = { -1, -1, -1, 1, 1, 1 },
		selectionbox = { -1, -1, -1, 1, 1, 1, rotate = false },
		pointable = true,
		visual = "cube",
		visual_size = {x = 2, y = 2, z = 2},
		textures = string.split(("torrl_meteors_meteor.png"):rep(6, ","), ","),
		makes_footstep_sound = false,
		automatic_rotate = 6,
		automatic_face_movement_dir = 0.0,
		backface_culling = true,
		glow = minetest.LIGHT_MAX,
		nametag = "[  !  ]",
		nametag_color = "#FF0000",
		static_save = false,
		shaded = true,
		show_on_minimap = true,
	},
	on_activate = function(self, staticdata, dtime_s)
		torrl_effects.particle_effect(self.object, {
			type = torrl_effects.type.fire,
			amount = 50,
			duration = 0,
			collision_removal = false,
			spread_vel = 5,
			pos = {x = 0, y = -2, z = 0},
			particle_life_min = 6,
			particle_life_max = 8,
			size_mult = 3,
		})

		self.falling_sound = minetest.sound_play({name = "torrl_meteors_meteor_falling"}, {
			object = self.object,
			gain = 1.2,
			max_hear_distance = 200,
			loop = true,
		})

		self.object:set_velocity(vector.new(math.random(-20, 20), -fall_speed, math.random(-20, 20)))
	end,
	on_step = function(self, dtime, moveresult)
		self.timer = (self.timer or 0) + dtime

		if self.timer >= 5 then
			self.timer = 0

			self.object:set_velocity(vector.new(0, -fall_speed, 0))

			return
		end

		if moveresult.collides then
			local pos = moveresult.node_pos or self.object:get_pos()

			minetest.sound_stop(self.falling_sound)

			torrl_effects.explosion(pos, 5, torrl_effects.type.fire, function()
				minetest.set_node(pos, {name = "torrl_meteors:meteorite"})
				minetest.sound_play({name = "torrl_meteors_meteor_explode"}, {
					pos = pos,
					gain = 3.0,
					max_hear_distance = 128,
				}, true)
			end)
			self.object:remove()
		end
	end,
})
