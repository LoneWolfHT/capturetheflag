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

--leaves
minetest.register_node(":default:leaves", {
	description = "Apple Tree Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"default_leaves.png"},
	special_tiles = {"default_leaves_simple.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = after_place_leaves,
})

minetest.register_node(":default:jungleleaves", {
	description = "Jungle Tree Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"default_jungleleaves.png"},
	special_tiles = {"default_jungleleaves_simple.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = after_place_leaves,
})

minetest.register_node(":default:acacia_leaves", {
	description = "Acacia Tree Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_acacia_leaves.png"},
	special_tiles = {"default_acacia_leaves_simple.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = after_place_leaves,
})

minetest.register_node(":default:aspen_leaves", {
	description = "Aspen Tree Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_aspen_leaves.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = after_place_leaves,
})

minetest.register_node(":default:bush_leaves", {
	description = "Bush Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_leaves_simple.png"},
	paramtype = "light",
	groups = {snappy = 3, flammable = 2, leaves = 1},
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = after_place_leaves,
})

minetest.register_node(":default:blueberry_bush_leaves", {
	description = "Blueberry Bush Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_blueberry_bush_leaves.png"},
	paramtype = "light",
	groups = {snappy = 3, flammable = 2, leaves = 1},
	drop = "default:blueberry_bush_leaves",
	sounds = default.node_sound_leaves_defaults(),
	on_timer = function(pos, elapsed)
		if minetest.get_node_light(pos) < 11 then
			minetest.get_node_timer(pos):start(200)
		else
			minetest.set_node(pos, {name = "default:blueberry_bush_leaves_with_berries"})
		end
	end,

	after_place_node = after_place_leaves,
})

minetest.register_node(":default:acacia_bush_leaves", {
	description = "Acacia Bush Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_acacia_leaves_simple.png"},
	paramtype = "light",
	groups = {snappy = 3, flammable = 2, leaves = 1},
	drop = "default:acacia_bush_leaves",
	sounds = default.node_sound_leaves_defaults(),

	after_place_node = after_place_leaves,
})
