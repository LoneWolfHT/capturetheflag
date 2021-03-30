-- default/torch.lua

-- support for MT game translation.
local S = default.get_translator

local function on_flood(pos, oldnode, newnode)
	minetest.add_item(pos, ItemStack("default:torch 1"))
	-- Play flame-extinguish sound if liquid is not an 'igniter'
	local nodedef = minetest.registered_items[newnode.name]
	if not (nodedef and nodedef.groups and
			nodedef.groups.igniter and nodedef.groups.igniter > 0) then
		minetest.sound_play(
			"default_cool_lava",
			{pos = pos, max_hear_distance = 16, gain = 0.1},
			true
		)
	end
	-- Remove the torch node
	return false
end

function default.register_torch(name, defs)
	local def = defs.floor
	local ceiling = name .. "_ceiling"
	local wall = name .. "_wall"
	local lookup = {[0] = ceiling, name, wall, wall, wall, wall}
	def.on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local nodedef = minetest.registered_nodes[node.name]
		if nodedef and nodedef.on_rightclick and
			not (placer and placer:is_player() and
			placer:get_player_control().sneak) then
			return nodedef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		local above = pointed_thing.above
		local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
		itemstack:set_name(lookup[wdir])
		itemstack = minetest.item_place(itemstack, placer, pointed_thing, wdir)
		itemstack:set_name(name)
		return itemstack
	end
	minetest.register_node(":" .. name, def)

	local def_ceiling = table.copy(def)
	for key, value in pairs(defs.ceiling) do
		def_ceiling[key] = value
	end

	def_ceiling.groups.not_in_creative_inventory = 1
	minetest.register_node(":" .. ceiling, def_ceiling)

	local def_wall = table.copy(def)
	for key, value in pairs(defs.wall) do
		def_wall[key] = value
	end

	def_wall.groups.not_in_creative_inventory    = 1
	minetest.register_node(":" .. wall, def_wall)
end

default.torch = {
	floor = {
		description = S("Torch"),
		drawtype = "mesh",
		mesh = "torch_floor.obj",
		inventory_image = "default_torch_on_floor.png",
		wield_image = "default_torch_on_floor.png",
		tiles = {{
				name = "default_torch_on_floor_animated.png",
				animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
		}},
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		liquids_pointable = false,
		light_source = 12,
		groups = {choppy=2, dig_immediate=3, flammable=1, attached_node=1, torch=1},
		drop = "default:torch",
		selection_box = {
			type = "wallmounted",
			wall_bottom = {-1/8, -1/2, -1/8, 1/8, 2/16, 1/8},
		},
		sounds = default.node_sound_wood_defaults(),
		floodable = true,
		on_flood = on_flood,
	},
	ceiling = {
		mesh = "torch_ceiling.obj",
		selection_box = {
			type = "wallmounted",
			wall_top = {-1/8, -1/16, -5/16, 1/8, 1/2, 1/8},
		},
	},
	wall = {
		mesh = "torch_wall.obj",
		selection_box = {
			type = "wallmounted",
			wall_side = {-1/2, -1/2, -1/8, -1/8, 1/8, 1/8},
		},
	},
}
default.register_torch("default:torch", default.torch)

minetest.register_lbm({
	name = "default:3dtorch",
	nodenames = {"default:torch", "torches:floor", "torches:wall"},
	action = function(pos, node)
		if node.param2 == 0 then
			minetest.set_node(pos, {name = "default:torch_ceiling",
				param2 = node.param2})
		elseif node.param2 == 1 then
			minetest.set_node(pos, {name = "default:torch",
				param2 = node.param2})
		else
			minetest.set_node(pos, {name = "default:torch_wall",
				param2 = node.param2})
		end
	end
})

minetest.register_craft({
	output = "default:torch 4",
	recipe = {
		{"default:coal_lump"},
		{"group:stick"},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:torch",
	burntime = 4,
})
