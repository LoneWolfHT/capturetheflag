doors.register("ctf_teams:door_steel", {
	tiles = {{name = "doors_door_steel.png", backface_culling = true}},
	description = "Team Door",
	inventory_image = "doors_item_steel.png",
	groups = {node = 1, cracky = 1, level = 2},
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	gain_open = 0.2,
	gain_close = 0.2,
})

local old_on_place = minetest.registered_craftitems["ctf_teams:door_steel"].on_place
minetest.override_item("ctf_teams:door_steel", {
	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer)

		if pteam then
			local pos1, pos2 = ctf_teams.get_team_territory(pteam)

			if not ctf_core.area_contains(pos1, pos2, pointed_thing.above) then
				minetest.chat_send_player(placer:get_player_name(), "You can only place team doors in your own territory!")
				return itemstack
			end

			local newitemstack = ItemStack("ctf_teams:door_steel_"..pteam)
			newitemstack:set_count(itemstack:get_count())

			itemstack:set_count(old_on_place(newitemstack, placer, pointed_thing):get_count())

			return itemstack
		end

		return old_on_place(itemstack, placer, pointed_thing)
	end
})

local old_handle = minetest.handle_node_drops
minetest.handle_node_drops = function(pos, drops, digger)
	if drops and drops[1]:match("ctf_teams:door_steel_") then
		return old_handle(pos, {"ctf_teams:door_steel"}, digger)
	end

	return old_handle(pos, drops, digger)
end

for team, def in pairs(ctf_teams.team) do
	local doorname = "ctf_teams:door_steel_%s"
	local modifier = "^[colorize:%s:190)^(ctf_teams_door_steel.png^[mask:ctf_teams_door_steel_mask.png^[colorize:%s:42)"

	doors.register(doorname:format(team), {
		tiles = {{name = "(ctf_teams_door_steel.png"..modifier:format(def.color, def.color), backface_culling = true}},
		description = "Steel Team Door",
		inventory_image = "doors_item_steel.png^[multiply:"..def.color,
		groups = {node = 1, cracky = 1, level = 2},
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_steel_door_open",
		sound_close = "doors_steel_door_close",
		gain_open = 0.2,
		gain_close = 0.2,
	})
end

local old_func = default.can_interact_with_node
default.can_interact_with_node = function(player, pos)
	local pteam = ctf_teams.get(player)

	if pteam then
		if pteam == minetest.get_node(pos).name:match("ctf_teams:door_steel_(.-)[_$]") then
			return true
		else
			return false
		end
	end

	return old_func(player, pos)
end
