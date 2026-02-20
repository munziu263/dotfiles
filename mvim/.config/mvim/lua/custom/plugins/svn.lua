-- SVN Navigator Module
local M = {}

-- Store state
M.state = {
	files = {},
	current_index = 1,
	list_buf = nil,
	list_win = nil,
	file_win = nil,
	original_win = nil,
	original_tab = nil,
	navigator_tab = nil
}

-- Parse SVN status output
function M.parse_svn_status()
	local handle = io.popen("svn status")
	if not handle then
		vim.notify("Failed to run svn status", vim.log.levels.ERROR)
		return {}
	end
	
	local result = handle:read("*a")
	handle:close()
	
	local files = {}
	for line in result:gmatch("[^\r\n]+") do
		local status = line:sub(1, 1)
		local file = line:sub(8):match("^%s*(.-)%s*$") -- Skip status column, trim whitespace
		if status:match("[ACDMR]") and file and file ~= "" then
			table.insert(files, {
				status = status,
				file = file,
				display = string.format("[%s] %s", status, file)
			})
		end
	end
	
	return files
end

-- Update the file list display
function M.update_file_list()
	if not M.state.list_buf or not vim.api.nvim_buf_is_valid(M.state.list_buf) then
		return
	end
	
	local lines = {}
	for i, item in ipairs(M.state.files) do
		local prefix = (i == M.state.current_index) and "> " or "  "
		table.insert(lines, prefix .. item.display)
	end
	
	vim.api.nvim_buf_set_option(M.state.list_buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.state.list_buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(M.state.list_buf, "modifiable", false)
	
	-- Color code status indicators and position cursor
	vim.api.nvim_buf_clear_namespace(M.state.list_buf, -1, 0, -1)
	for i, item in ipairs(M.state.files) do
		local line_idx = i - 1
		local status = item.status
		local hl_group = "Normal"
		
		if status == "M" then
			hl_group = "DiffChange"
		elseif status == "A" then
			hl_group = "DiffAdd"
		elseif status == "D" then
			hl_group = "DiffDelete"
		elseif status == "C" then
			hl_group = "DiffText"
		end
		
		-- Highlight the status indicator [X]
		local prefix_len = (i == M.state.current_index) and 2 or 2
		vim.api.nvim_buf_add_highlight(M.state.list_buf, -1, hl_group, line_idx, prefix_len, prefix_len + 3)
	end
	
	-- Position cursor on current line (enables built-in scrolling with scrolloff)
	if M.state.current_index > 0 and M.state.current_index <= #M.state.files and M.state.list_win and vim.api.nvim_win_is_valid(M.state.list_win) then
		vim.api.nvim_win_set_cursor(M.state.list_win, {M.state.current_index, 0})
	end
end

-- Show file content (not diff) in top window
function M.show_current_file()
	if #M.state.files == 0 or M.state.current_index < 1 or M.state.current_index > #M.state.files then
		return
	end
	
	local file = M.state.files[M.state.current_index].file
	
	-- Switch to file window
	if M.state.file_win and vim.api.nvim_win_is_valid(M.state.file_win) then
		-- Save current window
		local cur_win = vim.api.nvim_get_current_win()
		
		-- Move to file window
		vim.api.nvim_set_current_win(M.state.file_win)
		
		-- Open the file (no diff)
		vim.cmd("edit " .. vim.fn.fnameescape(file))
		
		-- Return to list window
		if cur_win and vim.api.nvim_win_is_valid(cur_win) then
			vim.api.nvim_set_current_win(cur_win)
		end
	end
end

-- Open diff in new tab
function M.open_diff_in_new_tab()
	if #M.state.files == 0 or M.state.current_index < 1 or M.state.current_index > #M.state.files then
		return
	end
	
	local file = M.state.files[M.state.current_index].file
	
	-- Open new tab
	vim.cmd("tabnew " .. vim.fn.fnameescape(file))
	
	-- Show diff in current tab (! forces current tab)
	vim.cmd("SignifyDiff!")
end

-- Navigate to next/previous file
function M.navigate(direction)
	local new_index = M.state.current_index + direction
	if new_index >= 1 and new_index <= #M.state.files then
		M.state.current_index = new_index
		M.update_file_list()
		M.show_current_file()
	end
end

-- Close the navigator
function M.close_navigator()
	-- Return to original tab and window
	if M.state.original_tab and vim.api.nvim_tabpage_is_valid(M.state.original_tab) then
		vim.api.nvim_set_current_tabpage(M.state.original_tab)
		if M.state.original_win and vim.api.nvim_win_is_valid(M.state.original_win) then
			vim.api.nvim_set_current_win(M.state.original_win)
		end
	end
	
	-- Close navigator tab if it exists
	if M.state.navigator_tab and vim.api.nvim_tabpage_is_valid(M.state.navigator_tab) then
		vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(M.state.navigator_tab))
	end
	
	-- Clean up state
	M.state = {
		files = {},
		current_index = 1,
		list_buf = nil,
		list_win = nil,
		file_win = nil,
		original_win = nil,
		original_tab = nil,
		navigator_tab = nil
	}
end

