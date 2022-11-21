local config = Settings(minetest.get_worldpath() .. "/world.mt")
if config:get("backend") ~= "dummy" then
	config:set("backend","dummy")
	config:write()
end

minetest.set_mapgen_setting("mg_name", "flat", true)
minetest.set_mapgen_setting("mg_flags", "nocaves, nodungeons, light, decorations, biomes", true)
minetest.set_mapgen_setting("mgflat_spflags", "hills, lakes", true)
minetest.set_mapgen_setting("mgflat_hill_threshhold", "0.4", true)
minetest.set_mapgen_setting("mgflat_lake_threshhold", "-0.7", true)
minetest.set_mapgen_setting("mgflat_lake_steepness", "200.0", true)
minetest.set_mapgen_setting("mgflat_hill_steepness", "100.0", true)
minetest.set_mapgen_setting(
	"mgflat_np_terrain",
	"noise_params_2d "..table.concat({
		"0"              , --offset
		"1"              , --scale
		"(140, 100, 140)", --spread
		"10441740"     , --seed
		"5"              , --octaves
		"0.4"            , --persistence
		"3"              , --lacunarity
		"absvalue"          , --default flags
	}, ", "),
	true
)

dofile(minetest.get_modpath(minetest.get_current_modname()).."/structures.lua")

minetest.register_alias("mapgen_stone", "torrl_nodes:stone")

--
--- Decorations
--

do
	local def = {
		deco_type = "schematic",
		place_on = "torrl_nodes:grass",
		sidelen = 2,
		place_offset_y = 1,
		noise_params = {
			offset = -0.1,
			scale = 0.1,
			spread = {x = 20, y = 20, z = 20},
			seed = 74332,
			octaves = 2,
		},
		biomes = {"grass_biome"},
		y_min = 0,
		y_max = 12,
		schematic = "schematics/tree_straight.mts",
		flags = "place_center_x, place_center_z",
		rotation = "random",
	}

	minetest.register_decoration(def)

	def.schematic = "schematics/tree_lazy.mts"
	minetest.register_decoration(def)
end

--
--- Biomes
--

minetest.register_biome({
	name = "grass_biome",
	node_top = "torrl_nodes:grass",
	depth_top = 1,
	node_filler = "torrl_nodes:dirt",
	depth_filler = 5,
	node_riverbed = "torrl_nodes:sand",
	depth_riverbed = 5,
	y_max = 50,
    y_min = 4,
	vertical_blend = 8,
	heat_point = 50,
	humidity_point = 35,
})

minetest.register_biome({
	name = "mountain_biome",
	node_top = "torrl_nodes:sand",
	depth_top = 1,
	node_filler = "torrl_nodes:dirt",
	depth_filler = 5,
	node_riverbed = "torrl_nodes:sand",
	depth_riverbed = 5,
	y_max = 1500,
	y_min = 50,
	vertical_blend = 8,
	heat_point = 50,
	humidity_point = 35,
})

minetest.register_biome({
	name = "ocean",
	node_top = "torrl_nodes:sand",
	depth_top = 1,
	node_filler = "torrl_nodes:sand",
	depth_filler = 5,
	node_riverbed = "torrl_nodes:sand",
	depth_riverbed = 5,
	node_cave_liquid = "torrl_nodes:water_source",
	y_max = 3,
	y_min = -255,
	heat_point = 50,
	humidity_point = 35,
})
