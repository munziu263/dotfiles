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

-- Signify opens a new tab and I want to be able to close it without quiting the program
vim.keymap.set("n", "<leader>tc", ":tabclose<cr>", { desc = "[T]ab [C]lose" })

-- Reload configuration
vim.keymap.set("n", "<leader>rc", function()
	vim.cmd("source ~/.config/mvim/init.lua")
	vim.notify("Config reloaded!", vim.log.levels.INFO)
end, { desc = "[R]eload [C]onfig" })
