function ctf_modebase.update_crafts(name)
	crafting.lock_all(name)
	for i=1, #(ctf_modebase.modes[ctf_modebase.current_mode].crafts or {}) do
		crafting.unlock(name, ctf_modebase.modes[ctf_modebase.current_mode].crafts[i])
	end
end

ctf_modebase.register_on_new_mode(function()
	for _, player in pairs(minetest.get_connected_players()) do
		ctf_modebase.update_crafts(player:get_player_name())
	end
end)

local full_ores = {
	diamond = "default:diamond",
	mese = "default:mese_crystal",
	steel = "default:steel_ingot",
	stone = "default:cobble",
}

local sword_materials = {
	steel   = "default:steel_ingot",
	mese    = "default:mese_crystal",
	diamond = "default:diamond",
}

-- Swords
for material, craft_material in pairs(sword_materials) do
	crafting.register_recipe({
		type   = "inv",
		output = "ctf_melee:sword_" .. material,
		items  = { "default:stick", craft_material .. " 2" },
		always_known = true,
		level  = 1,
	})
end

-- Pickaxes
for ore, ore_item in pairs(full_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:pick_" .. ore,
		items  = { "default:stick 2", ore_item .. " 3" },
		always_known = true,
		level  = 1,
	})
end

-- Mese crystal x9 <== Mese block
crafting.register_recipe({
	type   = "inv",
	output = "default:mese_crystal 9",
	items  = { "default:mese"},
	always_known = true,
	level  = 1,
})

-- Furnace <== group:stone x8
crafting.register_recipe({
	type   = "inv",
	output = "default:furnace",
	items  = { "group:stone 8" },
	always_known = true,
	level  = 1,
})

-- Team door
crafting.register_recipe({
	type   = "inv",
	output = "ctf_map:team_door",
	items  = { "default:steel_ingot 6" },
	always_known = true,
	level  = 1,
})

-- Wood x4
crafting.register_recipe({
	type   = "inv",
	output = "default:wood 4",
	items  = { "group:tree" },
	always_known = true,
	level  = 1,
})

-- Stick x4
crafting.register_recipe({
	type   = "inv",
	output = "default:stick 4",
	items  = { "group:wood" },
	always_known = true,
	level  = 1,
})

-- Torch x5
crafting.register_recipe({
	type   = "inv",
	output = "default:torch 5",
	items  = { "default:stick", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

-- Ammo <== Tin ingot x3 + Coal lump x2
crafting.register_recipe({
	type   = "inv",
	output = "shooter:ammo",
	items  = { "default:tin_ingot 2", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

-- Ammo <== Steel ingot x3 + Coal lump x2
crafting.register_recipe({
	type   = "inv",
	output = "shooter:ammo 2",
	items  = { "default:steel_ingot 2", "default:coal_lump 2" },
	always_known = true,
	level  = 1,
})

-- Wooden ladder x4
crafting.register_recipe({
	type   = "inv",
	output = "default:ladder 4",
	items  = { "default:stick 8" },
	always_known = true,
	level  = 1,
})

-- Stick x2 <== Wooden ladder
crafting.register_recipe({
	type   = "inv",
	output = "default:stick 2",
	items  = { "default:ladder" },
	always_known = true,
	level  = 1,
})

-- Shovels
for ore, ore_item in pairs(full_ores) do
	local show = true
	if ore == "diamond" or ore == "mese" or ore == "bronze" then
		show = false
	end

	crafting.register_recipe({
		type   = "inv",
		output = "default:shovel_" .. ore,
		items  = { "default:stick 2", ore_item },
		always_known = show,
		level  = 1,
	})
end

-- Axes
for ore, ore_item in pairs(full_ores) do
	local show = true
	if ore == "diamond" or ore == "mese" or ore == "bronze" then
		show = false
	end

	crafting.register_recipe({
		type   = "inv",
		output = "default:axe_" .. ore,
		items  = { "default:stick 2", ore_item},
		always_known = show,
		level  = 1,
	})
end
