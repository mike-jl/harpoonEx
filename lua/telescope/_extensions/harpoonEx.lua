local action_state = require("telescope.actions.state")
local harpoon = require("harpoon")
local harpoonEx = require("harpoonEx")
local actions = require("telescope.actions")

local conf = {}

local make_finder = function(harpoon_files)
	local paths = {}
	for i, item in pairs(harpoon_files.items) do
		table.insert(paths, { i, item })
	end

	local utils = require("telescope.utils")
	local strings = require("plenary.strings")
	local entry_display = require("telescope.pickers.entry_display")

	local icon_width = 0
	if not conf.disable_devicons then
		local icon, _ = utils.get_devicons("fname", conf.disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 2 },
			{ width = icon_width },
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		local icon, hl_group = utils.get_devicons(entry.path, conf.disable_devicons)
		return displayer({
			{ entry.value[1], "TelescopeResultsNumber" },
			{ icon, hl_group },
			{ entry.value[2].value },
		})
	end

	return require("telescope.finders").new_table({
		results = paths,
		entry_maker = function(entry)
			return {
				value = entry,
				ordinal = entry[1] .. " " .. entry[2].value,
				display = make_display,
				path = entry[2].value,
				lnum = entry[2].context.row,
			}
		end,
	})
end

local move_mark_up = function(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	local length = harpoon:list():length()

	if selection.index == length then
		return
	end

	local mark_list = harpoon:list().items

	local oldIndex = selection.index
	local newIndex = oldIndex + 1
	table.remove(mark_list, oldIndex)
	table.insert(mark_list, newIndex, selection.value[2])

	local current_picker = action_state.get_current_picker(prompt_bufnr)
	-- temporarily register a callback which keeps selection on refresh
	local selection_row = current_picker:get_selection_row() - 1
	local callbacks = { unpack(current_picker._completion_callbacks) } -- shallow copy
	current_picker:register_completion_callback(function(self)
		self:set_selection(selection_row)
		self._completion_callbacks = callbacks
	end)
	current_picker:refresh(make_finder(harpoon:list()), { reset_prompt = true })
end

local move_mark_down = function(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	if selection.index == 1 then
		return
	end
	local mark_list = harpoon:list().items

	local oldIndex = selection.index
	local newIndex = oldIndex - 1
	table.remove(mark_list, oldIndex)
	table.insert(mark_list, newIndex, selection.value[2])
	local current_picker = action_state.get_current_picker(prompt_bufnr)

	local selection_row = current_picker:get_selection_row() + 1
	local callbacks = { unpack(current_picker._completion_callbacks) } -- shallow copy
	current_picker:register_completion_callback(function(self)
		self:set_selection(selection_row)
		self._completion_callbacks = callbacks
	end)
	current_picker:refresh(make_finder(harpoon:list()), { reset_prompt = true })
end

local harpoon_list
return require("telescope").register_extension({
	setup = function(ext_config, config)
		conf = config
		harpoon_list = ext_config.list or harpoon:list()
	end,
	exports = {
		harpoonEx = function(opts)
			-- vim.print(opts)
			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon",
					finder = make_finder(harpoon_list),
					previewer = conf.grep_previewer({}),
					sorter = conf.generic_sorter({}),
					attach_mappings = function(_, map)
						actions.delete_mark = function(prompt_bufnr)
							local current_picker = action_state.get_current_picker(prompt_bufnr)
							current_picker:delete_selection(function(selection)
								harpoonEx.delete(harpoon:list(), selection.value[1])
							end)
						end

						actions.move_mark_up = function(prompt_bufnr)
							move_mark_up(prompt_bufnr)
						end

						actions.move_mark_down = function(prompt_bufnr)
							move_mark_down(prompt_bufnr)
						end

						map({ "i", "n" }, "<M-d>", actions.delete_mark)
						map({ "i", "n" }, "<M-k>", actions.move_mark_up)
						map({ "i", "n" }, "<M-j>", actions.move_mark_down)

						return true
					end,
				})
				:find()
		end,
	},
})
