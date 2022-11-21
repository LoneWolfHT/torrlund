local creative = minetest.settings:get_bool("creative_mode", false)

minetest.register_node("torrl_nodes:ship_armor", {
	description = "Ship Armor",
	tiles = {"torrl_nodes_ship_armor.png"},
	groups = {blastable = creative and 1 or nil},
})

minetest.register_node("torrl_nodes:ship_armor_cracked", {
	description = "Cracked Ship Armor",
	tiles = {"torrl_nodes_ship_armor.png^[crack:1:1:4"},
	drop = "",
	groups = {breakable = 1},
})

minetest.register_node("torrl_nodes:ship_tile", {
	description = "Ship Tile",
	tiles = {"torrl_nodes_ship_tile.png"},
	light_source = 5,
	groups = {blastable = creative and 1 or nil},
})

minetest.register_node("torrl_nodes:ship_light", {
	description = "Ship Light",
	tiles = {"torrl_nodes_ship_light.png"},
	light_source = 12,
	groups = {blastable = creative and 1 or nil},
})

minetest.register_node("torrl_nodes:ship_booster", {
	description = "Ship Booster",
	tiles = {"torrl_nodes_ship_booster.png"},
	groups = {blastable = creative and 1 or nil},
})

minetest.register_node("torrl_nodes:ship_window", {
	description = "Ship Window",
	tiles = {"torrl_nodes_ship_window.png"},
	groups = {blastable = creative and 1 or nil},
	light_source = 12,
	use_texture_alpha = "clip",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propogates = true,
})
