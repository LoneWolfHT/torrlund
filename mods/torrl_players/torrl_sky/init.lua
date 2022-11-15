minetest.register_on_joinplayer(function(player)
	player:set_sky({
		type = "regular",
		base_color = 0x5a6988,
		sky_color = {
			day_sky = 0x8b9bb4,
			day_horizon = 0x5a6988,
			dawn_sky = 0x3e2731,
			dawn_horizon = 0xbe4a2f,
			night_sky = 0x262b44,
			night_horizon = 0x181425,
			indoors = 0x000000,
		}
	})

	player:set_clouds({
		density = 0.4,
		color = "#5a6988",
		thickness = 20,
		height = 120,
		speed = {x=10, z=0},
	})

	player:set_stars({
		count = 3000,
		scale = 0.4,
		star_color = "#ead4aa",
	})

	player:set_lighting({shadows = {intensity = 0.5}})
end)
