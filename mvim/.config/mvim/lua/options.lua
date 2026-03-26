-- Relative numbers
vim.opt.number = true
vim.opt.relativenumber = true
-- tab and indent stuff
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
-- enable OS Clipboard
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)
-- only show the mode in the mini status line
vim.opt.showmode = false
-- Preview substitutions live
vim.opt.inccommand = "split"
-- Show which line your cursor is on
vim.opt.cursorline = true
-- Scroll off
vim.opt.scrolloff = 10
-- keep signcolum on by default
vim.opt.signcolumn = "yes"
-- conceallevel for obsidian.nvim ui features
vim.opt.conceallevel = 2

-- Auto-reload files changed externally (e.g., by Claude Code in another tmux pane)
vim.opt.autoread = true
vim.opt.updatetime = 250

local auto_reload_group = vim.api.nvim_create_augroup("AutoReloadFiles", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = auto_reload_group,
	callback = function()
		if vim.fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
})

-- Make cursor character visible (block cursor with character visibility)
vim.opt.guicursor = "n-v-c:block-Cursor/lCursor-blinkwait700-blinkoff400-blinkon250,i-ci-ve:ver25-Cursor/lCursor,r-cr:hor20,o:hor50"
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"

-- Additional cursor visibility settings
vim.opt.termguicolors = true
vim.cmd([[highlight Cursor guifg=black guibg=white blend=0]])
vim.cmd([[set guicursor+=a:Cursor/lCursor]])
