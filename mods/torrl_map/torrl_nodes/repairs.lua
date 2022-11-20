minetest.register_craftitem("torrl_nodes:repair_tape", {
	description = "Repair Tape",
	inventory_image = "torrl_nodes_repair_tape.png",
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing and pointed_thing.type == "node" then
			local rep = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name].heal_replace

			if rep then
				minetest.swap_node(pointed_thing.under, {name = rep})

				itemstack:set_count(itemstack:get_count()-1)

				return itemstack
			end
		end
	end
})
