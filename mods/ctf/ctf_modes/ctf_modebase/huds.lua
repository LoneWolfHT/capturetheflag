local hud = mhud.init()

--Add huds when players join
minetest.register_on_joinplayer(function(player)
	local mode_HUD
	local map_HUD
	local map_duration_HUD = "Map duration: "

	if ctf_modebase.current_mode then
		mode_HUD = "Mode: " .. ctf_modebase.current_mode
	else
		mode_HUD = "Mode: "
	end

	if ctf_map.current_map ~= false then
		map_HUD = "Map: " .. ctf_map.current_map.name
	else
		map_HUD = "Map: "
	end

	--Mode
	hud:add(player:get_player_name(), "mode_hud", {
		hud_elem_type = "text",
		position = {x = 1, y = 0.2},
		alignment = {x = "left", y = "up"},
		offset = {x = 1, y = 0.2},
		text = mode_HUD,
		text_scale = 1.7,
		color = 0xF00000,
	})

	--Map
	hud:add(player:get_player_name(), "map_hud", {
		hud_elem_type = "text",
		position = {x = 1, y = 0.23},
		alignment = {x = "left", y = "up"},
		offset = {x = 1, y = 0.23},
		text = map_HUD,
		text_scale = 1.7,
		color = 0xF00000,
	})

	--Match duration
	hud:add(player:get_player_name(), "match_duration_hud", {
		hud_elem_type = "text",
		position = {x = 1, y = 0.26},
		alignment = {x = "left", y = "up"},
		offset = {x = 1, y = 0.26},
		text = map_duration_HUD_len,
		text_scale = 1.7,
		color = 0xF00000,
	})
end)

--Updating huds

local hours = 0
local time = 0
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time >= 3600 then
		time = 0
		hours = hours + 1
	end

	local time_str = string.format(hours .."h ".."%dm %ds", math.floor(time / 60), math.floor(time % 60))

	for _,player in pairs(minetest.get_connected_players()) do
		--Match duration
		if hud:get(player, "match_duration_hud") then
			hud:change(player, "match_duration_hud", {
				text = "Match duration: " .. time_str
			})
		end
	end
end)

--Update Map HUD when a new match starts
ctf_modebase.register_on_new_match(function(mapdef, old_mapdef)
	for _,player in pairs(minetest.get_connected_players()) do
		if hud:get(player, "map_hud") then
			local map_HUD = "Map: " .. mapdef.name
			hud:change(player, "map_hud", {
				text = map_HUD
			})
		end
	end
	--reset the Match duration timer
	hours = 0
	time = 0
end)

--Updates the Mode HUD when a new mode starts
ctf_modebase.register_on_new_mode(function()
	for _,player in pairs(minetest.get_connected_players()) do
		if hud:get(player, "mode_hud") then
			local mode_HUD = "Mode: " .. ctf_modebase.current_mode
			hud:change(player, "mode_hud", {
				text = mode_HUD
			})
		end
	end
end)
