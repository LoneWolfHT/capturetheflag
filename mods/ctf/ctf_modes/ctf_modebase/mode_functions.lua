-- add_mode_func(minetest.register_on_dieplayer, "on_dieplayer", true) is the same as calling
--[[
	minetest.register_on_dieplayer(function(...)
		if current_mode.on_dieplayer then
			return current_mode.on_dieplayer(...)
		end
	end, true)
]]--
local function add_mode_func(minetest_func, mode_func_name, ...)
	minetest_func(function(...)
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode then return end

		if current_mode[mode_func_name] then
			return current_mode[mode_func_name](...)
		end
	end, ...)
end

add_mode_func(ctf_teams.register_on_allocplayer  , "on_allocplayer"  )
add_mode_func(ctf_teams.register_on_deallocplayer, "on_deallocplayer")
add_mode_func(minetest .register_on_dieplayer    , "on_dieplayer"    )
add_mode_func(minetest .register_on_respawnplayer, "on_respawnplayer")
add_mode_func(minetest .register_on_punchplayer  , "on_punchplayer"  )

add_mode_func(ctf_modebase.register_on_new_match, "on_new_match", true)
add_mode_func(ctf_modebase.register_on_new_mode, "on_mode_start", true)

add_mode_func(ctf_modebase.register_on_flag_take    , "on_flag_take"    )
add_mode_func(ctf_modebase.register_on_flag_drop    , "on_flag_drop"    )
add_mode_func(ctf_modebase.register_on_flag_capture , "on_flag_capture" )

add_mode_func(ctf_modebase.register_on_treasurefy_node, "on_treasurefy_node")
