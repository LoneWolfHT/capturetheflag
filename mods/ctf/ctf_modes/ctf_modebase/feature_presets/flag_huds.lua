local hud = mhud.init()

local FLAG_SAFE             = {color = 0xFFFFFF, text = "Punch the enemy flag(s)! Protect your flag!"         }
local FLAG_STOLEN           = {color = 0xFF0000, text = "Kill %s, they've got your flag!"                     }
local FLAG_STOLEN_YOU       = {color = 0xFF0000, text = "You've got a flag! Run back and punch your flag!"    }
local FLAG_STOLEN_TEAMMATE  = {color = 0x22BB22, text = "Protect teammate(s) %s! They have the enemy flag!"   }
local BOTH_FLAGS_STOLEN     = {color = 0xFF0000, text = "Kill %s to allow teammate(s) %s to capture the flag!"}
local BOTH_FLAGS_STOLEN_YOU = {color = 0xFF0000, text = "You can't capture that flag until %s is killed!"     }

local function get_status(you)
	local teamname = ctf_teams.get(you)

	if not teamname then return end

	local enemy_thief = ctf_modebase.flag_taken[teamname]
	local your_thieves = {}

	for pname in pairs(ctf_modebase.team_flag_takers[teamname]) do
		table.insert(your_thieves, pname)
	end

	if #your_thieves > 0 then
		your_thieves = table.concat(your_thieves, ", ")
	else
		your_thieves = false
	end

	local status

	if enemy_thief then
		if your_thieves then
			if ctf_modebase.taken_flags[you] then
				status = table.copy(BOTH_FLAGS_STOLEN_YOU)
				status.text = status.text:format(enemy_thief)
			else
				status = table.copy(BOTH_FLAGS_STOLEN)
				status.text = status.text:format(enemy_thief, your_thieves)
			end
		else
			status = table.copy(FLAG_STOLEN)
			status.text = status.text:format(enemy_thief)
		end
	else
		if your_thieves then
			if ctf_modebase.taken_flags[you] then
				status = FLAG_STOLEN_YOU
			else
				status = table.copy(FLAG_STOLEN_TEAMMATE)
				status.text = status.text:format(your_thieves)
			end
		else
			status = FLAG_SAFE
		end
	end

	return status
end

local player_timers = nil

local function get_base_label(tname)
	local team = HumanReadable(tname)
	if ctf_modebase.flag_captured[tname] then
		return team .. "'s flag (captured)"
	elseif ctf_modebase.flag_taken[tname] then
		return team .. "'s flag (taken)"
	else
		return team .. "'s flag"
	end
end

local function update()
	for _, player in pairs(minetest.get_connected_players()) do
		for tname in pairs(ctf_map.current_map.teams) do
			hud:change(player, "flag_pos:" .. tname, {waypoint_text = get_base_label(tname)})
		end
	end
end

local timer = 0
minetest.register_globalstep(function(dtime)
	if not player_timers then return end

	timer = timer + dtime
	if timer < 1 then return end

	for pname, timeleft in pairs(player_timers) do
		if timeleft - timer <= 0 then
			ctf_modebase.drop_flags(pname)
			return
		end

		player_timers[pname] = timeleft - timer

		hud:change(pname, "flag_timer", {
			text = string.format("%dm %ds left to capture", math.floor(timeleft / 60), math.floor(timeleft % 60))
		})
	end

	timer = 0
end)

return {
	track_capturer = function(player, time)
		player = PlayerName(player)

		if not player_timers then player_timers = {} end

		if not player_timers[player] then
			player_timers[player] = time

			hud:add(player, "flag_timer", {
				hud_elem_type = "text",
				position = {x = 0.5, y = 0},
				alignment = {x = "center", y = "down"},
				color = 0xFF0000,
				text_scale = 2
			})
		else
			player_timers[player] = time -- Player already has a flag, just reset their capture timer
		end

		update()
	end,
	untrack_capturer = function(player)
		player = PlayerName(player)

		if hud:get(player, "flag_timer") then
			hud:remove(player, "flag_timer")
		end

		if player_timers and player_timers[player] then
			player_timers[player] = nil
		end

		update()
	end,
	on_match_end = function()
		hud:clear_all()

		player_timers = nil
	end,
	on_allocplayer = function(player)
		local status = get_status(player:get_player_name())

		if not hud:exists(player, "flag_status") then
			hud:add(player, "flag_status", {
				hud_elem_type = "text",
				position = {x = 1, y = 0},
				offset = {x = -6, y = 6},
				alignment = {x = "left", y = "down"},
				text = status.text,
				color = status.color,
			})
		else
			hud:change(player, "flag_status", status)
		end

		for tname, def in pairs(ctf_map.current_map.teams) do
			hud:add(player, "flag_pos:" .. tname, {
				hud_elem_type = "waypoint",
				waypoint_text = get_base_label(tname),
				color = ctf_teams.team[tname].color_hex,
				world_pos = def.flag_pos,
			})
		end
	end,
}
