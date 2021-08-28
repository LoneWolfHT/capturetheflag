local voting = false
local voters = {}
local timer = 0

-- List of all maps placed during the current mode
local maps_placed = {}

local check_interval = 0
minetest.register_globalstep(function(dtime)
	if not voting then return end

	check_interval = check_interval + dtime

	if check_interval >= 3 then
		timer = timer - check_interval
		check_interval = 0
	else
		return
	end

	local votes = {_most = {c = 0}}

	for _, mode in pairs(ctf_modebase.modelist) do
		votes[mode] = 0
	end

	for pname, info in pairs(voters) do
		if not info.choice and timer > 0 then
			ctf_modebase.show_modechoose_form(pname)
		else
			votes[info.choice] = (votes[info.choice] or 0) + 1

			if votes[info.choice] > votes._most.c then
				votes._most.c = votes[info.choice]
				votes._most.n = info.choice
			end
		end
	end

	voting = false
	voters = {}

	local new_mode = votes._most.n or ctf_modebase.modelist[math.random(1, #ctf_modebase.modelist)]

	minetest.chat_send_all(string.format("Voting is over, '%s' won with %d votes!",
		HumanReadable(new_mode),
		votes._most.c or 0
	))

	ctf_modebase.start_new_match(nil, new_mode)
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	if voting then
		voters[name] = {choice = false, formname = ctf_modebase.show_modechoose_form(player)}
	end

	if ctf_modebase.current_mode and ctf_map.current_map then
		local map = ctf_map.current_map
		local mode_def = ctf_modebase:get_current_mode()
		skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

		physics.set(name, "ctf_modebase:map_physics", {
			speed = map.phys_speed,
			jump = map.phys_jump,
			gravity = map.phys_gravity,
		})

		if mode_def.physics then
			player:set_physics_override({
				sneak_glitch = mode_def.physics.sneak_glitch or false,
				new_move = mode_def.physics.new_move or true
			})
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	if voting then
		voters[player:get_player_name()] = nil
	end
end)

function ctf_modebase.start_mode_vote()
	voters = {}

	for _, player in pairs(minetest.get_connected_players()) do
		voters[player:get_player_name()] = {choice = false, formname = ctf_modebase.show_modechoose_form(player)}
	end

	timer = ctf_modebase.VOTING_TIME
	voting = true
end


function ctf_modebase.start_new_match(show_form, new_mode, specific_map)
	local old_map = ctf_map.current_map
	local old_mode = ctf_modebase.current_mode

	local function start_new_match()
		for _, pos in pairs(ctf_teams.team_chests) do
			minetest.remove_node(pos)
		end
		ctf_teams.team_chests = {}

		if new_mode and new_mode ~= old_mode then
			maps_placed = {}
		end

		if new_mode then
			if old_mode and ctf_modebase.modes[old_mode].on_mode_end then
				ctf_modebase.modes[old_mode].on_mode_end()
			end

			ctf_modebase.current_mode = new_mode
			RunCallbacks(ctf_modebase.registered_on_new_mode, new_mode, old_mode)
		end

		ctf_modebase.place_map(new_mode or ctf_modebase.current_mode, specific_map, function(map)
			give_initial_stuff.reset_stuff_providers()

			RunCallbacks(ctf_modebase.registered_on_new_match, map, old_map)

			if map.initial_stuff then
				give_initial_stuff.register_stuff_provider(function()
					return map.initial_stuff
				end)
			end

			ctf_teams.allocate_teams(map.teams)

			ctf_modebase.current_mode_matches = ctf_modebase.current_mode_matches + 1
		end)
	end

	-- Show mode selection form every 'ctf_modebase.MAPS_PER_MODE'-th match
	if ctf_modebase.current_mode_matches >= ctf_modebase.MAPS_PER_MODE or show_form then
		ctf_modebase.current_mode_matches = 0

		ctf_modebase.start_mode_vote()
	else
		start_new_match()
	end
end

function ctf_modebase.show_modechoose_form(player)
	local elements = {}
	local idx = 0

	for modename, def in pairs(ctf_modebase.modes) do
		elements[modename] = {
			type = "button",
			label = HumanReadable(modename),
			exit = true,
			pos = {"center", idx},
			func = function(playername, fields, field_name)
				if voting then
					if ctf_modebase.modes[modename] then
						voters[playername].choice = modename
						minetest.chat_send_all(string.format("%s voted for the mode '%s'", playername, HumanReadable(modename)))
					else
						ctf_modebase.show_modechoose_form(player)
					end
				end
			end,
		}

		idx = idx + 1
	end

	ctf_gui.show_formspec(player, "ctf_modebase:mode_select", {
		size = {x = 8, y = 8},
		title = "Mode Selection",
		description = "Please vote on what gamemode you would like to play",
		on_quit = function(pname)
			if voting then
				minetest.after(0.1, function()
					if voting and voters[pname] and not voters[pname].choice then
						ctf_modebase.show_modechoose_form(pname)
					end
				end)
			end
		end,
		elements = elements,
	})

	return "ctf_modebase:mode_select"
end

--- @param mode_def table | string
function ctf_modebase.place_map(mode_def, mapidx, callback)
	-- Convert name of mode into it's def
	if type(mode_def) == "string" then
		mode_def = ctf_modebase.modes[mode_def]
	end

	local dirlist = minetest.get_dir_list(ctf_map.maps_dir, true)

	if not mapidx then
		local map_pool = mode_def.map_whitelist or dirlist
		local new_pool = {}

		if #maps_placed >= #map_pool then
			maps_placed = {}
		end

		for _, name in pairs(map_pool) do
			if table.indexof(maps_placed, name) == -1 then
				table.insert(new_pool, name)
			end
		end

		mapidx = table.indexof(dirlist, new_pool[math.random(1, #new_pool)])
	elseif type(mapidx) ~= "number" then
		mapidx = table.indexof(dirlist, mapidx)
	end

	ctf_map.place_map(mapidx, dirlist[mapidx], function(map)
		table.insert(maps_placed, dirlist[mapidx])

		-- Set time, time_speed, skyboxes, and physics

		minetest.set_timeofday(map.start_time/24000)

		for _, player in pairs(minetest.get_connected_players()) do
			local name = PlayerName(player)

			skybox.set(player, table.indexof(ctf_map.skyboxes, map.skybox)-1)

			physics.set(name, "ctf_modebase:map_physics", {
				speed = map.phys_speed,
				jump = map.phys_jump,
				gravity = map.phys_gravity,
			})

			if mode_def.physics then
				player:set_physics_override({
					sneak_glitch = mode_def.physics.sneak_glitch or false,
					new_move = mode_def.physics.new_move or true
				})
			end

			minetest.settings:set("time_speed", map.time_speed * 72)
		end

		ctf_map.announce_map(map)

		callback(map)
	end)
end
