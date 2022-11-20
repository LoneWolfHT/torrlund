torrl_nodes = {
	blast_ignore = {}
}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/repairs.lua")

--
--- Processed Blocks, T.R.E.C Unit
--

local function register_compressable(name, max, def)
	minetest.register_node(name, {
		drawtype = def.drawtype,
		description = def.description,
		tiles = {def.texture},
		use_texture_alpha = def.use_texture_alpha,
		groups = def.groups,
		paramtype = def.paramtype,
		sunlight_propogates = def.sunlight_propogates,
		blast_replace = name.."_2",
		on_dig = function(pos, node, digger)
			if digger and digger:is_player() then
				minetest.node_dig(pos, node, digger)
			else
				minetest.swap_node(pos, {name = name.."2"})
			end
		end
	})

	name = name .. "_" -- this will show up in the on_dig code above

	for i = 2, max do
		local rep = name..(i+1)
		local heal = name..(i-1)

		if i == 2 then
			heal = name:sub(1, -2)
		end

		if i == max then rep = nil end

		def.groups.not_in_creative_inventory = 1
		def.groups.cracked = 1

		minetest.register_node(name..i, {
			drawtype = def.drawtype,
			description = def.description,
			tiles = {def.texture.."^[crack:1:1:"..i},
			use_texture_alpha = def.use_texture_alpha,
			paramtype = def.paramtype,
			sunlight_propogates = def.sunlight_propogates,
			groups = def.groups,
			blast_replace = rep,
			heal_replace = heal,
			drop = rep and name:sub(1, -2) or "",
			on_dig = rep and function(pos, node, digger)
				if digger and digger:is_player() then
					minetest.node_dig(pos, node, digger)
				elseif rep then
					minetest.swap_node(pos, {name = rep})
				end
			end
		})
	end
end

register_compressable("torrl_nodes:dirt_compressed", 3, {
	description = "Compressed Dirt",
	texture = "torrl_nodes_dirt.png^torrl_nodes_compact_overlay.png",
	groups = {breakable = 1},
})

register_compressable("torrl_nodes:stone_compressed", 6, {
	description = "Compressed Stone",
	texture = "torrl_nodes_stone.png^torrl_nodes_compact_overlay.png",
	groups = {breakable = 1},
})

register_compressable("torrl_nodes:glass", 3, {
	description = "Reinforced Glass",
	texture = "torrl_nodes_glass.png",
	groups = {breakable = 1},
	use_texture_alpha = "clip",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propogates = true,
})

dofile(modpath.."/trec_unit.lua")({
	["torrl_nodes:dirt" ]  = "torrl_nodes:dirt_compressed",
	["torrl_nodes:stone"]  = "torrl_nodes:stone_compressed",
	["torrl_nodes:sand" ]  = "torrl_nodes:glass",
	["torrl_nodes:tree"]   = "torrl_nodes:repair_tape",
	["torrl_nodes:leaves"] = "torrl_nodes:repair_tape",
})

--
--- Terrain
--

minetest.register_node("torrl_nodes:grass", {
	description = "Grass",
	drop = "torrl_nodes:dirt",
	tiles = {"torrl_nodes_grass.png", "torrl_nodes_dirt.png", "torrl_nodes_grass_side.png"},
	groups = {breakable = 1},
})

minetest.register_node("torrl_nodes:dirt", {
	description = "Dirt",
	tiles = {"torrl_nodes_dirt.png"},
	groups = {breakable = 1, compressable = 1},
})

minetest.register_node("torrl_nodes:sand", {
	description = "Sand",
	tiles = {"torrl_nodes_sand.png"},
	groups = {breakable = 1, compressable = 1},
})

minetest.register_node("torrl_nodes:stone", {
	description = "Stone",
	tiles = {"torrl_nodes_stone.png"},
	groups = {blastable = 1, compressable = 1},
})

--
--- Plants
--

minetest.register_node("torrl_nodes:tree", {
	description = "Tree",
	tiles = {"torrl_nodes_tree.png"},
	groups = {breakable = 1},
})

minetest.register_node("torrl_nodes:leaves", {
	drawtype = "glasslike",
	description = "Leaves",
	paramtype = "light",
	sunlight_propogates = true,
	tiles = {"torrl_nodes_leaves.png"},
	groups = {breakable = 1},
})

for name, def in pairs(minetest.registered_nodes) do
	if def.groups and def.groups.blast_ignore then
		table.insert(torrl_nodes.blast_ignore, minetest.get_content_id(name))
	end
end
