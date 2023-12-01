unused_args = false

globals = {
	"torrl_core",
	"torrl_tools", "torrl_effects", "torrl_nodes", "torrl_aliens", "torrl_player",
	"torrl_voiceover",

	"trec_unit",

	"creatura", "fire", "player_api",

	"unpack",
	"VoxelManip", "VoxelArea", "PseudoRandom", "ItemStack",
	"Settings",
	"vector", "table", "string", "dump",
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
	"mods/show_wielded_item/",
	"mods/wield3d/",
}
