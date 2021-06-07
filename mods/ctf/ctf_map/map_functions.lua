function ctf_map.announce_map(map)
	local msg = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", map.name) ..
	minetest.colorize("#fcdb05", " by ") .. minetest.colorize("#f49200", map.author))
	if map.hint then
		msg = msg .. "\n" .. minetest.colorize("#f49200", map.hint)
	end
	minetest.chat_send_all(msg)
	if minetest.global_exists("irc") and irc.connected then
		irc:say("Map: " .. map.name)
	end
end

function ctf_map.place_map(idx, dirname, mapmeta)
	if not mapmeta then
		mapmeta = ctf_map.load_map_meta(idx, dirname)
	end

	local schempath = ctf_map.maps_dir .. dirname .. "/map.mts"
	local res = minetest.place_schematic(mapmeta.pos1, schempath)

	for name, def in pairs(mapmeta.teams) do
		local p = def.flag_pos

		local node = minetest.get_node(p)

		if node.name ~= "ctf_modebase:flag" then
			minetest.log("error", name.."'s flag was set incorrectly")
		else
			minetest.set_node(vector.offset(p, 0, 1, 0), {name="ctf_modebase:flag_top_"..name, param2 = node.param2})

			-- Place flag base if needed
			if tonumber(mapmeta.map_version or "0") < 2 then
				for x = -2, 2 do
					for z = -2, 2 do
						minetest.set_node(vector.offset(p, x, -1, z), {name = def.base_node or "ctf_map:cobble"})
					end
				end
			end
		end
	end

	assert(res, "Unable to place schematic, does the MTS file exist? Path: " .. schempath)

	ctf_map.current_map = mapmeta

	return mapmeta
end

-- Takes [mapmeta] or [pos1, pos2] arguments
function ctf_map.remove_barrier(mapmeta, pos2)
	local pos1 = mapmeta

	if not pos2 then
		pos1, pos2 = mapmeta.pos1, mapmeta.pos2
	end

	local vm = VoxelManip(pos1, pos2)
	local area = VoxelArea:new{MinEdge = pos1, MaxEdge = pos2}
	local data = vm:get_data()

	for z = pos1.z, pos2.z do
		for y = pos1.y, pos2.y do
			for x = pos1.x, pos2.x do
				local vi = area:index(x, y, z)

				for barriernode_id, replacement_id in pairs(ctf_map.barrier_nodes) do
					if data[vi] == barriernode_id then
						data[vi] = replacement_id
						break
					end
				end
			end
		end
	end

	vm:set_data(data)
	vm:update_liquids()
	vm:write_to_map(false)
end

local getpos_players = {}
function ctf_map.get_pos_from_player(name, amount, donefunc)
	getpos_players[name] = {amount = amount, func = donefunc, positions = {}}

	minetest.chat_send_player(name, "Please punch a node or run /ctf_map thispos to supply coordinates")
end

local function add_position(player, pos)
	pos = vector.round(pos)

	table.insert(getpos_players[player].positions, pos)
	minetest.chat_send_player(player, "Got pos "..minetest.pos_to_string(pos, 1))

	if getpos_players[player].amount > 1 then
		getpos_players[player].amount = getpos_players[player].amount - 1
	else
		minetest.chat_send_player(player, "Done getting positions!")
		getpos_players[player].func(player, getpos_players[player].positions)
		getpos_players[player] = nil
	end
end

ctf_map.register_map_command("thispos", function(name, params)
	local player = PlayerObj(name)

	if player then
		if getpos_players[name] then
			add_position(name, player:get_pos())
			return true
		else
			return false, "You aren't doing anything that requires coordinates"
		end
	end
end)

minetest.register_on_punchnode(function(pos, _, puncher)
	puncher = PlayerName(puncher)

	if getpos_players[puncher] then
		add_position(puncher, pos)
	end
end)

minetest.register_on_leaveplayer(function(player)
	getpos_players[PlayerName(player)] = nil
end)
