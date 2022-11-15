torrl_tools = {}

minetest.register_tool("torrl_tools:mappick", {
	description = "Map Pickaxe",
	inventory_image = "torrl_tools_mappick.png",
	range = 15,
	tool_capabilities = {
		full_punch_interval = 0.1,
		max_drop_level = 3,
		groupcaps = {
			breakable = {times={[1] = 0.6, [2] = 0.6, [3] = 0.6}, uses = 0, maxlevel = 3},
			blastable = {times={[1] = 0.6, [2] = 0.6, [3] = 0.6}, uses = 0, maxlevel = 3},
		},
		damage_groups = {fleshy = 4},
	}
})

local files = {
	"update_wear.lua",
	"hammer_of_power.lua",
}

for _, file in ipairs(files) do
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/" .. file)
end
