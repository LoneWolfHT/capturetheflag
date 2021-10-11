---@param name string Player name
---@param rankings table Recent rankings to show in the gui
---@param rank_values table Example: `{_sort = "score", "captures" "kills"}`
---@param formdef table table for customizing the formspec
function ctf_modebase.show_summary_gui(name, rankings, special_rankings, rank_values, formdef)
	local sort_by = rank_values._sort or rank_values[1]

	local sort = function(unsorted)
		local sorted = {}

		for pname, ranks in pairs(unsorted) do
			local t = table.copy(ranks)
			t.pname = pname
			t.sort = ranks[sort_by] or 0
			table.insert(sorted, t)
		end

		table.sort(sorted, function(a, b) return a.sort > b.sort end)

		return sorted
	end

	local rankings_sorted = sort(rankings)
	local special_rankings_sorted = sort(special_rankings)

	ctf_modebase.show_summary_gui_sorted(
		name, rankings_sorted, special_rankings_sorted, rank_values, formdef
	)
end

---@param name string Player name
---@param rankings table Sorted recent rankings Example: `{{pname=a, score=2}, {pname=b, score=1}}`
---@param rank_values table Example: `{_sort = "score", "captures" "kills"}`
---@param formdef table table for customizing the formspec
function ctf_modebase.show_summary_gui_sorted(name, rankings, special_rankings, rank_values, formdef)
	if not formdef then formdef = {} end
	if not formdef.buttons then formdef.buttons = {} end

	local render = function(sorted)
		for i, ranks in ipairs(sorted) do
			local color = "white"

			if not formdef.disable_nonuser_colors then
				if not ranks._row_color then
					local team = ctf_teams.get(ranks.pname)

					if team then
						color = ctf_teams.team[team].color
					end
				else
					color = ranks._row_color
				end
			elseif name == ranks.pname then
				color = "gold"
			end

			local row = string.format("%d,%s,%s", ranks.number or i, color, ranks.pname)

			for idx, rank in ipairs(rank_values) do
				row = string.format("%s,%s", row, ranks[rank] or 0)
			end

			sorted[i] = row
		end
	end

	render(rankings)
	render(special_rankings)

	if #special_rankings >= 1 then
		if formdef.special_row_title then
			table.insert(special_rankings, 1, string.format(
				",white,%s,%s", formdef.special_row_title, HumanReadable(table.concat(rank_values, "  ,"))
			))
		end

		table.insert(special_rankings, string.rep(",", #rank_values+3))
	end

	ctf_gui.show_formspec(name, "ctf_modebase:summary", {
		title = formdef.title or "Summary",
		elements = {
			rankings = {
				type = "table",
				pos = {"center", 0},
				size = {ctf_gui.FORM_SIZE.x-1, ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 3)},
				options = {
					highlight = "#00000000",
				},
				columns = {
					{type = "text", width = 1},
					{type = "color"}, -- Player team color
					{type = "text", width = 16}, -- Player name
					("text;"):rep(#rank_values):sub(1, -2),
				},
				rows = {
					#special_rankings > 1 and table.concat(special_rankings, ",") or "",
					"white", "Player Name", HumanReadable(table.concat(rank_values, "  ,")),
					table.concat(rankings, ",")
				}
			},
			next = formdef.buttons.next and {
				type = "button",
				label = "See Current",
				pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
				func = function(playername, fields, field_name)
					local current_mode = ctf_modebase:get_current_mode()

					if not current_mode then return end

					local result, nrankings, nspecial_rankings, nrank_values, nformdef = current_mode.summary_func(playername)

					if result then
						ctf_modebase.show_summary_gui(name, nrankings, nspecial_rankings, nrank_values, nformdef)
					end
				end,
			},
			previous = formdef.buttons.previous and {
				type = "button",
				label = "See Previous",
				pos = {"center", ctf_gui.FORM_SIZE.y - (ctf_gui.ELEM_SIZE.y + 2.5)},
				func = function(playername, fields, field_name)
					local current_mode = ctf_modebase:get_current_mode()

					if not current_mode then return end

					local result, nrankings, nspecial_rankings, nrank_values, nformdef = current_mode.summary_func(playername, "p")

					if result then
						ctf_modebase.show_summary_gui(name, nrankings, nspecial_rankings, nrank_values, nformdef)
					end
				end,
			},
		}
	})
end

minetest.register_chatcommand("summary", {
	description = "Show a summary for the current match",
	func = function(name, param)
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode then
			return false, "No match has started yet!"
		end

		if current_mode.summary_func then
			local result, rankings, special_rankings, rank_values, formdef = current_mode.summary_func(name, param)

			if result then
				ctf_modebase.show_summary_gui(name, rankings, special_rankings, rank_values, formdef)
			else
				return result, rankings -- rankings holds an error message in this case
			end

			return true
		else
			return false, "This mode doesn't have a summary command!"
		end
	end
})

minetest.register_chatcommand("s", minetest.registered_chatcommands.summary)
