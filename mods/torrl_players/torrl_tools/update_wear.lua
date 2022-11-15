local PlayerName = torrl_core.PlayerName

local wear_timers = {}

torrl_tools.update_wear = {}

function torrl_tools.update_wear.find_item(pinv, item)
	for pos, stack in pairs(pinv:get_list("main")) do
		if stack:get_name() == item then
			return pos, stack
		end
	end
end

function torrl_tools.update_wear.start_update(pname, item, step, down, finish_callback, cancel_callback)
	if not wear_timers[pname] then wear_timers[pname] = {} end
	if wear_timers[pname][item] then return end

	wear_timers[pname][item] = {c=cancel_callback, t=minetest.after(0.5, function()
		wear_timers[pname][item] = nil
		local player = minetest.get_player_by_name(pname)

		if player then
			local pinv = player:get_inventory()
			local pos, stack = torrl_tools.update_wear.find_item(pinv, item)

			if pos then
				local wear = stack:get_wear()

				if down then
					wear = math.max(0, wear - step)
				else
					wear = math.min(65534, wear + step)
				end

				stack:set_wear(wear)
				pinv:set_stack("main", pos, stack)

				if (down and wear > 0) or (not down and wear < 65534) then
					torrl_tools.update_wear.start_update(pname, item, step, down, finish_callback, cancel_callback)
				elseif finish_callback then
					finish_callback()
				end
			end
		end
	end)}
end

function torrl_tools.update_wear.cancel_player_updates(pname)
	pname = PlayerName(pname)

	if wear_timers[pname] then
		for _, timer in pairs(wear_timers[pname]) do
			if timer.c then
				timer.c()
			end
			timer.t:cancel()
		end

		wear_timers[pname] = nil
	end
end

minetest.register_on_leaveplayer(function(player)
	torrl_tools.update_wear.cancel_player_updates(player)
end)
