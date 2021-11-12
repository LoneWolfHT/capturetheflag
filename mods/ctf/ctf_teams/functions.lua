--
--- Team set/get
--

---@param player string | ObjectRef
function ctf_teams.remove_online_player(player)
	player = PlayerName(player)

	local team = ctf_teams.player_team[player]
	if team then
		if ctf_teams.online_players[team].players[player] then
			ctf_teams.online_players[team].players[player] = nil
			ctf_teams.online_players[team].count = ctf_teams.online_players[team].count - 1
		end
	end
	ctf_teams.player_team[player] = nil
end

---@param player string | ObjectRef
---@param teamname string | nil
function ctf_teams.set(player, teamname)
	player = PlayerName(player)

	if not teamname then
		ctf_teams.player_team[player] = nil
		ctf_teams.remembered_player[player] = nil
		return
	end

	assert(type(teamname) == "string")

	if ctf_teams.player_team[player] == teamname then
		return
	end

	ctf_teams.remove_online_player(player)

	ctf_teams.player_team[player] = teamname
	ctf_teams.remembered_player[player] = teamname
	ctf_teams.online_players[teamname].players[player] = true
	ctf_teams.online_players[teamname].count = ctf_teams.online_players[teamname].count + 1

	RunCallbacks(ctf_teams.registered_on_allocplayer, PlayerObj(player), teamname)
end

---@param player string | ObjectRef
---@return nil | string
function ctf_teams.get(player)
	player = PlayerName(player)

	return ctf_teams.player_team[player]
end

--
--- Allocation
--

local tpos = 1
function ctf_teams.default_allocate_player(player)
	if #ctf_teams.current_team_list <= 0 then return end -- No teams initialized yet
	player = PlayerName(player)

	if not ctf_teams.remembered_player[player] then
		ctf_teams.set(player, ctf_teams.current_team_list[tpos])

		if tpos >= #ctf_teams.current_team_list then
			tpos = 1
		else
			tpos = tpos + 1
		end
	else
		ctf_teams.set(player, ctf_teams.remembered_player[player])
	end
end
ctf_teams.allocate_player = ctf_teams.default_allocate_player

---@param teams table
-- Should be called at match start
function ctf_teams.allocate_teams(teams)
	ctf_teams.player_team = {}
	ctf_teams.online_players = {}
	ctf_teams.current_team_list = {}
	ctf_teams.remembered_player = {}
	tpos = 1

	for teamname, def in pairs(teams) do
		ctf_teams.online_players[teamname] = {count = 0, players = {}}
		table.insert(ctf_teams.current_team_list, teamname)
	end

	local players = minetest.get_connected_players()
	table.shuffle(players)
	for _, player in ipairs(players) do
		ctf_teams.allocate_player(player)
	end
end

--
--- Other
--

---@param teamname string Name of team
---@return boolean | table,table
--- Returns 'false' if there is no current map.
---
--- Example usage: `pos1, pos2 = ctf_teams.get_team_territory("red")`
function ctf_teams.get_team_territory(teamname)
	local current_map = ctf_map.current_map
	if not current_map then return false end

	return current_map.teams[teamname].pos1, current_map.teams[teamname].pos2
end

---@param teamname string Name of team
---@param message string message to send
--- Like `minetest.chat_send_player()` but sends to all members of the given team
function ctf_teams.chat_send_team(teamname, message)
	assert(teamname and message, "Incorrect usage of chat_send_team()")

	for player in pairs(ctf_teams.online_players[teamname].players) do
		minetest.chat_send_player(player, message)
	end
end
