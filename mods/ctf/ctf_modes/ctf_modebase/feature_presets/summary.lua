local previous = nil

return function(mode_data, rankings)

local start_time = nil

local function team_rankings(total)
	local ranks = {}

	for team, rank_values in pairs(total) do
		rank_values._row_color = ctf_teams.team[team].color

		ranks[HumanReadable("team "..team)] = rank_values
	end

	return ranks
end

local function get_duration()
	if not start_time then
		return "-"
	end

	local time = os.time() - start_time
	return string.format("%02d:%02d:%02d",
        math.floor(time / 3600),        -- hours
        math.floor((time % 3600) / 60), -- minutes
        math.floor(time % 60))          -- seconds
end

return {
	summary_func = function(prev)
		if not prev then
			return
				{
					rankings = rankings.recent(),
					special_rankings = team_rankings(rankings.teams()),
					duration = get_duration(),
				}, {
					title = "Match Summary",
					special_row_title = "Total Team Stats",
					buttons = {previous = previous ~= nil},
				}, mode_data.SUMMARY_RANKS
		elseif previous ~= nil then
			return
				{
					rankings = previous.players,
					special_rankings = team_rankings(previous.teams),
					duration = previous.duration,
				}, {
					title = "Previous Match Summary",
					special_row_title = "Total Team Stats",
					buttons = {next = true},
				}, previous.mode_data.SUMMARY_RANKS
		end
	end,
	on_match_end = function()
		previous = {
			players = rankings.recent(),
			teams = rankings.teams(),
			duration = get_duration(),
			mode_data = mode_data,
		}
		start_time = nil
	end,
	match_start = function ()
		start_time = os.time()
	end,
}

end
