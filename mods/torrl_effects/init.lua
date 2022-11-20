torrl_effects = {
	type = {
		fire = "torrl_effects_fire.png",
		alien = "torrl_effects_alien.png",
	},
}

-- type, amount, duration, particle_life[_min, _max], pos
function torrl_effects.particle_effect(obj, settings)
	if settings.collison_removal == nil then
		settings.collison_removal = true
	end

	minetest.add_particlespawner({
		amount = settings.amount,
		time = settings.duration,
		minpos = settings.pos or {x=0, y=0, z=0},
		maxpos = settings.pos or {x=0, y=0, z=0},
		minvel = {x= (settings.spread_vel or 1), y= (settings.spread_vel or 1), z= (settings.spread_vel or 1)},
		maxvel = {x=-(settings.spread_vel or 1), y=-(settings.spread_vel or 1), z=-(settings.spread_vel or 1)},
		minacc = {x=0, y=-9.8, z=0},
		maxacc = {x=0, y=-9.8, z=0},
		minexptime = settings.particle_life_min or settings.particle_life,
		maxexptime = settings.particle_life_max or settings.particle_life,
		minsize = 1.9 * (settings.size_mult or 1),
		maxsize = 2.1 * (settings.size_mult or 1),
		collisiondetection = false,
		collision_removal = settings.collison_removal,
		object_collision = true,
		attached = obj,
		vertical = false,
		texture = settings.type,
		glow = 10,
	})
end

local function explosion(vm, s_data, s_pos1, s_pos2, s_pos, s_radius, s_type, callback)
	minetest.handle_async(function(data, pos, pos1, pos2, radius, etype)
		local blast_queue = {}
		local on_blast_queue = {}

		local area = VoxelArea:new({MinEdge = pos1, MaxEdge = pos2})
		local pr = PseudoRandom(os.time())

		local length = vector.length
		local add = vector.add
		local round = vector.round
		local get_name_from_content_id = minetest.get_name_from_content_id
		local get_content_id = minetest.get_content_id

		-- Derived from mtg tnt mod https://github.com/minetest/minetest_game/tree/master/mods/tnt
		for z = -radius, radius do
		for y = -radius, radius do
		local vi = area:index(pos.x + (-radius), pos.y + y, pos.z + z)
		for x = -radius, radius do
			local p = {x=x, y=y, z=z}
			local r = length(p)
			if data[vi] and (radius * radius) / (r * r) >= (pr:next(80, 125) / 100) then
				local nodename = get_name_from_content_id(data[vi])
				local def = minetest.registered_nodes[nodename]

				if def.explosive then
					blast_queue[add(pos, p)] = {
						type = def.explosion_type,
						intensity = def.explosive,
						nodename = nodename,
					}
				end

				if def.on_torrl_blast then
					on_blast_queue[round(add(pos, p))] = {nodename = nodename, type = etype}
				end

				if not def.groups or not def.groups.blast_ignore then
					if def.blast_replace then
						data[vi] = get_content_id(def.blast_replace)
					else
						data[vi] = minetest.CONTENT_AIR
					end
				end
			end
			vi = vi + 1
		end
		end
		end

		return data, blast_queue, on_blast_queue
	end, function(a_data, blast_queue, on_blast_queue)
		vm:set_data(a_data)
		vm:write_to_map(true)

		for pos, info in pairs(on_blast_queue) do
			minetest.registered_nodes[info.nodename].on_torrl_blast(pos, info.type)
		end

		if next(blast_queue) then
			local max
			local min
			local _

			for pos in pairs(blast_queue) do
				if max then
					_, max = vector.sort(max, pos)
					min = vector.sort(min, pos)
				else
					max = pos
					min = pos
				end
			end

			local b_pos1, b_pos2 = vm:read_from_map(
				min,
				max
			)
			local b_data = vm:get_data()

			for pos, info in pairs(blast_queue) do
				explosion(
					vm, b_data, b_pos1, b_pos2,
					pos, info.intensity, info.type,
					minetest.registered_nodes[info.nodename].explosion_callback
				)
			end
		end

		torrl_effects.particle_effect(nil, {
			type = s_type,
			amount = 12 * s_radius,
			duration = 0.1,
			collision_removal = false,
			spread_vel = 20,
			size_mult = 2,
			pos = s_pos,
			particle_life_min = 2,
			particle_life_max = 3,
		})

		for _, obj in pairs(minetest.get_objects_inside_radius(s_pos, s_radius/2)) do
			local dir = vector.direction(s_pos, obj:get_pos())

			obj:punch(obj, nil, {damage_groups = {fleshy = s_radius/2, alien = s_radius/2}}, dir)
			obj:add_velocity(dir:multiply(s_radius))
		end

		if callback then
			callback()
		end
	end, s_data, s_pos, s_pos1, s_pos2, s_radius, s_type)
end

function torrl_effects.explosion(s_pos, s_radius, ...)
	s_pos = vector.round(s_pos)

	local vm = VoxelManip()
	local s_pos1, s_pos2 = vm:read_from_map(
		s_pos:subtract(s_radius),
		s_pos:add(s_radius)
	)
	local s_data = vm:get_data()

	explosion(vm, s_data, s_pos1, s_pos2, s_pos, s_radius, ...)
end
