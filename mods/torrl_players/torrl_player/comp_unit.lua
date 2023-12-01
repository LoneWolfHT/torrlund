local companions = {}

function torrl_player.get_companion(pname)
	return companions[pname]
end

local function spawn_companion(player)
	if not player or not player:is_player() then
		minetest.log("error", "[spawn_companion]: Given invalid player")
		return
	end

	local obj = minetest.add_entity(
		player:get_pos():offset(0, 2, 0):subtract(player:get_look_dir():multiply(-1)),
		"torrl_player:comp_unit"
	)

	obj:get_luaentity().owner = player:get_player_name()
	obj:get_luaentity().follow = player

	companions[player:get_player_name()] = obj:get_luaentity()

	return obj
end

local tools = {
	["torrl_tools:hammer"] = "torrl_tools:sword",
	["torrl_tools:sword"]  = "torrl_tools:hammer",
}

minetest.register_entity("torrl_player:comp_unit", {
	initial_properties = {
		is_visible = true,
		physical = false,
		collide_with_objects = false,
		pointable = true,

		collisionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25 },
		selectionbox = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25, rotate = true },

		visual = "mesh",
		visual_size = {x = 0.5, y = 0.5, z = 0.5},
		mesh = "torrl_player_comp_unit.obj",
		textures = {"torrl_player_comp_unit.png"},
		use_texture_alpha = true,
		backface_culling = true,
		glow = 5,

		automatic_rotate = 0,
		automatic_face_movement_dir = -90.0,
		automatic_face_movement_max_rotation_per_sec = 720,

		infotext = "C.O.M.P Unit",
		static_save = false,
	},
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
	end,
	on_deactivate = function(self, removal)
		if self.owner then
			spawn_companion(minetest.get_player_by_name(self.owner))
		end
	end,
	on_step = function(self, dtime, moveresult)
		if not self.owner then return end

		if not self.follow or not self.follow:is_player() then
			self.follow = minetest.get_player_by_name(self.owner)
		end

		if not self.follow or not self.follow:is_player() then
			self.object:remove()
			return
		end

		local target_pos = self.follow:get_pos():offset(0, 1.5, 0)
		local distance = self.object:get_pos():distance(target_pos)
		if distance > 3 and not self.started then
			self.object:set_velocity(self.object:get_pos():direction(target_pos):multiply(math.min(distance, 30)))
			self.started = true
			self.stopped = false
		elseif not self.stopped then
			self.started = false
			self.stopped = true
			self.object:set_velocity(vector.new())
		end
		self.object:set_rotation(vector.dir_to_rotation(self.object:get_pos():direction(target_pos)))
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
		if self.follow and self.follow == puncher then
			if self.owner and time_from_last_punch > 1 then
				self.object:add_velocity(vector.multiply(dir, 20))
				torrl_voiceover.skip(self.owner)
			end

			self.object:set_hp(self.object:get_hp())
			return true
		end
	end,
	on_death = function(self, killer)
		minetest.log("error", "Companion Died: "..dump(self.owner))
		-- torrl_effects.explosion(self.object:get_pos(), 24, torrl_effects.type.fire)
	end,
	on_rightclick = function(self, clicker)
		if clicker:is_player() and clicker:get_player_name() == self.owner then
			local item = clicker:get_wielded_item()
			local itemname = item:get_name()

			if tools[itemname] and item:get_wear() == 0 then
				clicker:set_wielded_item(tools[itemname])
			end
		end
	end,
	-- on_attach_child = function(self, child),
	-- on_detach_child = function(self, child),
	-- on_detach = function(self, parent),

	hp_set = false,
})

minetest.register_on_joinplayer(function(player)
	spawn_companion(player)
end)

minetest.register_on_leaveplayer(function(player)
	companions[player:get_player_name()] = nil
end)