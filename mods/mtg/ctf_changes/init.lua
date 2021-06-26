local DISALLOW_MOD_ABMS = {"default", "fire", "flowers", "tnt"}

minetest.register_on_mods_loaded(function()

	-- Remove Unneeded ABMs

	local remove_list = {}

	for key, abm in pairs(minetest.registered_abms) do
		for _, mod in pairs(DISALLOW_MOD_ABMS) do
			if abm.mod_origin == mod then
				table.insert(remove_list, key)
				break
			end
		end
	end

	local removed = 0
	for _, key in pairs(remove_list) do
		table.remove(minetest.registered_abms, key - removed)
		removed = removed + 1
	end

	-- Unset falling group for all nodes

	for name, def in pairs(minetest.registered_nodes) do
		if def.groups then
			def.groups.falling_node = nil
			minetest.override_item(name, {groups = def.groups})
		end

		if name:find("fire:") and def.on_timer then
			def.on_timer = nil
		end
	end

	-- Set item type and tiers for give_initial_stuff
	local tiers = {"wood", "stone", "steel", "mese", "diamond"}
	local tool_categories = {"pickaxe", "shovel", "axe"}
	local other_categories = {sword = "melee", ranged = "ranged", healing = "healing"}
	for name, def in pairs(minetest.registered_tools) do
		local new_category = nil

		for _, tcat in pairs(tool_categories) do
			if def.groups[tcat] then
				new_category = tcat
				def.groups.tool = 1
				break
			end
		end

		for group, ocat in pairs(other_categories) do
			if def.groups[group] then
				new_category = ocat
				break
			end
		end

		if def.groups.tool or def.groups.sword then
			for tier, needle in pairs(tiers) do
				if name:match(needle) then
					def.groups.tier = tier
					break
				end
			end
		end

		minetest.override_item(name, {groups = def.groups, _g_category = new_category})
	end
end)

--mushroom
minetest.register_node(":flowers:mushroom_red", {
	description = "Red Mushroom",
	tiles = {"flowers_mushroom_red.png"},
	inventory_image = "flowers_mushroom_red.png",
	wield_image = "flowers_mushroom_red.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {mushroom = 1, snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	on_use = nil,
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, -1 / 16, 4 / 16},
	}
})

minetest.register_node(":flowers:mushroom_brown", {
	description = "Brown Mushroom",
	tiles = {"flowers_mushroom_brown.png"},
	inventory_image = "flowers_mushroom_brown.png",
	wield_image = "flowers_mushroom_brown.png",
	drawtype = "plantlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {mushroom = 1, food_mushroom = 1, snappy = 3, attached_node = 1, flammable = 1},
	sounds = default.node_sound_leaves_defaults(),
	on_use = nil,
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, -2 / 16, 3 / 16},
	}
})
