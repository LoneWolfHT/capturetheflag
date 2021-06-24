local hud = mhud.init()

local BUILD_TIME = 3 * 60

local target_map
local timer
local second_timer = 0

local build_timer = {
	start = function(mapdef)
		timer = BUILD_TIME
		target_map = mapdef
	end,
	in_progress = function()
		return timer ~= nil
	end,
	finish = function()
		timer = nil

		if target_map then
			ctf_map.remove_barrier(target_map)
			hud:remove_all()

			target_map = nil
			timer = nil
			second_timer = 0
		end
	end
}

minetest.register_globalstep(function(dtime)
	if not timer then return end

	timer = timer - dtime
	second_timer = second_timer + dtime

	if timer <= 0 then
		return build_timer.finish()
	end

	if second_timer >= 1 then
		second_timer = 0

		for _, player in pairs(minetest.get_connected_players()) do
			local time_str = string.format("%dm %ds until match begins!", math.floor(timer / 60), math.floor(timer % 60))
			local pteam = ctf_teams.get_team(player)

			if not hud:exists(player, "build_timer") then
				hud:add(player, "build_timer", {
					hud_elem_type = "text",
					position = {x = 0.5, y = 0.5},
					offset = {x = 0, y = -42},
					alignment = {x = "center", y = "up"},
					text = time_str,
					color = 0xFFFFFF,
				})
			else
				hud:change(player, "build_timer", {
					text = time_str
				})
			end

			-- local pos1, pos2 = ctf_teams.get_team_territory(pteam)
			-- if not ctf_core.area_contains(pos1, pos2, player:get_pos()) then
			-- 	minetest.chat_send_player(player:get_player_name(), "You can't cross the barrier until build time is over!")
			-- 	mode_classic.tp_player_near_flag(player)
			-- end
		end
	end
end)

ctf_modebase.register_chatcommand("classic", "start", {
	description = "Skip build time",
	privs = {ctf_admin = true},
	func = function(name, param)
		build_timer.finish()

		return true, "Build time ended"
	end,
})

return build_timer