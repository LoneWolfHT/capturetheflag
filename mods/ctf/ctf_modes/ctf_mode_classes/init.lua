ctf_gui.init()

mode_classes = {
	SUMMARY_RANKS = {
		_sort = "score",
		"score",
		"flag_captures", "flag_attempts",
		"kills", "kill_assists", "bounty_kills",
		"deaths",
		"hp_healed"
	}
}

local rankings = ctf_modebase.feature_presets.rankings("classes", mode_classes)
local summary = ctf_modebase.feature_presets.summary(mode_classes, rankings)
local flag_huds = ctf_modebase.feature_presets.flag_huds
local bounties = ctf_modebase.feature_presets.bounties(rankings)
local teams = ctf_modebase.feature_presets.teams(rankings, summary, flag_huds)

local crafts, classes = ctf_core.include_files(
	"crafts.lua",
	"classes.lua"
)

function mode_classes.dist_from_flag(player)
	local tname = ctf_teams.get(player)

	if not tname then return 0 end

	return vector.distance(ctf_map.current_map.teams[tname].flag_pos, PlayerObj(player):get_pos())
end

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
local old_get_colored_skin = ctf_cosmetics.get_colored_skin
ctf_modebase.register_mode("classes", {
	map_whitelist = {
		"bridge", "caverns", "coast", "iceage", "two_hills", "plains", "desert_spikes", "river_valley", "plain_battle",
		"karsthafen", "abandoned_isles", "ahkmenrah_pyramids", "capture_legend", "moon", "big_ocean", "green_hills",
		"mayan_legend", "mini_village", "nether_kingdom", "snowland", "the_wall",
	},
	treasures = {
		["default:ladder_wood"] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:cobble"] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 5},
		["default:wood"  ] = {min_count = 10, max_count = 60, rarity = 0.5, max_stacks = 4},

		["ctf_teams:door_steel"] = {rarity = 0.2, max_stacks = 3},

		["default:pick_steel"  ] = {rarity = 0.4, max_stacks = 3},
		["default:shovel_steel"] = {rarity = 0.4, max_stacks = 2},
		["default:axe_steel"   ] = {rarity = 0.4, max_stacks = 2},

		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:rifle_loaded"  ] = {rarity = 0.2                 },
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.05                },

		["ctf_ranged:ammo"     ] = {min_count = 3, max_count = 10, rarity = 0.3 , max_stacks = 2},
		["default:apple"       ] = {min_count = 5, max_count = 20, rarity = 0.1 , max_stacks = 2},

		["grenades:frag" ] = {rarity = 0.1, max_stacks = 1},
		["grenades:smoke"] = {rarity = 0.2, max_stacks = 2},
	},
	crafts = crafts,
	physics = {sneak_glitch = true, new_move = false},

	is_bound_item = function(_, itemstack)
		local iname = itemstack:get_name()

		if itemstack:get_definition().groups.sword or
		iname:match("ctf_mode_classes:") or
		iname == "ctf_healing:bandage" then
			return true
		end
	end,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = bounties.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = bounties.get_next_bounty

		ctf_cosmetics.get_colored_skin = function(player, color)
			local classname = classes.get_name(player)

			return old_get_colored_skin(player, color) .. (classname and "^ctf_mode_classes_"..classname.."_overlay.png" or "")
		end
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty

		ctf_cosmetics.get_colored_skin = old_get_colored_skin

		classes.finish()
	end,
	on_new_match = function(mapdef)
		teams.on_new_match()

		ctf_modebase.build_timer.start(mapdef, 60 * 1.5, function()
			summary.on_match_start()
			ctf_modebase.bounties.on_match_start()
		end)

		give_initial_stuff.register_stuff_provider(function(player)
			local initial_stuff = classes.get(player).items or {}

			table.insert_all(initial_stuff, {"default:pick_stone", "default:torch 15", "default:stick 5"})

			return(initial_stuff)
		end)

		ctf_map.place_chests(mapdef)
	end,
	on_match_end = function()
		teams.on_match_end()

		summary.on_match_end()
		rankings.on_match_end()

		ctf_modebase.update_wear.cancel_updates()

		ctf_modebase.bounties.on_match_end()

		flag_huds.on_match_end()
	end,
	summary_func = summary.summary_func,
	allocate_player = teams.allocate_player,
	on_allocplayer = function(player, teamname)
		classes.set(player)

		teams.on_allocplayer(player, teamname)
	end,
	on_leaveplayer = teams.on_leaveplayer,
	on_dieplayer = teams.on_dieplayer,
	on_respawnplayer = teams.on_respawnplayer,
	can_take_flag = teams.can_take_flag,
	on_flag_take = teams.on_flag_take,
	on_flag_drop = teams.on_flag_drop,
	on_flag_capture = teams.on_flag_capture,
	on_flag_rightclick = function(clicker, pos, node)
		classes:show_class_formspec(clicker)
	end,
	get_chest_access = teams.get_chest_access,
	on_punchplayer = teams.on_punchplayer,
	on_healplayer = teams.on_healplayer,
	calculate_knockback = function()
		return 0
	end,
})
