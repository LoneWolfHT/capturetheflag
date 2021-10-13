return {
	backend = "default",
	init_new = function(self, top)
		local new_rankingobj = table.copy(self)

		new_rankingobj.modstorage = assert(minetest.get_mod_storage(), "Can only init rankings at runtime!")
		new_rankingobj.top = top

		for k, v in pairs(new_rankingobj.modstorage:to_table()["fields"]) do
			local rank = minetest.deserialize(v)
			if rank.score then
				top:set(k, rank.score)
			end
		end

		return new_rankingobj
	end,
	get = function(self, pname)
		local rank_str = self.modstorage:get_string(PlayerName(pname))

		if not rank_str or rank_str == "" then
			return false
		end

		return minetest.deserialize(rank_str)
	end,
	set = function(self, pname, newrankings, erase_unset)
		pname = PlayerName(pname)

		if not erase_unset then
			local rank = self:get(pname)
			if rank then
				for k, v in pairs(newrankings) do
					rank[k] = v
				end

				newrankings = rank
			end
		end

		self.top:set(pname, newrankings.score or 0)
		self.modstorage:set_string(pname, minetest.serialize(newrankings))
	end,
	add = function(self, pname, amounts)
		pname = PlayerName(pname)

		local newrankings = self:get(pname) or {}

		for k, v in pairs(amounts) do
			newrankings[k] = (newrankings[k] or 0) + v
		end

		self.top:set(pname, newrankings.score or 0)
		self.modstorage:set_string(pname, minetest.serialize(newrankings))
	end
}