-- Refresh the file list
function M.refresh()
	M.state.files = M.parse_svn_status()
	M.state.current_index = math.min(M.state.current_index, #M.state.files)
	if M.state.current_index < 1 and #M.state.files > 0 then
		M.state.current_index = 1
	end
	M.update_file_list()
	M.show_current_file()
end

-- Commit changes
function M.commit_changes()
	vim.ui.input({
		prompt = "Commit message: ",
		default = "",
	}, function(msg)
		if msg and msg ~= "" then
			-- Save current buffers
			vim.cmd("wall")
			
			-- Run svn commit
			local cmd = string.format('svn commit -m "%s"', msg:gsub('"', '\\"'))
			local result = vim.fn.system(cmd)
			
			if vim.v.shell_error == 0 then
				vim.notify("Changes committed successfully", vim.log.levels.INFO)
				-- Refresh the view
				M.refresh()
				
				-- If no more changes, close the navigator
				if #M.state.files == 0 then
					vim.notify("No more changes to review", vim.log.levels.INFO)
					M.close_navigator()
				end
			else
				vim.notify("Commit failed: " .. result, vim.log.levels.ERROR)
			end
		end
	end)
end

-- Jump to file window
function M.jump_to_file()
	if M.state.file_win and vim.api.nvim_win_is_valid(M.state.file_win) then
		vim.api.nvim_set_current_win(M.state.file_win)
	end
end

-- Create the SVN navigator layout
function M.show_svn_navigator()
	M.state.files = M.parse_svn_status()
	
	if #M.state.files == 0 then
		vim.notify("No SVN changes found", vim.log.levels.INFO)
		return
	end
	
	-- Store original window and tab
	M.state.original_win = vim.api.nvim_get_current_win()
	M.state.original_tab = vim.api.nvim_get_current_tabpage()
	
	-- Create a new tab for the navigator
	vim.cmd("tabnew")
	M.state.navigator_tab = vim.api.nvim_get_current_tabpage()
	
	-- Open first file
	local first_file = M.state.files[1].file
	vim.cmd("edit " .. vim.fn.fnameescape(first_file))
	M.state.file_win = vim.api.nvim_get_current_win()
	
	-- Create bottom split for file list
	vim.cmd("botright new")
	M.state.list_win = vim.api.nvim_get_current_win()
	
	-- Create and setup the list buffer
	M.state.list_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(M.state.list_win, M.state.list_buf)
	vim.api.nvim_buf_set_option(M.state.list_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(M.state.list_buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(M.state.list_buf, "swapfile", false)
	vim.api.nvim_buf_set_name(M.state.list_buf, "SVN Changes")
	
	-- Set window height
	vim.api.nvim_win_set_height(M.state.list_win, math.min(10, #M.state.files + 2))
	
	-- Update display
	M.update_file_list()
	
	-- Set up keymaps for the list buffer
	local opts = { buffer = M.state.list_buf, silent = true }
	
	-- Navigation
	vim.keymap.set("n", "j", function() M.navigate(1) end, opts)
	vim.keymap.set("n", "k", function() M.navigate(-1) end, opts)
	vim.keymap.set("n", "<Down>", function() M.navigate(1) end, opts)
	vim.keymap.set("n", "<Up>", function() M.navigate(-1) end, opts)
	vim.keymap.set("n", "l", function() M.navigate(1) end, opts)
	vim.keymap.set("n", "h", function() M.navigate(-1) end, opts)
	vim.keymap.set("n", "<Tab>", function() M.navigate(1) end, opts)
	vim.keymap.set("n", "<S-Tab>", function() M.navigate(-1) end, opts)
	
	-- Actions
	vim.keymap.set("n", "d", M.open_diff_in_new_tab, opts)
	vim.keymap.set("n", "<CR>", M.jump_to_file, opts)
	vim.keymap.set("n", "c", M.commit_changes, opts)
	vim.keymap.set("n", "r", M.refresh, opts)
	vim.keymap.set("n", "q", M.close_navigator, opts)
	vim.keymap.set("n", "<Esc>", M.close_navigator, opts)
	
	-- Set buffer options
	vim.api.nvim_buf_set_option(M.state.list_buf, "cursorline", true)
	vim.api.nvim_win_set_option(M.state.list_win, "number", false)
	vim.api.nvim_win_set_option(M.state.list_win, "relativenumber", false)
	vim.api.nvim_win_set_option(M.state.list_win, "signcolumn", "no")
	vim.api.nvim_win_set_option(M.state.list_win, "wrap", false)
	
	-- Add helpful statusline
	vim.api.nvim_win_set_option(M.state.list_win, "statusline", 
		string.format(" SVN Changes (%d files) | j/k:navigate | d:diff | c:commit | r:refresh | q:quit ", #M.state.files))
end

return {
	"mhinz/vim-signify",
	config = function()
		vim.keymap.set("n", "<leader>gd", ":SignifyDiff<cr>", { desc = "[G]et [D]iff [Signify]" })
		vim.keymap.set("n", "<leader>gp", ":SignifyHunkDiff<cr>", { desc = "[G]et Diff [P]review [Signify]" })
		vim.keymap.set("n", "<leader>gt", ":SignifyToggleHighlights<cr>", { desc = "[G]et Diff [P]review [Signify]" })
		
		-- SVN Navigator keymap
		vim.keymap.set("n", "<leader>gs", function()
			M.show_svn_navigator()
		end, { desc = "[G]et [S]VN Navigator" })
	end,
}