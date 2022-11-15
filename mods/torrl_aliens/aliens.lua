creatura.register_utility("torrl_aliens:seek", function(selfa)
	local wander_time = 5
	local pursue_time = 60

	selfa:set_utility(function(self)
		if not self:get_action() then
			if #torrl_aliens.target_list <= 0 then
				creatura.action_idle(self, wander_time)
				return
			end

			local pos = torrl_aliens.target_list[math.random(#torrl_aliens.target_list)]
			if type(pos) ~= "table" then
				pos = pos:get_pos()
			end

			creatura.action_move(self, pos, 60, "creatura:neighbors")
		end
	end)
end)

creatura.register_mob("torrl_aliens:alien_mini", {
	max_health = 10,
	damage = 2,
	speed = 4,
	tracking_range = 16,
	max_fall = 8,
	turn_rate = 8,
	hitbox = {
		width = 0.5,
		height = 1,
	},
	animations = {
		anim = {range = {x = 1, y = 10}, speed = 30, frame_blend = 0.3, loop = true}
	},
	-- drops = {
	-- 	{name = (itemstring), min = 1, max = 3, chance = 1},
	-- },
	utility_stack = {
		-- {
		-- 	utility = "torrl_aliens:attack",
		-- 	get_score = function(self)
		-- 		return 0
		-- 	end,
		-- },
		{
			utility = "torrl_aliens:seek",
			get_score = function(self)
				return 2
			end,
		},
		-- {
		-- 	utility = "torrl_aliens:dig",
		-- 	get_score = function(self)
		-- 		return 1
		-- 	end,
		-- },
	},
})

creatura.register_spawn_egg("torrl_aliens:alien_mini", "63c74d" ,"193c3e")
