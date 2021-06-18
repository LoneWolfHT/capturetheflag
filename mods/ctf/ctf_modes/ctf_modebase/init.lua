ctf_modebase = {
	-- Time until voting ends
	VOTING_TIME          = 5,    ---@type integer

	-- Amount of maps that need to be played before a mode vote starts
	MAPS_PER_MODE        = 3,     ---@type integer

	-- Table containing all registered modes and their definitions
	modes                = {},    ---@type table

	-- Same as ctf_modebase.modes but in list form
	modelist             = {},    ---@type list

	-- Name of the mode currently being played. On server start this will be false
	current_mode         = false, ---@type string

	-- Amount of matches played since this mode won the last vote
	current_mode_matches = 0,     ---@type integer

	-- taken_flags[Player Name] = list of team names
	taken_flags          = {},

	-- flag_taken[Team Name] = Name of thief
	flag_taken           = {},
}

ctf_gui.init()

ctf_core.include_files(
	"give_initial_stuff.lua",
	"treasure.lua",
	"register.lua",
	"flag_nodes.lua",
	"match.lua",
	"flag_taking.lua",
	"mode_functions.lua",
	"commands.lua"
)

if ctf_core.settings.server_mode == "play" then
	local match_started = false

	minetest.register_on_joinplayer(function(player)
		if not match_started then
			ctf_modebase.current_mode_matches = ctf_modebase.MAPS_PER_MODE
			ctf_modebase.start_new_match(true)
			match_started = true
		end

		player:set_hp(player:get_properties().hp_max)
	end)
end

minetest.register_chatcommand("ctf_next", {
	description = "Skip to a new match.",
	privs = {ctf_admin = true},
	func = function(name, param)
		ctf_modebase.start_new_match()

		return true
	end,
})
