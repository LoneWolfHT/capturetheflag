local hud = mhud.init()

local FLAG_SAFE             = {color = 0xFFFFFF, text = "Punch the enemy flag(s)! Protect your flag!"         }
local FLAG_STOLEN           = {color = 0xFF0000, text = "Kill %s, they've got your flag!"                     }
local FLAG_STOLEN_YOU       = {color = 0xFF0000, text = "You've got a flag! Run back and punch your flag!"    }
local FLAG_STOLEN_TEAMMATE  = {color = 0x22BB22, text = "Protect teammate(s) %s! They have the enemy flag!"   }
local BOTH_FLAGS_STOLEN     = {color = 0xFF0000, text = "Kill %s to allow teammate(s) %s to capture the flag!"}
local BOTH_FLAGS_STOLEN_YOU = {color = 0xFF0000, text = "You can't capture that flag until %s is killed!"     }
local OTHER_FLAG_STOLEN     = {color = 0xAA00FF, text = "Kill %s, they've got some flags!"                    }

local function concat_players(players)
	local list = {}
	for pname in pairs(players) do
		table.insert(list, pname)
	end

	if #list > 0 then
		return table.concat(list, ", ")
	end

	return false
end

local function get_flag_status(you)
	local teamname = ctf_teams.get(you)

	if not teamname then return end

	local enemy_thief = ctf_modebase.flag_taken[teamname]
	local your_thieves = {}
	local other_thieves = {}

	for tname, player in pairs(ctf_modebase.flag_taken) do
		if player.t == teamname then
			your_thieves[player.p] = true
		else
			other_thieves[player.p] = true
		end
	end

	if enemy_thief then
		enemy_thief = enemy_thief.p
	end

	your_thieves = concat_players(your_thieves)
	other_thieves = concat_players(other_thieves)

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
		elseif other_thieves then
			status = table.copy(OTHER_FLAG_STOLEN)
			status.text = status.text:format(other_thieves)
		else
			status = FLAG_SAFE
		end
	end

	return status
end

local function update_player(player)
	local flag_status = get_flag_status(player:get_player_name())

	if hud:exists(player, "flag_status") then
		hud:change(player, "flag_status", flag_status)
	else
		hud:add(player, "flag_status", {
			hud_elem_type = "text",
			position = {x = 1, y = 0},
			offset = {x = -6, y = 6},
			alignment = {x = "left", y = "down"},
			text = flag_status.text,
			color = flag_status.color,
		})
	end

	for tname, def in pairs(ctf_map.current_map.teams) do
		local hud_label = "flag_pos:" .. tname

		local base_label = HumanReadable(tname) .. "'s flag"
		if ctf_modebase.flag_captured[tname] then
			base_label = base_label .. " (captured)"
		elseif ctf_modebase.flag_taken[tname] then
			base_label = base_label .. " (taken)"
		end

		if hud:exists(player, hud_label) then
			hud:change(player, hud_label, {waypoint_text = base_label})
		else
			hud:add(player, hud_label, {
				hud_elem_type = "waypoint",
				waypoint_text = base_label,
				color = ctf_teams.team[tname].color_hex,
				world_pos = def.flag_pos,
			})
		end
	end
end

local function update()
	for _, player in pairs(minetest.get_connected_players()) do
		update_player(player)
	end
end

local player_timers = {}

local function update_timer(pname)
	if player_timers[pname] then
		local timeleft = player_timers[pname]

		if timeleft <= 1 then
			ctf_modebase.drop_flags(pname)
		else
			player_timers[pname] = timeleft - 1

			hud:change(pname, "flag_timer", {
				text = string.format("%dm %ds left to capture", math.floor(timeleft / 60), math.floor(timeleft % 60))
			})

			minetest.after(1, update_timer, pname)
		end
	end
end

ctf_modebase.flag_huds = {}

function ctf_modebase.flag_huds.track_capturer(player, time)
	player = PlayerName(player)

	if not player_timers[player] then
		player_timers[player] = time + 1

		hud:add(player, "flag_timer", {
			hud_elem_type = "text",
			position = {x = 0.5, y = 0},
			alignment = {x = "center", y = "down"},
			color = 0xFF0000,
			text_scale = 2
		})

		update_timer(player)
	else
		player_timers[player] = time -- Player already has a flag, just reset their capture timer
	end

	update()
end

function ctf_modebase.flag_huds.untrack_capturer(player)
	player = PlayerName(player)

	if hud:get(player, "flag_timer") then
		hud:remove(player, "flag_timer")
	end

	player_timers[player] = nil

	update()
end

function ctf_modebase.flag_huds.on_match_end()
	hud:clear_all()

	player_timers = {}
end

function ctf_modebase.flag_huds.on_allocplayer(player)
	update_player(player)
end
