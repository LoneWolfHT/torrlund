unused_args = false

globals = {
	"torrl_core",
	"torrl_tools", "torrl_effects", "torrl_nodes", "torrl_aliens",

	"trec_unit",

	"creatura",

	"VoxelManip", "VoxelArea", "PseudoRandom",
	"vector", "table", "string",
	math = {
		fields = {
			"round",
			"hypot",
			"sign",
			"factorial",
			"ceil",
		}
	},

	"minetest", "core",
}

exclude_files = {
	"mods/mtg/mtg_*",
	"mods/ext_libs/",
	"mobs/torrl_map/modgen_mod_export/"
}
