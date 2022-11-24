local music = {}
local sday   = {}

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer >= 1 then
		local time = minetest.get_timeofday()
		local day = "day"

		if time >= 0.82 or time <= 0.18 then
			day = "night"
		end

		if torrl_player.won then
			day = "themewin"
		end

		for _, player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()

			if not music[name] then
				sday[name] = day

				music[name] = minetest.sound_play({name = day}, {
					to_player = name,
					gain = 0.1,
					loop = true,
				})
			else
				local vol = (1.1 + 0.2) - math.max(0.2, (player:get_hp() / 20) * 1.1)

				if day == "themewin" then
					vol = 1.1
				end

				minetest.sound_fade(music[name], 3, vol)

				if sday[name] ~= day then
					sday[name] = day

					minetest.sound_fade(music[name], 3, 0)

					music[name] = minetest.sound_play({name = day}, {
						to_player = name,
						gain = 0.1,
						loop = true,
					})
				end
			end
		end
	end
end)
