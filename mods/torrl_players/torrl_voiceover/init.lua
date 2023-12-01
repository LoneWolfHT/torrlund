local saying = {
--[[
	["<playername>"] = {
	_name = filename,
	_soundhandle = handle of currently playing sound
	_timer = timer until the next sound is played
	}
]]
}

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()

	if saying[name]._timer then
		saying[name]._timer:cancel()
	end

	saying[name] = nil
end)

local function say(pname, file, time, text)
	minetest.log("error", "Voice Error, uninitialized version of say() called")
end

local function next(pname)
	assert(pname)
	if not saying[pname] then return end

	if saying[pname]._timer then
		saying[pname]._timer:cancel()
		saying[pname]._timer = nil
	end

	if saying[pname]._soundhandle then
		minetest.sound_stop(saying[pname]._soundhandle)
		saying[pname]._soundhandle = nil

		minetest.sound_play({name = "torrl_voiceover_skip"}, {
			to_player = pname,
			object = torrl_player.get_companion(pname).object,
			gain = 0.5,
		}, true)
	end

	if #saying[pname] >= 1 and minetest.get_player_by_name(pname) then
		say(pname, unpack(table.remove(saying[pname], 1)))
		return
	end

	saying[pname] = nil
end

function say(pname, file, time, text)
	assert(pname and file and time and text)
	saying[pname]._name = file

	minetest.after(0.5, function()
		if not saying[pname] then return end

		saying[pname]._soundhandle = minetest.sound_play({name = "torrl_voiceover_"..file}, {
			to_player = pname,
			object = torrl_player.get_companion(pname).object,
			gain = 1.2,
		})

		minetest.chat_send_player(pname, minetest.colorize(
			"cyan",
			"<C.O.M.P Unit> " .. text
		))

		saying[pname]._timer = minetest.after(time+1, function()
			saying[pname]._timer = nil
			saying[pname]._soundhandle = nil

			next(pname)
		end)
	end)
end

local function get_say(times, file, time, text)
	assert(times and file and time and text)
	local said = {}

	local function init(pname)
		if not pname then
			for _, p in pairs(minetest.get_connected_players()) do
				init(p:get_player_name())
			end

			return
		end

		if said[pname] and times and said[pname] >= times then
			return
		else
			said[pname] = (said[pname] or 0) + 1
		end

		if not saying[pname] then
			saying[pname] = {}
		else
			table.insert(saying[pname], {file, time, text})

			return
		end

		say(pname, file, time, text)
	end

	return init
end

torrl_voiceover = {
	skip = function(pname)
		if not pname then
			for _, p in pairs(minetest.get_connected_players()) do
				next(p:get_player_name())
			end

			return
		end

		next(pname)
	end,

	say_greeting = get_say(1, "greeting", 8.0,
		"Greetings. Your ship is badly damaged. I will need a tough metal to repair it"
	),
	say_abilities = get_say(1, "explain_abilities", 4.5,
		"Rightclick while holding a tool to activate its ability"
	),
	say_abilities_trec = get_say(1, "explain_abilities_trec", 5,
		"You must place the T.R.E.C Unit to use tool abilities"
	),
	say_tools = get_say(1, "explain_tools", 6.0,
		"You can switch to a different weapon by rightclicking me with your current one"
	),
	say_hammer = get_say(1, "explain_hammer", 10.5,
		"Until your hammer recharges you are immune to fall damage. Try zooming back to the ground next time"
	),
	say_sword = get_say(1, "explain_sword", 9.5,
		"You can rightclick with your sword a second time while looking at the ground to do an area damage attack"
	),
	say_meteorite = get_say(1, "explain_meteorite", 13.2,
		"That will work, put it in your T.R.E.C Unit. To repair the ship I need 5 for every passenger. " ..
		"Keep an eye out for meteors"
	),
	say_compress = get_say(1, "explain_compress", 8.8,
		"You can use your T.R.E.C unit to compress blocks, which will be helpful for protecting the T.R.E.C unit"
	),
	say_detected = get_say(2, "detected", 3.5,
		"Alien ship detected. Protect the T.R.E.C Unit"
	),
	say_followed = get_say(1, "followed", 7.0,
		"Command just sent a retreat signal, our fleet has lost the battle"
	),
	say_trec = get_say(1, "explain_trec", 8.0,
		"While your T.R.E.C Unit is placed you will be able to use your tool abilities and respawn"
	),
	say_repairing = get_say(1, "repairing", 2.0,
		"Repairing ship, stand by"
	),
}
