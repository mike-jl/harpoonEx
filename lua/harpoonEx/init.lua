local M = {}

M.index = {}

local get_full_path = function(path)
	local bufPath = vim.loop.fs_realpath(path)
	if not bufPath then
		if string.sub(path, 1, 1) == "/" then
			bufPath = path
		else
			bufPath = vim.loop.fs_realpath(".") .. "/" .. path
		end
	end
	return bufPath
end

local sync_index = function(list, index)
	if index then
		M.index[list.name] = index
		return
	end

	if M.index[list.name] > list._length then
		M.index[list.name] = list._length
		return
	end
	local bufPath = get_full_path(vim.api.nvim_buf_get_name(0))
	-- find corresponding harpoon item
	for i = 1, list._length do
		local item = list.items[i]
		if item ~= nil and item.value ~= nil then
			local harpoonPath = get_full_path(item.value)
			if bufPath == harpoonPath then
				M.index[list.name] = i
				return
			end
		end
	end
end

local list_created = function(list)
	M.index[list.name] = 0
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		pattern = { "*" },
		callback = function(_)
			sync_index(list)
		end,
	})
end

local ui_create = function(args)
	local bufPath = get_full_path(args.current_file)

	local lines = vim.api.nvim_buf_get_lines(args.bufnr, 0, -1, false)
	for i, line in pairs(lines) do
		local harpoonPath = get_full_path(line)
		if bufPath == harpoonPath then
			vim.api.nvim_win_set_cursor(args.win_id, { i, 0 })
			return
		end
	end
end

function M.extend()
	return {
		SELECT = function(args)
			sync_index(args.list, args.idx)
		end,
		ADD = function(args)
			sync_index(args.list, args.idx)
		end,
		REMOVE = function(args)
			sync_index(args.list)
		end,
		LIST_CREATED = list_created,
		UI_CREATE = ui_create,
	}
end

local function cur_buf_is_harpoon(list)
	local current = list.items[M.index[list.name]]
	if not current then
		return true
	end

	local bufnr = vim.fn.bufnr(get_full_path(current.value))

	return bufnr == vim.fn.bufnr()
end

M.next_harpoon = function(list, prev)
	if not cur_buf_is_harpoon(list) then
		list:select(M.index[list.name])
		return
	end
	local i = M.index[list.name] or 0
	local j = 1
	while true do
		if prev then
			i = i - 1
		else
			i = i + 1
		end
		if i > list._length then
			i = 1
		end
		if i <= 0 then
			i = list._length
		end
		if list.items[i] then
			list:select(i)
			return
		end
		j = j + 1
		if j > list._length then
			return
		end
	end
end

M.telescope_live_grep = function(list)
	local ok, builtin = pcall(require, "telescope.builtin")
	if not ok then
		return
	end

	local file_paths = {}
	for _, item in pairs(list.items) do
		table.insert(file_paths, item.value)
	end
	builtin.live_grep({
		search_dirs = file_paths,
	})
end

M.delete = function(list, index, switch)
	if not index then
		if not cur_buf_is_harpoon(list) then
			return
		end
		index = M.index[list.name]
	end
	if not list.items[index] then
		sync_index(list)
		return
	end
	local item = table.remove(list.items, index)
	list._length = list._length - 1

	local ok, Extensions = pcall(require, "harpoon.extensions")
	if not ok then
		return
	end

	Extensions.extensions:emit(Extensions.event_names.REMOVE, { list = list, item = item, idx = index })

	if switch and not cur_buf_is_harpoon(list) and vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "" then
		M.next_harpoon(list)
	end
end

local default_options = {
	reload_on_dir_change = false,
}

M.options = {}

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("keep", opts or {}, default_options)
	if M.options.reload_on_dir_change then
		vim.api.nvim_create_autocmd({ "DirChanged" }, {
			pattern = "*",
			callback = function(_)
				M:reset()
			end,
		})
	end
end

M.reset = function()
	local hok, Harpoon = pcall(require, "harpoon")
	local dok, Data = pcall(require, "harpoon.data")
	if not hok or not dok then
		return
	end
	Harpoon.data = Data.Data:new(Harpoon.config)
	Harpoon.lists = {}
end

return M
