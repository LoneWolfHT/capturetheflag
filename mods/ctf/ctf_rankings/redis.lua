return {
	backend = "redis",
	init_new = function(self, top)
		local redis = require("redis")
		self.client = redis.connect("127.0.0.1", tonumber(minetest.settings:get("ctf_rankings_redis_server_port")) or 6379)
		self.top = top

		assert(self.client:ping(), "Redis server not found!")

		for _, pname in ipairs(self.client:keys('*')) do
			local value = self.client:get(pname)
			local rank = minetest.parse_json(value)
			if rank.score then
				top:set(pname, rank.score)
			end
		end

		return self
	end,
	get = function(self, pname)
		local ranks = self.client:get(pname)

		if not ranks or ranks == "" then
			return false
		end

		return minetest.parse_json(ranks)
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
		self.client:set(pname, minetest.write_json(newrankings))
	end,
	add = function(self, pname, amounts)
		pname = PlayerName(pname)

		local newrankings = self:get(pname) or {}

		for k, v in pairs(amounts) do
			newrankings[k] = (newrankings[k] or 0) + v
		end

		self.top:set(pname, newrankings.score or 0)
		self.client:set(pname, minetest.write_json(newrankings))
	end
}
