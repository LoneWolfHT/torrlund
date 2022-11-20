-- creatura.action_idle, but my physics stay applied
function torrl_aliens.temp_braindead(self, time, anim)
	local timer = time
	self.temp_braindead = true
	local function func(self_)
		self_:animate(anim or "stand")
		timer = timer - self_.dtime
		if timer <= 0 then
			self.temp_braindead = nil
			return true
		end
	end
	self:set_action(func)
end

creatura.register_utility("torrl_aliens:idle", function(selfa)
	selfa.target_player = nil
	selfa.target_pos = nil

	selfa:set_utility(function(self)
		local pos = self.object:get_pos()
		if pos.y < 9 then
			pos.y = 9
			self.target_pos = pos
		end

		if not self:get_action() then
			creatura.action_idle(self, 2)
		end
	end)
end)

creatura.register_utility("torrl_aliens:seek_trec", function(selfa)
	local blind_pursue_time = 6

	if math.random(8) == 1 then
		selfa.obsessed = 5
		selfa.object:set_texture_mod("^[colorize:#0f0:35")
	end

	selfa.target_player = nil

	selfa:set_utility(function(self)
		if not self:get_action() and #torrl_aliens.target_list_trecs > 0 then
			local pos = torrl_aliens.target_list_trecs[math.random(#torrl_aliens.target_list_trecs)]:copy()

			self.target_pos = pos
			if not self.temp_braindead then
				creatura.action_move(self, pos, blind_pursue_time)
			end
		end
	end)
end)

creatura.register_utility("torrl_aliens:attack_player", function(selfa)
	selfa:set_utility(function(self)
		if self.target_player and not self.temp_brainded then
			local pos = self.target_player:get_pos()
			local spos = self:get_center_pos()

			self.target_pos = pos

			if os.clock() - (self.last_hit or 0) > 3 and pos:distance(spos) <= 1.5 then
				local leap_vel = pos:direction(spos):multiply(2)
				leap_vel.y = 1

				self:punch_target(self.target_player)
				self.object:add_velocity(leap_vel)

				torrl_aliens.temp_braindead(self, 1)
				self.last_hit = os.clock()
			elseif not self.temp_braindead then
				creatura.action_move(self, pos, 1)
			end
		end
	end)
end)

creatura.register_utility("torrl_aliens:seek_player", function(selfa)
	selfa:set_utility(function(self)
		if self.target_player and self.target_pos then
			if self.target_pos:distance(self.object:get_pos()) <= 3 then

				self.target_player = nil
				self.target_pos = nil
			elseif not self.temp_brainded then
				creatura.action_move(self, self.target_pos, 10)
			end
		end
	end)
end)

minetest.register_node("torrl_aliens:fresh_stepping_stool", {
	description = "Alien stepping stool",
	tiles = {"torrl_alien_fresh_stepping_stool.png"},
	groups = {breakable = 1, bouncy = 60, fall_damage_add_percent = -50},
})

local player_chase_range = 6
local player_chase_range_max = 40
creatura.register_mob("torrl_aliens:alien_mini", {
	max_health = 40,
	damage = 2,
	armor_groups = {alien = 100},
	speed = 5,
	tracking_range = 6, -- not used AFAIK because I'm a noob
	turn_rate = 8,
	alien = true,
	max_fall = 80,
	despawn_after = 60 * 3,
	mesh = "torrl_aliens_alien_mini.b3d",
	textures = {"torrl_aliens_alien_mini.png"},
	visual_size = {x = 0.8, y = 0.8},
	hitbox = {
		width = 0.4,
		height = 0.8,
	},
	static_save = false,
	animations = {
		anim = {range = {x = 1, y = 10}, speed = 30, frame_blend = 0.3, loop = true}
	},
	-- drops = {
	-- 	{name = (itemstring), min = 1, max = 3, chance = 1},
	-- },
	death_func = function(self)
		torrl_effects.particle_effect(nil, {
			type = torrl_effects.type.alien,
			amount = 12,
			duration = 0.6,
			collision_removal = false,
			spread_vel = 4,
			size_mult = 1,
			pos = self.object:get_pos(),
			particle_life_min = 1,
			particle_life_max = 2,
		})

		self.object:remove()
	end,
	on_punch = creatura.basic_punch_func,
	step_func = function(self, dtime, moveresult)
		self.look_timer = (self.look_timer or math.random(-1, 1)) + dtime

		if self.target_pos and self.look_timer >= 2 then
			self.look_timer = 0

			local pos = self.object:get_pos()

			if pos:distance(self.target_pos) <= 1 then
				minetest.dig_node(self.target_pos)
				self.target_pos = nil
				return
			end

			local zx = self.target_pos:copy()
			zx.y = pos.y

			if pos:distance(zx) <= 0.5 then
				if pos.y - self.target_pos.y < 0 then
					self.object:set_pos(pos:round())
					self.object:add_velocity({x = 0, y = 6, z = 0})
					torrl_aliens.temp_braindead(self, 2)

					local above = pos:offset(0, 1, 0)
					if minetest.get_node(above).name ~= "air" then
						minetest.dig_node(above)
					elseif minetest.get_node(pos).name == "air" then
						minetest.set_node(pos, {name = "torrl_aliens:fresh_stepping_stool"})
					end
				elseif pos.y - self.target_pos.y > 0 then
					local offset = pos:offset(0, -1, 0)

					if minetest.get_node(offset).name ~= "air" then
						minetest.dig_node(pos:offset(0, -1, 0))
						torrl_aliens.temp_braindead(self, 1)
					end
				end
			end

			local target = self.target_pos:copy()

			if moveresult and moveresult.collisions then
				for _, collision in pairs(moveresult.collisions) do
					if collision.type == "node" and (collision.node_pos.y >= pos.y or collision.old_velocity.y >= 0) then
						collision = collision.node_pos

						minetest.add_particle({
							pos = collision,
							expirationtime = 2,
							size = 5,
							collisiondetection = false,
							collision_removal = false,
							object_collision = false,
							texture = "torrl_nodes_trec_unit_interactable.png",
							glow = 13,
						})

						if collision.y == pos.y and math.abs(pos.y - target.y) > 1 then
							local offset = collision:offset(0, (pos.y - collision.y > 0 and 0 or 1), 0)

							if minetest.registered_nodes[minetest.get_node(offset).name].walkable then
								collision = offset

								if offset == 1 then
									self.object:add_velocity({x = 0, y = 3, z = 0})
									torrl_aliens.temp_braindead(self, 1)
								end
							end
						end

						minetest.dig_node(collision)

						torrl_aliens.temp_braindead(self, 1)
					end
				end
			end
		end
	end,
	utility_stack = {
		{
			utility = "torrl_aliens:idle",
			get_score = function(self) return 0.1, {self} end
		},
		{
			utility = "torrl_aliens:seek_trec",
			get_score = function(self)
				if #torrl_aliens.target_list_trecs <= 0 then
					return 0
				else
					return self.obsessed or 1, {self}
				end
			end,
		},
		{
			utility = "torrl_aliens:attack_player",
			get_score = function(self)
				-- prioritize trec chasing if close to one
				if not self.target_player and self.target_pos and self.object:get_pos():distance(self.target_pos) <= 5 then
					return 0
				end

				local players = minetest.get_connected_players()

				if #players <= 0 then
					return 0
				else
					local pos = self.object:get_pos()
					local closest_dist = player_chase_range_max
					local closest_p
					local sight = false

					for _, p in pairs(players) do
						local ppos = p:get_pos()
						local dist = pos:distance(ppos)

						if dist < closest_dist then
							closest_dist = dist
							closest_p = p

							if minetest.line_of_sight(pos, ppos:offset(0, 1, 0)) then
								sight = true
							else
								sight = false
							end
						end
					end

					if closest_p then
						if closest_dist <= player_chase_range then
							self.target_player = closest_p
							return (sight and 2 or 1), {self}
						else
							self.target_player = closest_p
							return 1, {self}
						end
					end
				end

				return 0
			end,
		},
		{
			utility = "torrl_aliens:seek_player",
			get_score = function(self)
				if self.target_player and self.target_pos then
					if self.object:get_pos():distance(self.target_player:get_pos()) > player_chase_range_max then
						self.target_player = nil
						self.target_pos = nil

						return 0
					end

					return 1.5, {self}
				end

				return 0
			end
		},
	},
})

creatura.register_spawn_egg("torrl_aliens:alien_mini", "63c74d" ,"193c3e")
