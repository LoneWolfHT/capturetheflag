local cooldowns = ctf_core.init_cooldowns()
local CLASS_SWITCH_COOLDOWN = 30

local classes = {
	knight = {
		name = "Knight",
		hp_max = 30,
		visual_size = vector.new(1.1, 1, 1.1),
		items = {
			"ctf_mode_classes:knight_sword",
		}
	},
	support = {
		name = "Support",
		items = {
			"ctf_healing:bandage",
			"ctf_mode_classes:support_paxel",
			"default:cobble 99",
		}
	},
	ranged = {
		name = "Ranged",
		hp_max = 10,
		visual_size = vector.new(0.9, 1, 0.9),
		items = {
			"ctf_mode_classes:ranged_rifle_loaded",
		}
	}
}

local UPDATE_STEP = 2
local function update_wear(pname, item, cooldown_time, time_passed, down)
	minetest.after(UPDATE_STEP, function()
		time_passed = time_passed + UPDATE_STEP

		local player = minetest.get_player_by_name(pname)

		if player then
			local pinv = player:get_inventory()
			local found = false

			for pos, stack in pairs(pinv:get_list("main")) do
				if stack:get_name() == item then
					if down then
						stack:set_wear((65535 / cooldown_time) * time_passed)
					else
						stack:set_wear((65535 / cooldown_time) * (cooldown_time - time_passed))
					end

					pinv:set_stack("main", pos, stack)

					if time_passed == cooldown_time then
						return
					else
						found = true
						break
					end
				end
			end

			if found then
				update_wear(pname, item, cooldown_time, time_passed, down)
			end
		end
	end)
end

--
--- Knight Sword
--

local KNIGHT_COOLDOWN_TIME = 40
local KNIGHT_USAGE_TIME = 12

ctf_melee.simple_register_sword("ctf_mode_classes:knight_sword", {
	description = "Knight Sword\nRightclick to use Rage ability (Lasts "..
			KNIGHT_USAGE_TIME.."s, "..KNIGHT_COOLDOWN_TIME.."s cooldown)",
	inventory_image = "default_tool_bronzesword.png",
	damage_groups = {fleshy = 7},
	full_punch_interval = 0.7,
	rightclick_func = function(itemstack, user, pointed)
		local pname = user:get_player_name()
		local pointed_nodedef = {}

		if pointed and pointed.type == "node" then
			pointed_nodedef = minetest.registered_nodes[minetest.get_node(pointed.under).name]
		end

		if (not pointed or not pointed_nodedef.on_rightclick) and itemstack:get_wear() == 0 then
			minetest.after(KNIGHT_USAGE_TIME, function()
				local player = minetest.get_player_by_name(pname)

				if player then
					local pinv = player:get_inventory()

					for pos, stack in pairs(pinv:get_list("main")) do
						if stack:get_name() == "ctf_melee:sword_diamond" then
							local newstack = ItemStack("ctf_mode_classes:knight_sword")

							newstack:set_wear(65534)
							pinv:set_stack("main", pos, newstack)

							update_wear(pname, "ctf_mode_classes:knight_sword", KNIGHT_COOLDOWN_TIME, 0)
							break
						end
					end
				end
			end)

			minetest.after(0, user.set_wielded_item, user, "ctf_melee:sword_diamond")
			update_wear(pname, "ctf_melee:sword_diamond", KNIGHT_USAGE_TIME, 0, true)
		end

		minetest.item_place(itemstack, user, pointed)
	end,
})

--
--- Ranged Gun
--

local RANGED_COOLDOWN_TIME = 20

ctf_ranged.simple_register_gun("ctf_mode_classes:ranged_rifle", {
	type = "rifle",
	description = "Rifle\nRightclick to launch grenade ("..RANGED_COOLDOWN_TIME.."s cooldown)",
	texture = "ctf_mode_classes_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 0,
	range = 150,
	damage = 4,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
	rightclick_func = function(itemstack, user, pointed)
		local pointed_nodedef = {}

		if pointed and pointed.type == "node" then
			pointed_nodedef = minetest.registered_nodes[minetest.get_node(pointed.under).name]
		end

		if (not pointed or not pointed_nodedef.on_rightclick) and itemstack:get_wear() == 0 then
			grenades.throw_grenade("grenades:frag", 24, user)

			minetest.after(0, user.set_wielded_item, user, itemstack)
			itemstack:set_wear(65534)
			update_wear(user:get_player_name(), "ctf_mode_classes:ranged_rifle_loaded", RANGED_COOLDOWN_TIME, 0)
		end

		minetest.item_place(itemstack, user, pointed)
	end
})

--
--- Medic Paxel
--

minetest.register_tool("ctf_mode_classes:support_paxel", {
	description = "Paxel",
	inventory_image = "default_tool_bronzepick.png^default_tool_bronzeshovel.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=1,
		groupcaps={
			cracky = {times={[1]=4.00, [2]=1.60, [3]=0.80}, uses=0, maxlevel=2},
			crumbly = {times={[1]=1.50, [2]=0.90, [3]=0.40}, uses=0, maxlevel=2},
			choppy={times={[1]=2.50, [2]=1.40, [3]=1.00}, uses=0, maxlevel=2},
		},
		damage_groups = {fleshy=4},
		punch_attack_uses = 0,
	},
	groups = {pickaxe = 1, tier = 2},
	sound = {breaks = "default_tool_breaks"},
})

return {
	finish = function()
		for _, player in pairs(minetest.get_connected_players()) do
			player:set_properties({hp_max = minetest.PLAYER_MAX_HP_DEFAULT, visual_size = vector.new(1, 1, 1)})
		end
	end,
	set = function(player, classname)
		player = PlayerObj(player)
		local meta = player:get_meta()

		if not classname then
			classname = meta:get_string("class")
		end

		if not classes[classname] then
			classname = "knight"
		end

		meta:set_string("class", classname)

		player:set_properties({
			hp_max = classes[classname].hp_max or minetest.PLAYER_MAX_HP_DEFAULT,
			visual_size = classes[classname].visual_size or vector.new(1, 1, 1)
		})

		player:set_hp(classes[classname].hp_max or minetest.PLAYER_MAX_HP_DEFAULT)

		dropondie.drop_all(player)
		give_initial_stuff(player)
	end,
	get = function(player)
		local cname = player:get_meta():get_string("class")

		return cname and (classes[cname] or {}) or false
	end,
	show_class_formspec = function(self, player)
		if not cooldowns:get(player) then
			cooldowns:set(player, CLASS_SWITCH_COOLDOWN)

			local classes_elements = {}
			local idx = 0

			for cname in pairs(classes) do
				classes_elements[cname] = {
					type = "button",
					exit = true,
					label = HumanReadable(cname),
					pos = {x = "center", y = idx},
					func = function(playername, fields, field_name)
						if mode_classes.dist_from_flag(player) <= 5 then
							self.set(player, cname)
						end
					end,
				}

				idx = idx + ctf_gui.ELEM_SIZE.y + 0.5
			end

			ctf_gui.show_formspec(player, "ctf_mode_classes:class_form", {
				size = {x = 6, y = 8},
				title = "Choose A Class",
				privs = {interact = true},
				elements = classes_elements,
			})
		else
			minetest.chat_send_player(
				PlayerName(player),
				"You can only change your class every "..CLASS_SWITCH_COOLDOWN.." seconds"
			)
		end
	end,
}
