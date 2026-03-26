-- This helps me to play around with my nvim config
vim.keymap.set("n", "<leader><leader>x", "<CMD>source %<CR>")
vim.keymap.set("n", "<leader>x", ":.lua<CR>")
vim.keymap.set("v", "<leader>x", ":lua<CR>")

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Navigation between vim windows and tmux panes is handled by vim-tmux-navigator plugin

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Linting quickfix
vim.keymap.set("n", "<leader>lt", "<cmd>TyCheck<cr>", { desc = "[L]int [T]y check -> quickfix" })
vim.keymap.set("n", "<leader>lr", "<cmd>RuffCheck<cr>", { desc = "[L]int [R]uff check -> quickfix" })
vim.keymap.set("n", "<leader>ln", "<cmd>cnext<cr>", { desc = "[L]int [N]ext quickfix entry" })
vim.keymap.set("n", "<leader>lp", "<cmd>cprev<cr>", { desc = "[L]int [P]rev quickfix entry" })

-- Signify opens a new tab and I want to be able to close it without quiting the program
vim.keymap.set("n", "<leader>tc", ":tabclose<cr>", { desc = "[T]ab [C]lose" })

-- Insert discussion comment block: --- / ### munatsi -- <date> / cursor / ---
vim.keymap.set("n", "<leader>dc", function()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local header = "### munatsi -- " .. os.date("%Y-%m-%d")
	local lines = { "---", "", header, "", "", "", "---" }
	vim.api.nvim_put(lines, "l", true, false)
	-- Cursor target: row+1="---", +2="", +3=header, +4="", +5=<here>, +6="", +7="---"
	vim.api.nvim_win_set_cursor(0, { row + 5, 0 })
	vim.cmd("startinsert")
end, { desc = "[D]iscussion [C]omment block" })

-- Preview diagram in tmux pane (for BOP markdown review)
vim.keymap.set("n", "gp", function()
  require("preview").show()
end, { desc = "[G]o [P]review diagram in tmux pane" })

vim.keymap.set("n", "<leader>p", function()
  require("preview").show()
end, { desc = "[P]review diagram in tmux pane" })

-- Reload configuration
vim.keymap.set("n", "<leader>rc", function()
	vim.cmd("source ~/.config/mvim/init.lua")
	vim.notify("Config reloaded!", vim.log.levels.INFO)
end, { desc = "[R]eload [C]onfig" })
