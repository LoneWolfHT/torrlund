local huds = {}

trec_unit = {
	add_hud = function(player, pos)
		local name = player:get_player_name()

		if not huds[name] then
			huds[name] = player:hud_add({
				name = "T.R.E.C Unit",
				hud_elem_type = "waypoint",
				precision = 1,
				number = 0x55FF55,
				world_pos = pos,
			})
		else
			player:hud_change(huds[name], "world_pos", pos)
		end
	end,
	remove_hud = function(player)
		local name = player:get_player_name()

		if huds[name] then
			player:hud_remove(huds[name])
			huds[name] = nil
		end
	end
}

local particles = {}

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer >= 0.7 then
		timer = 0

		for _, player in pairs(minetest.get_connected_players()) do
			local def = player:get_wielded_item():get_definition()

			if def and def.groups and def.groups.compressable then
				local meta = player:get_meta()
				local name = player:get_player_name()

				if meta:get_string("torrl_player:trec_unit_status") == "placed" and not particles[name] then
					local pos = minetest.string_to_pos(meta:get_string("torrl_player:trec_unit_pos"))

					particles[name] = true

					minetest.after(1.4, function() particles[name] = nil end)

					minetest.add_particle({
						pos = pos:offset(0, 0.9, 0),
						expirationtime = 2,
						size = 5,
						collisiondetection = false,
						collision_removal = false,
						object_collision = false,
						texture = "torrl_nodes_trec_unit_interactable.png",
						playername = name,
						glow = 13,
					})
				end
			end
		end
	end
end)

return function(compressables)
	minetest.register_node("torrl_nodes:trec_unit", {
		description = "T.R.E.C Unit",
		tiles = {
			"torrl_nodes_trec_unit_side.png", "torrl_nodes_trec_unit_side.png",
			"torrl_nodes_trec_unit_side.png",
			"torrl_nodes_trec_unit_side.png",
			"torrl_nodes_trec_unit_front.png",
		},
		paramtype2 = "facedir",
		drop = "",
		groups = {breakable = 1, blast_ignore = 1},
		light_source = minetest.LIGHT_MAX,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if itemstack and clicker and clicker:is_player() then
				local iname = itemstack:get_name()

				for from, to in pairs(compressables) do
					if iname == from then
						itemstack:set_name(to)

						minetest.after(0, function()
							clicker:get_inventory():add_item("main", itemstack)
						end)

						return ""
					end
				end
			end
		end,
		on_torrl_blast = function(pos, type)
			if type == torrl_effects.type.alien then
				local owner = minetest.get_meta(pos):get_string("owner")

				if owner then
					owner = minetest.get_player_by_name(owner)

					if owner then
						owner:get_meta():set_string("torrl_player:trec_unit_status", "dead")
						trec_unit.remove_hud(owner)
					end
				end

				minetest.remove_node(pos)
				torrl_effects.explosion(pos, 10, torrl_effects.type.fire)
			end
		end,
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing and pointed_thing.above and
			placer and placer:is_player() then
				local pos = pointed_thing.above

				if minetest.get_node(pos:offset(0, 1, 0)).name == "air" and
				minetest.get_node(pos:offset(0, 2, 0)).name == "air"
				then
					local meta = placer:get_meta()

					if meta:get_string("torrl_player:trec_unit_status") ~= "inv" then
						minetest.chat_send_player(placer:get_player_name(), "You can only have 1 trec unit at a time")
						return
					end

					minetest.item_place_node(itemstack, placer, pointed_thing)
					itemstack:set_count(itemstack:get_count() - 1)
					local nmeta = minetest.get_meta(pos)

					nmeta:set_string("owner", placer:get_player_name())
					meta:set_string("torrl_player:trec_unit_status", "placed")
					meta:set_string("torrl_player:trec_unit_pos", minetest.pos_to_string(pos))

					trec_unit.add_hud(placer, pos)

					return itemstack
				else
					minetest.chat_send_player(placer:get_player_name(), "You need 2 nodes of space above your T.R.E.C unit")
				end
			end
		end,
		can_dig = function(pos, player)
			if player and player:is_player() then
				local meta = minetest.get_meta(pos):get_string("owner")

				if meta == player:get_player_name() then
					return true
				end

				return false
			end

			return true
		end,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			local owner = minetest.get_player_by_name(oldmetadata.fields.owner)

			if digger and digger:is_player() then
				owner:get_meta():set_string("torrl_player:trec_unit_status", "inv")
				owner:get_inventory():add_item("main", "torrl_nodes:trec_unit")

				trec_unit.remove_hud(owner)
			else
				if owner then
					owner:get_meta():set_string("torrl_player:trec_unit_status", "dead")
					trec_unit.remove_hud(owner)
				end

				torrl_effects.explosion(pos, 10, torrl_effects.type.fire)
			end
		end
	})

	local old_is_protected = minetest.is_protected
	function minetest.is_protected(pos, ...)
		if minetest.get_node(pos:offset(0, -1, 0)).name == "torrl_nodes:trec_unit" or
		minetest.get_node(pos:offset(0, -2, 0)).name == "torrl_nodes:trec_unit"
		then
			return true
		end

		return old_is_protected(pos, ...)
	end
end
