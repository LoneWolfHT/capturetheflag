minetest.register_privilege("ctf_admin", {
	description = "Manage administrative ctf settings.",
})

minetest.register_chatcommand("ctf_next", {
	description = "Skip to next match, or a specified map.",
	params = "[<match>]",
	privs = {ctf_admin = true},

	func = function(name, match)
		ctf_modebase.place_map(ctf_modebase.current_mode)
	end,
})
