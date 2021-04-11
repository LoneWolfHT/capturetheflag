unused_args = false

globals = {
	"ctf_core", "ctf_map", "ctf_teams", "ctf_modebase", "ctf_gui",

	"PlayerObj", "PlayerName", "HumanReadable", "RunCallbacks",

	"ChatCmdBuilder", "mhud",

	"physics", "give_initial_stuff", "medkits", "grenades", "dropondie",
	"vote", "random_messages", "sfinv", "email", "hb", "wield3d", "irc",
	"default", "skybox",

	"vector",
}

exclude_files = {
	"mods/other/crafting",
	"mods/mtg/"
}

read_globals = {
	"DIR_DELIM",
	"minetest", "core",
	"dump", "dump2",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "PcgRandom",
	"ItemStack",
	"Settings",
	"unpack",

	table = {
		fields = {
			"copy",
			"indexof",
			"insert_all",
			"key_value_swap",
			"shuffle",
		}
	},

	string = {
		fields = {
			"split",
			"trim",
		}
	},

	math = {
		fields = {
			"hypot",
			"sign",
			"factorial"
		}
	},
}
