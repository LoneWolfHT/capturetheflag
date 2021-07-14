ctf_ranged = {}

local shoot_cooldown = ctf_core.init_cooldowns()

minetest.register_craftitem("ctf_ranged:ammo", {
	description = "Ammo",
	inventory_image = "ctf_ranged_ammo.png",
})

function ctf_ranged.register_simple_weapon(name, def)
	minetest.register_tool(rawf.also_register_loaded_tool(name, {
		description = def.description,
		inventory_image = def.texture.."^[colorize:#F44:42",
		ammo = def.ammo or "ctf_ranged:ammo",
		rounds = def.rounds,
		groups = {ranged = 1, [def.type] = 1, not_in_creative_inventory = 1},
		on_use = function(itemstack, user)
			local result = rawf.load_weapon(itemstack, user:get_inventory())

			if result:get_name() == itemstack:get_name() then
				minetest.sound_play("ctf_ranged_click", {pos = user:get_pos()}, true)
			else
				minetest.sound_play("ctf_ranged_reload", {pos = user:get_pos()}, true)
			end

			return result
		end,
	},
	function(loaded_def)
		loaded_def.description = def.description.." (Loaded)"
		loaded_def.inventory_image = def.texture
		loaded_def.groups.not_in_creative_inventory = nil
		loaded_def.on_use = function(itemstack, user)
			if shoot_cooldown:get(user) then
				return
			end

			if def.automatic then
				if not rawf.enable_automatic(def.fire_interval, itemstack, user) then
					return
				end
			else
				shoot_cooldown:start(user, def.fire_interval)
			end

			local spawnpos, look_dir = rawf.get_bullet_start_data(user)
			local endpos = vector.add(spawnpos, vector.multiply(look_dir, def.range))
			local rays

			if type(def.bullet) == "table" then
				def.bullet.texture = "ctf_ranged_bullet.png"
			else
				def.bullet = {texture = "ctf_ranged_bullet.png"}
			end

			if not def.bullet.spread then
				rays = {rawf.bulletcast(
					def.bullet,
					spawnpos, endpos, true, true
				)}
			else
				rays = rawf.spread_bulletcast(def.bullet, spawnpos, endpos, true, true)
			end

			minetest.sound_play(def.fire_sound, {pos = user:get_pos()}, true)

			for _, ray in pairs(rays) do
				local hitpoint = ray:hit_object_or_node({
					node = function(ndef)
						return ndef.walkable == true
					end,
					object = function(obj)
						return obj:is_player() and obj ~= user
					end
				})

				if hitpoint then
					if hitpoint.type == "node" then
						local nodedef = minetest.registered_nodes[minetest.get_node(hitpoint.under).name]

						if nodedef.groups.snappy or (nodedef.groups.oddly_breakable_by_hand or 0) >= 3 then
							if not minetest.is_protected(hitpoint.under, user:get_player_name()) then
								minetest.dig_node(hitpoint.under)
							end
						else
							minetest.add_particle({
								pos = vector.subtract(hitpoint.intersection_point, vector.multiply(look_dir, 0.04)),
								velocity = vector.new(),
								acceleration = {x=0, y=0, z=0},
								expirationtime = def.bullethole_lifetime or 3,
								size = 1,
								collisiondetection = false,
								texture = "ctf_ranged_bullethole.png",
							})
						end
					elseif hitpoint.type == "object" then
						hitpoint.ref:punch(user, 1, {
							full_punch_interval = 1,
							damage_groups = {ranged = 1, [def.type] = 1, fleshy = def.damage}
						}, look_dir)
					end
				end
			end

			return rawf.unload_weapon(itemstack)
		end
	end))
end

ctf_ranged.register_simple_weapon("ctf_ranged:pistol", {
	type = "pistol",
	description = "Pistol",
	texture = "ctf_ranged_pistol.png",
	fire_sound = "ctf_ranged_pistol",
	rounds = 50,
	range = 75,
	damage = 1,
	automatic = true,
	fire_interval = 0.6,
})

ctf_ranged.register_simple_weapon("ctf_ranged:rifle", {
	type = "rifle",
	description = "Rifle",
	texture = "ctf_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 40,
	range = 150,
	damage = 4,
	fire_interval = 0.8,
})

ctf_ranged.register_simple_weapon("ctf_ranged:shotgun", {
	type = "shotgun",
	description = "Shotgun",
	texture = "ctf_ranged_shotgun.png",
	fire_sound = "ctf_ranged_shotgun",
	bullet = {
		amount = 30,
		spread = 3,
	},
	rounds = 10,
	range = 25,
	damage = 1,
	fire_interval = 2,
})

ctf_ranged.register_simple_weapon("ctf_ranged:smg", {
	type = "smg",
	description = "Submachinegun",
	texture = "ctf_ranged_smgun.png",
	fire_sound = "ctf_ranged_pistol",
	bullet = {
		spread = 1,
	},
	automatic = true,
	rounds = 30,
	range = 75,
	damage = 2,
	fire_interval = 0.1,
})
