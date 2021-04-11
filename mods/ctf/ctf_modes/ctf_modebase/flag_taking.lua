ctf_modebase.register_on_new_match(function(mapdef, old_mapdef)
	ctf_modebase.taken_flags = {}
	ctf_modebase.flag_taken = {}

	for tname in pairs(mapdef.teams) do
		ctf_modebase.flag_taken[tname] = false
	end
end)

local function drop_flags(pname, dont_run_callbacks)
	local flagteams = ctf_modebase.taken_flags[pname]

	if flagteams then
		for _, flagteam in pairs(flagteams) do
			ctf_modebase.flag_taken[flagteam] = false
		end

		ctf_modebase.taken_flags[pname] = nil

		if not dont_run_callbacks then
			RunCallbacks(ctf_modebase.registered_on_flag_drop, pname, flagteams)
		end
	end
end

function ctf_modebase.flag_on_punch(puncher, nodepos, node)
	local pname = PlayerName(puncher)

	if not ctf_teams.player_team[pname] then
		minetest.chat_send_player(pname, "You're not in a team, you can't take that flag!")
		return
	end

	local pteam = ctf_teams.player_team[pname].name
	local target_team = node.name:sub(node.name:find("top_") + 4)

	if pteam ~= target_team then
		if not ctf_modebase.taken_flags[pname] then
			ctf_modebase.taken_flags[pname] = {}
		end

		table.insert(ctf_modebase.taken_flags[pname], target_team)
		ctf_modebase.flag_taken[target_team] = pname

		local result = RunCallbacks(ctf_modebase.registered_on_flag_take, pname, target_team)

		if not result then
			minetest.set_node(nodepos, {name = "ctf_modebase:flag_captured_top", param2 = node.param2})
		elseif type(result) == "string" then
			minetest.chat_send_player(pname, "You can't take that flag. Reason: "..result)
		end
	else
		if not ctf_modebase.taken_flags[pname] then
			minetest.chat_send_player(pname, "That's your flag!")
		else
			drop_flags(pname, true)

			local result = RunCallbacks(ctf_modebase.registered_on_flag_capture, pname, ctf_modebase.taken_flags[pname])

			if type(result) == "string" then
				minetest.chat_send_player(pname, "You can't capture. Reason: "..result)
			end
		end
	end
end

minetest.register_on_dieplayer(function(player)
	local pname = player:get_player_name()

	drop_flags(pname)
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	drop_flags(pname)
end)
