return {
	backend = "redis",
	recent = {},
	init_new = function(self, top)
		local redis = require("redis")
		self.client = redis.connect("127.0.0.1", tonumber(minetest.settings:get("ctf_rankings_redis_server_port")) or 6379)
		self.top = top

		assert(self.client:ping(), "Redis server not found!")

		for _, pname in ipairs(self.client:keys('*')) do
			local value = self.client:get(pname)
			local rank = minetest.deserialize(value)
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

		return minetest.deserialize(ranks)
	end,
	set = function(self, pname, newrankings, erase_unset)
		pname = PlayerName(pname)

		if not self.recent[pname] then
			self.recent[pname] = {}
		end

		local rank = self:get(pname)
		if rank then
			if not erase_unset then
				for k, v in pairs(newrankings) do
					rank[k] = v
					self.recent[pname][k] = self.recent[pname][v]
				end

				newrankings = rank
			else
				self.recent[pname] = newrankings
			end
		end

		self.top:set(pname, newrankings.score or 0)

		self.client:set(pname, minetest.serialize(newrankings))
	end,
	add = function(self, pname, additions)
		pname = PlayerName(pname)

		if not self.recent[pname] then
			self.recent[pname] = {}
		end

		local newrank = self:get(pname) or {}

		for k, v in pairs(additions) do
			newrank[k] = (newrank[k] or 0) + v
			self.recent[pname][k] = (self.recent[pname][k] or 0) + v
		end

		self.top:set(pname, newrank.score or 0)

		self.client:set(pname, minetest.serialize(newrank))
	end
}
