-- fire/init.lua

-- Global namespace for functions
fire = {}

-- Load support for MT game translation.
local S = minetest.get_translator("fire")


--
-- Items
--

-- Flood flame function
local function flood_flame(pos, _, newnode)
	-- Play flame extinguish sound if liquid is not an 'igniter'
	if minetest.get_item_group(newnode.name, "igniter") == 0 then
		minetest.sound_play("fire_extinguish_flame",
			{pos = pos, max_hear_distance = 16, gain = 0.15}, true)
	end
	-- Remove the flame
	return false
end

-- Flame nodes
local fire_node = {
	drawtype = "firelike",
	tiles = {{
		name = "fire_basic_flame_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1
		}}
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 3, fire = 1},
	drop = "",
	on_flood = flood_flame
}

-- Basic flame node
local flame_fire_node = table.copy(fire_node)
flame_fire_node.description = S("Fire")
flame_fire_node.groups.not_in_creative_inventory = 1
flame_fire_node.on_timer = function(pos)
	minetest.remove_node(pos)

	return
end

if not minetest.settings:get_bool("creative_mode", false) then
	flame_fire_node.on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30, 60))
	end
end

minetest.register_node("fire_m:basic_flame", flame_fire_node)

-- Permanent flame node
local permanent_fire_node = table.copy(fire_node)
permanent_fire_node.description = S("Permanent Fire")

minetest.register_node("fire_m:permanent_flame", permanent_fire_node)

--
-- Sound
--

-- Enable if no setting present
local flame_sound = minetest.settings:get_bool("flame_sound", true)

if flame_sound then
	local handles = {}
	local timer = 0

	-- Parameters
	local radius = 8 -- Flame node search radius around player
	local cycle = 3 -- Cycle time for sound updates

	-- Update sound for player
	function fire.update_player_sound(player)
		local player_name = player:get_player_name()
		-- Search for flame nodes in radius around player
		local ppos = player:get_pos()
		local areamin = vector.subtract(ppos, radius)
		local areamax = vector.add(ppos, radius)
		local fpos, num = minetest.find_nodes_in_area(
			areamin,
			areamax,
			{"fire_m:basic_flame", "fire_m:permanent_flame"}
		)
		-- Total number of flames in radius
		local flames = (num["fire_m:basic_flame"] or 0) +
			(num["fire_m:permanent_flame"] or 0)
		-- Stop previous sound
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
		-- If flames
		if flames > 0 then
			-- Find centre of flame positions
			local fposmid = fpos[1]
			-- If more than 1 flame
			if #fpos > 1 then
				local fposmin = areamax
				local fposmax = areamin
				for i = 1, #fpos do
					local fposi = fpos[i]
					if fposi.x > fposmax.x then
						fposmax.x = fposi.x
					end
					if fposi.y > fposmax.y then
						fposmax.y = fposi.y
					end
					if fposi.z > fposmax.z then
						fposmax.z = fposi.z
					end
					if fposi.x < fposmin.x then
						fposmin.x = fposi.x
					end
					if fposi.y < fposmin.y then
						fposmin.y = fposi.y
					end
					if fposi.z < fposmin.z then
						fposmin.z = fposi.z
					end
				end
				fposmid = vector.divide(vector.add(fposmin, fposmax), 2)
			end
			-- Play sound
			local handle = minetest.sound_play("fire_fire", {
				pos = fposmid,
				to_player = player_name,
				gain = math.min(0.06 * (1 + flames * 0.125), 0.18),
				max_hear_distance = 32,
				loop = true -- In case of lag
			})
			-- Store sound handle for this player
			if handle then
				handles[player_name] = handle
			end
		end
	end

	-- Cycle for updating players sounds
	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer < cycle then
			return
		end

		timer = 0
		local players = minetest.get_connected_players()
		for n = 1, #players do
			fire.update_player_sound(players[n])
		end
	end)

	-- Stop sound and clear handle on player leave
	minetest.register_on_leaveplayer(function(player)
		local player_name = player:get_player_name()
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
	end)
end
