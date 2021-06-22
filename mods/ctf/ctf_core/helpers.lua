--
--- PLAYERS
--
local get_player_by_name = minetest.get_player_by_name
function PlayerObj(player)
	local type = type(player)

	if type == "string" then
		return get_player_by_name(player)
	elseif type == "userdata" and player:is_player() then
		return player
	end
end

function PlayerName(player)
	local type = type(player)

	if type == "string" then
		return player
	elseif type == "userdata" and player:is_player() then
		return player:get_player_name()
	end
end

--
--- FORMSPECS
--

local registered_on_formspec_input = {}
function ctf_core.register_on_formspec_input(formname, func)
	table.insert(registered_on_formspec_input, {formname = formname, call = func})
end

minetest.register_on_player_receive_fields(function(player, formname, fields, ...)
	for _, func in ipairs(registered_on_formspec_input) do
		if formname:match(func.formname) then
			if func.call(PlayerName(player), formname, fields, ...) then
				return
			end
		end
	end
end)

--
--- STRINGS
--

-- Credit to https://stackoverflow.com/q/20284515/11433667 for capitalization
function HumanReadable(string)
	return string:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

--
--- TABLES
--

-- Borrowed from random_messages mod
function table.count( t ) -- luacheck: ignore
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end

---@param funclist table
function RunCallbacks(funclist, ...)
	for _, func in ipairs(funclist) do
		local temp = func(...)

		if temp then
			return temp
		end
	end
end

--
--- VECTORS/POSITIONS
--

function vector.sign(a)
	return vector.new(math.sign(a.x), math.sign(a.y), math.sign(a.z))
end

local vsort = vector.sort
function ctf_core.area_contains(pos1, pos2, pos)
	pos1, pos2 = vsort(pos1, pos2)

	return pos.x >= pos1.x and pos.x <= pos2.x
	   and pos.y >= pos1.y and pos.y <= pos2.y
	   and pos.z >= pos1.z and pos.z <= pos2.z
end

if not math.round then
	local m_floor = math.floor

	function math.round(x)
		return m_floor(x + 0.5)
	end
end
