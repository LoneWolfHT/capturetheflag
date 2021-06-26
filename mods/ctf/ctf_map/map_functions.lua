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
	local pos1, pos2 = mapmeta.pos1, mapmeta.pos2

	for name, def in pairs(mapmeta.teams) do
		local p = def.flag_pos

		local node = minetest.get_node(p)

		if node.name ~= "ctf_modebase:flag" then
			minetest.log("error", name.."'s flag was set incorrectly, or there is no flag node placed")
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

	for _, object_drop in pairs(minetest.get_objects_in_area(pos1, pos2)) do
		local drop = object_drop:get_luaentity()
		if drop and drop.name == "__builtin:item" then
			if object_drop:is_player() then return end
			object_drop:remove()
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

	local vm = VoxelManip()
	pos1, pos2 = vm:read_from_map(pos1, pos2)

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

function ctf_map.place_chests(mapmeta, pos2, amount)
	local pos1 = mapmeta
	local pos_list

	if not pos2 then
		pos_list = mapmeta.chests
		pos1, pos2 = mapmeta.pos1, mapmeta.pos2
	else
		pos_list = {{pos1 = pos1, pos2 = pos2, amount = amount or ctf_map.DEFAULT_CHEST_AMOUNT}}
	end

	local vm = VoxelManip()
	pos1, pos2 = vm:read_from_map(pos1, pos2)

	local area = VoxelArea:new{MinEdge = pos1, MaxEdge = pos2}
	local data = vm:get_data()

	for _, a in pairs(pos_list) do
		local place_positions = {}
		local chest_node = minetest.get_content_id("ctf_map:chest")

		for z = a.pos1.z, a.pos2.z, (a.pos1.z <= a.pos2.z) and 1 or -1 do
			for y = a.pos1.y, a.pos2.y, (a.pos1.y <= a.pos2.y) and 1 or -1 do
				for x = a.pos1.x, a.pos2.x, (a.pos1.x <= a.pos2.x) and 1 or -1 do
					local vi = area:index(x, y, z)
					local id_below = data[area:index(x, y-1, z)]

					if data[vi] == minetest.CONTENT_AIR and
					id_below ~= minetest.CONTENT_AIR and id_below ~= minetest.CONTENT_IGNORE and
					data[area:index(x, y+1, z)] == minetest.CONTENT_AIR then
						table.insert(place_positions, vi)
					end
				end
			end
		end

		if place_positions and #place_positions > 1 then
			for i = 1, a.amount, 1 do
				local idx = math.random(1, #place_positions)

				data[place_positions[idx]] = chest_node

				table.remove(place_positions, idx)
			end
		else
			minetest.log("error", "Something went wrong with chest placement")
		end
	end

	vm:set_data(data)
	vm:update_liquids()
	vm:write_to_map(false)
end
