local CURRENT_MAP_VERSION = "2"

function ctf_map.load_map_meta(idx, dirname)
	local meta = Settings(ctf_map.maps_dir .. dirname .. "/map.conf")

	if not meta then error("Map '"..dump(dirname).."' not found") end

	minetest.log("info", "load_map_meta: Loading map meta from '" .. dirname .. "/map.conf'")

	local map
	local offset = vector.new(600 * idx, 0, 0)

	if not meta:get("map_version") then
		if not meta:get("r") then
			error("Map was not properly configured: " .. ctf_map.maps_dir .. dirname .. "/map.conf")
		end

		local mapr = meta:get("r")
		local maph = meta:get("h")
		local start_time = meta:get("start_time")
		local time_speed = meta:get("time_speed")
		local initial_stuff = meta:get("initial_stuff")
		local treasures = meta:get("treasures")

		local pos1 = vector.add(offset, { x = -mapr, y = -maph / 2, z = -mapr })
		local pos2 = vector.add(offset, { x =  mapr, y =  maph / 2, z =  mapr })

		map = {
			pos1          = pos1,
			pos2          = pos2,
			offset        = offset,
			size          = vector.subtract(pos2, pos1),
			enabled       = not meta:get("disabled", false),
			dirname       = dirname,
			name          = meta:get("name"),
			author        = meta:get("author"),
			hint          = meta:get("hint"),
			license       = meta:get("license"),
			others        = meta:get("others"),
			base_node     = meta:get("base_node"),
			initial_stuff = initial_stuff and initial_stuff:split(","),
			treasures     = treasures and treasures:split(";"),
			skybox        = "none",
			start_time    = start_time and tonumber(start_time) or ctf_map.DEFAULT_START_TIME,
			time_speed    = time_speed and tonumber(time_speed) or 1,
			phys_speed    = tonumber(meta:get("phys_speed")),
			phys_jump     = tonumber(meta:get("phys_jump")),
			phys_gravity  = tonumber(meta:get("phys_gravity")),
			chests        = {},
			teams         = {},
		}

		-- Read teams from config
		local i = 1
		while meta:get("team." .. i) do
			local tname  = meta:get("team." .. i)
			local tpos   = minetest.string_to_pos(meta:get("team." .. i .. ".pos"))

			map.teams[tname] = {
				enabled = true,
				base_pos = vector.add(offset, tpos),
			}

			i = i + 1
		end

		-- Read custom chest zones from config
		i = 1
		minetest.log("verbose", "Parsing chest zones of " .. map.name .. "...")
		while meta:get("chests." .. i .. ".from") do
			local from  = minetest.string_to_pos(meta:get("chests." .. i .. ".from"))
			local to    = minetest.string_to_pos(meta:get("chests." .. i .. ".to"))
			assert(from and to, "Positions needed for chest zone " ..
					i .. " in map " .. map.name)

			from, to = vector.sort(from, to)

			map.chests[i] = {
				pos1   = from,
				pos2   = to,
				amount = tonumber(meta:get("chests." .. i .. ".n") or "20"),
			}

			i = i + 1
		end

		-- Add default chest zones if none given
		if i == 1 then
			while meta:get("team." .. i) do
				local chests1
				if i == 1 then
					chests1 = vector.add(offset, { x = -mapr, y = -maph / 2, z = 0 })
				elseif i == 2 then
					chests1 = map.pos1
				end

				local chests2
				if i == 1 then
					chests2 = map.pos2
				elseif i == 2 then
					chests2 = vector.add(offset, { x = mapr, y = maph / 2, z = 0 })
				end

				map.chests[i] = {
					pos1 = chests1,
					pos2 = chests2,
					amount = ctf_map.DEFAULT_CHEST_AMOUNT,
				}
				i = i + 1
			end
		end
	elseif meta:get("map_version") == CURRENT_MAP_VERSION then
		-- If new items are added also remember to change the table in mapedit_gui.lua
		-- You should also update the version number too
		local size = minetest.deserialize(meta:get("size"))

		offset.y = -size.y

		map = {
			pos1          = offset,
			pos2          = vector.add(offset, size),
			offset        = offset,
			size          = size,
			dirname       = dirname,
			enabled       = meta:get("enabled"),
			name          = meta:get("name"),
			author        = meta:get("author"),
			hint          = meta:get("hint"),
			license       = meta:get("license"),
			others        = meta:get("others"),
			base_node     = meta:get("base_node"),
			initial_stuff = minetest.deserialize(meta:get("initial_stuff")),
			treasures     = minetest.deserialize(meta:get("treasures")),
			skybox        = meta:get("skybox"),
			start_time    = meta:get("start_time"),
			time_speed    = tonumber(meta:get("time_speed")),
			phys_speed    = tonumber(meta:get("phys_speed")),
			phys_jump     = tonumber(meta:get("phys_jump")),
			phys_gravity  = tonumber(meta:get("phys_gravity")),
			chests        = minetest.deserialize(meta:get("chests")),
			teams         = minetest.deserialize(meta:get("teams")),
		}

		for id, def in pairs(map.chests) do
			map.chests[id].pos1 = vector.add(offset, def.pos1)
			map.chests[id].pos2 = vector.add(offset, def.pos2)
		end

		for id, def in pairs(map.teams) do
			map.teams[id].base_pos = vector.add(offset, def.base_pos)
		end
	end

	minetest.log(dump(map))
	return map
