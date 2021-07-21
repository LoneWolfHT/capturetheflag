local function set_max_hp(player, max_hp)
	local cur_hp = player:get_hp()
	local old_max = player:get_properties().hp_max

	if old_max == 0 then
		minetest.log("error", "[ctf_classes] Reviving dead player " .. player:get_player_name())
	end

	player:set_properties({hp_max = max_hp})

	local new_hp = cur_hp + max_hp - old_max
	if new_hp > max_hp then
		minetest.log("error", string.format("New hp %d is larger than new max %d, old max is %d", new_hp, max_hp, old_max))
		new_hp = max_hp
	end

	if cur_hp > max_hp then
		player:set_hp(max_hp)
	elseif new_hp > cur_hp then
		player:set_hp(new_hp)
	end
end

function mode_class.set_player_class(player, new_class)
	local old_class = mode_class.player_class[player] --get current class

	if not mode_class.class[cname] == new_class then return "Class doesn't exist" end

	if new_class == old_class then
		return "You are already in class " .. old_class .. "."
	else

		mode_class.player_class[player] = new_class

		mode_class.update_class(player)
		give_initial_stuff(player)

	end
end

function mode_class.update_class(player)
	local name = player:get_player_name()

	local class = mode_class.player_class[player]
	local tcolor = ctf_teams.team[ctf_teams.get(name)].color

	set_max_hp(player, mode_class.class[class].properties.max_hp)
	player:set_properties({
		textures = {"mode_class_" .. class .. "_skin.png^(mode_class_" .. class .. "_skin.png^[mask:mode_class_" .. class .. "_skin_mask.png^[colorize:" .. tcolor .. ":230)"}
	})

	physics.set(player:get_player_name(), "mode_class:physics", {
		speed = mode_class.class[class].properties.speed,
		jump = mode_class.class[class].properties.jump,
		gravity = mode_class.class[class].properties.gravity,
	})

	crafting.lock_all(player:get_player_name())
	for i=1, #(mode_class.class[class].properties.crafting or {}) do
		crafting.unlock(player:get_player_name(), mode_class.class[class].properties.crafting[i])
	end
end

ctf_modebase.register_chatcommand("classes", "class", {
	description = "change class",
	params = "[classname]",
	func = function(name, param)
		mode_class.set_player_class(minetest.get_player_by_name(name), param)
	end
})

--Knight's sword

local sword_special_timer = {}
local SWORD_SPECIAL_COOLDOWN = 20
local function sword_special_timer_func(pname, timeleft)
	sword_special_timer[pname] = timeleft

	if timeleft - 2 >= 0 then
		minetest.after(2, sword_special_timer_func, pname, timeleft - 2)
	else
		sword_special_timer[pname] = nil
	end
end

--Melee bonus
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type ~= "punch" or not reason.object or not reason.object:is_player() then
		return hp_change
	end

	local pclass = mode_class.player_class[reason.object]

	if mode_class.class[pclass].properties.melee_bonus and reason.object:get_wielded_item():get_name():find("sword") then
		local change = hp_change - mode_class.class[pclass].properties.melee_bonus

		if player:get_hp() + change <= 0 and player:get_hp() + hp_change > 0 then
			local wielded_item = reason.object:get_wielded_item()
		end

		return change
	end

	return hp_change
end, true)

--Disallow dropping class items

local function stack_list_to_map(stacks)
	local map = {}
	for i = 1, #stacks do
		map[ItemStack(stacks[i]):get_name()] = true
	end
	return map
end

local function is_class_blacklisted(player, itemname)
	local pclass = mode_class.player_class[player]
	
	if mode_class.class[pclass].properties.item_blacklist then
		local items = stack_list_to_map(mode_class.class[pclass].properties.item_blacklist)
		return items[itemname]
	end
end

local old_item_drop = minetest.item_drop
minetest.item_drop = function(itemstack, player, pos)
	if is_class_blacklisted(player, itemstack:get_name()) then
		minetest.chat_send_player(player:get_player_name(),
			"You're not allowed to drop class items!")
		return itemstack
	else
		return old_item_drop(itemstack, player, pos)
	end
end

minetest.register_tool("ctf_mode_classes:sword_bronze", {
	description = "Knight's Sword\nSneak+Rightclick items/air to place marker\nRightclick enemies to place marker listing all enemies in area",
	inventory_image = "default_tool_bronzesword.png",
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=6, sword=1},
		punch_attack_uses = 0,
	},
	groups = {tier = 2},
	sound = {breaks = "default_tool_breaks"},
	on_place = function(itemstack, placer, pointed_thing)
		local pname = placer:get_player_name()
		if not pointed_thing then return end

		if sword_special_timer[pname] and placer:get_player_control().sneak then
			minetest.chat_send_player(pname, "You have to wait "..sword_special_timer[pname].."s to place marker again")

			if pointed_thing.type == "node" then
				return minetest.item_place(itemstack, placer, pointed_thing)
			else
				return
			end
		end

		local pteam = ctf_teams.get(pname)

		if not pteam then -- can be nil during map change
			return
		end

		if pointed_thing.type == "object" and pointed_thing.ref:is_player() then

			local enemies = {}
			local pos = pointed_thing.ref:get_pos()

			sword_special_timer[pname] = SWORD_SPECIAL_COOLDOWN
			sword_special_timer_func(pname, SWORD_SPECIAL_COOLDOWN)

			for _, p in pairs(minetest.get_connected_players()) do
				local name = p:get_player_name()

				if pteam ~= ctf_teams.get(name) and
				vector.distance(p:get_pos(), pos) <= 10 then
					table.insert(enemies, name)
				end
			end

			if #enemies > 0 then
				ctf_modebase.remove_marker(pteam)
				ctf_modebase.add_marker(pteam, (" found enemies: <%s>]"):format(table.concat(enemies, ", ")), pos)
			end

			return
		end

		if pointed_thing.type == "node" then
			return minetest.item_place(itemstack, placer, pointed_thing)
		end

		-- Check if player is sneaking before placing marker
		if not placer:get_player_control().sneak then return end

		sword_special_timer[pname] = 4
		sword_special_timer_func(pname, 4)

		minetest.registered_chatcommands["m"].func(pname, "placed with sword")
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing then
			minetest.registered_tools["ctf_mode_classes:sword_bronze"].on_place(itemstack, user, pointed_thing)
		end
	end,
})
