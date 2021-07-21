function mode_class.show_gui(player)
	player = player or player:get_player_name()
--	assert(player.get_player_name)

	local fs = {
		"size[", #mode_class.class * 3 , ",4.5]"
	}

	local x = 0
	local y = 0
	for _, class in pairs(mode_class.class) do
		fs[#fs + 1] = "container["
		fs[#fs + 1] = tostring(x*3)
		fs[#fs + 1] = ","
		fs[#fs + 1] = tostring(y*3.5)
		fs[#fs + 1] = "]"
		fs[#fs + 1] = "image[1,-0.1;1,1;mode_class_"
		fs[#fs + 1] = class.name
		fs[#fs + 1] = ".png]"
		fs[#fs + 1] = "style[select_"
		fs[#fs + 1] = class.name
		fs[#fs + 1] = ";bgcolor="
		fs[#fs + 1] = class.color
		fs[#fs + 1] = "]"
		fs[#fs + 1] = "tableoptions[background=#00000000;highlight=#00000000;border=false]"
		fs[#fs + 1] = "tablecolumns[color;text]"
		fs[#fs + 1] = "table[0,0.9;2.8,2.2;;"
		fs[#fs + 1] = class.color
		fs[#fs + 1] = ","
		fs[#fs + 1] = minetest.formspec_escape(class.description)
		fs[#fs + 1] = ",,"
		for _, item in pairs(class.pros) do
			fs[#fs + 1] = ",#cfc," .. minetest.formspec_escape(item)
		end
		for _, item in pairs(class.cons) do
			fs[#fs + 1] = ",#fcc," .. minetest.formspec_escape(item)
		end
		fs[#fs + 1] = "]"

		fs[#fs + 1] = "box[0,3.1;2.75,0.75;#2b2b2bFF]"

		for i, item in pairs(class.properties.initial_stuff) do
			fs[#fs + 1] = "item_image["
			fs[#fs + 1] = tostring(((i + 0.85) - ((#class.properties.initial_stuff-1) * 0.85)/2) * 0.6)
			fs[#fs + 1] = ",3.17;0.7,0.7;"
			fs[#fs + 1] = minetest.formspec_escape(ItemStack(item):get_name())
			fs[#fs + 1] = "]"

			local desc = ItemStack(item):get_description():split("\n")[1]

			fs[#fs + 1] = "tooltip["
			fs[#fs + 1] = tostring(((i + 0.85) - ((#class.properties.initial_stuff-1) * 0.85)/2) * 0.6)
			fs[#fs + 1] = ",3.17;0.7,0.7;"
			fs[#fs + 1] = minetest.formspec_escape(desc)
			fs[#fs + 1] = "]"
		end


		fs[#fs + 1] = "button_exit[0.5,4;2,1;select_"
		fs[#fs + 1] = class.name
		fs[#fs + 1] = ";Select]"
		fs[#fs + 1] = "container_end[]"

		x = x + 1
		if x > 3 then
			x = 0
			y = y + 1
		end
	end

	minetest.show_formspec(player, "mode_class:select", table.concat(fs))
end