end

function ctf_map.save_map(mapmeta)
	local path = minetest.get_worldpath() .. "/schems/" .. mapmeta.dirname .. "/"
	minetest.mkdir(path)

	minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Saving Map..."))

	-- Write to .conf
	local meta = Settings(path .. "map.conf")

	mapmeta.pos1, mapmeta.pos2 = vector.sort(mapmeta.pos1, mapmeta.pos2)

	for id, def in pairs(mapmeta.chests) do
		def.pos1, def.pos2 = vector.sort(def.pos1, def.pos2)

		mapmeta.chests[id].pos1 = vector.subtract(def.pos1, mapmeta.offset)
		mapmeta.chests[id].pos2 = vector.subtract(def.pos2, mapmeta.offset)
	end

	for id, def in pairs(mapmeta.teams) do
		mapmeta.teams[id].base_pos = vector.subtract(def.base_pos, mapmeta.offset)
	end

	-- Remove teams from the list if not enabled
	for name, def in pairs(mapmeta.teams) do
		if not def.enabled then
			mapmeta.teams[name] = nil
		end
	end

	meta:set("map_version"  , CURRENT_MAP_VERSION)
	meta:set("size"         , minetest.serialize(vector.subtract(mapmeta.pos2, mapmeta.pos1)))
	meta:set("enabled"      , mapmeta.enabled and "true" or "false")
	meta:set("name"         , mapmeta.name)
	meta:set("author"       , mapmeta.author)
	meta:set("hint"         , mapmeta.hint)
	meta:set("license"      , mapmeta.license)
	meta:set("others"       , mapmeta.others)
	meta:set("base_node"    , mapmeta.base_node)
	meta:set("initial_stuff", minetest.serialize(mapmeta.initial_stuff))
	meta:set("treasures"    , minetest.serialize(mapmeta.treasures))
	meta:set("skybox"       , mapmeta.skybox)
	meta:set("start_time"   , mapmeta.start_time)
	meta:set("time_speed"   , mapmeta.time_speed)
	meta:set("phys_speed"   , mapmeta.phys_speed)
	meta:set("phys_jump"    , mapmeta.phys_jump)
	meta:set("phys_gravity" , mapmeta.phys_gravity)
	meta:set("chests"       , minetest.serialize(mapmeta.chests))
	meta:set("teams"        , minetest.serialize(mapmeta.teams))

	meta:write()

	minetest.after(0.1, function()
		local filepath = path .. "map.mts"
		if minetest.create_schematic(mapmeta.pos1, mapmeta.pos2, nil, filepath) then
			minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Saved Map '" .. mapmeta.name .. "' to " .. path))
		else
			minetest.chat_send_all(minetest.colorize(ctf_map.CHAT_COLOR, "Map Saving Failed!"))
		end
	end)
end