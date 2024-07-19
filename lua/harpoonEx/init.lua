local Path = require("plenary.path")

M = {}

M.index = {}

local function index_of(items, length, element, config)
	local equals = config and config.equals or function(a, b)
		return a == b
	end
	local index = -1
	for i = 1, length do
		local item = items[i]
		if equals(element, item) then
			index = i
			break
		end
	end

	return index
end

local sync_index = function(list, options)
	local bufnr = options.bufnr
	local filename = options.filename
	local index = options.index
	if bufnr ~= nil and filename ~= nil then
		local config = list.config
		local relname = Path:new(filename):make_relative(config.get_root_dir())
		if bufnr == vim.fn.bufnr(relname, false) then
			local element = config.create_list_item(config, relname)
			local index_found = index_of(list.items, list._length, element, config)
			if index_found > -1 then
				M.index[list.name] = index_found
			end
		elseif index ~= nil then
			M.index[list.name] = index
		end
	elseif index ~= nil then
		M.index[list.name] = index
	end
end

local list_created = function(list)
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		pattern = { "*" },
		callback = function(args)
			sync_index(list, {
				bufnr = args.buf,
				filename = args.file,
			})
		end,
	})
end

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

-- win_id = win_id,
-- bufnr = bufnr,
-- current_file = current_file,
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
			sync_index(args.list, { index = args.idx })
		end,
		ADD = function(args)
			sync_index(args.list, { index = args.idx })
		end,
		REMOVE = function(args)
			sync_index(args.list, { index = args.idx })
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

M.telescope_live_grep = function(harpoon_files)
	local has_t, builtin = pcall(require, "telescope.builtin")
	if not has_t then
		return
	end

	local file_paths = {}
	for _, item in pairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end
	builtin.live_grep({
		search_dirs = file_paths,
	})
end

return M
