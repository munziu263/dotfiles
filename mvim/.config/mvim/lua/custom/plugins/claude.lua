return {
	"coder/claudecode.nvim",
	dependencies = {
		"folke/snacks.nvim", -- Optional for enhanced terminal
	},
	keys = {
		{ "<leader>a", nil, desc = "AI/Claude Code" },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil" },
		},
		-- Diff management
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
	opts = {
		-- Server Configuration
		port_range = { min = 10000, max = 65535 }, -- WebSocket server port range
		auto_start = true, -- Auto-start server on Neovim startup
		log_level = "info", -- "trace", "debug", "info", "warn", "error"
		terminal_cmd = nil, -- Custom terminal command (default: "claude")

		-- Selection Tracking
		track_selection = true, -- Enable real-time selection tracking
		visual_demotion_delay_ms = 50, -- Delay before demoting visual selection (ms)

		-- Connection Management
		connection_wait_delay = 200, -- Wait time after connection before sending queued @ mentions (ms)
		connection_timeout = 10000, -- Max time to wait for Claude Code connection (ms)
		queue_timeout = 5000, -- Max time to keep @ mentions in queue (ms)

		-- Terminal Configuration
		terminal = {
			split_side = "right", -- "left" or "right"
			split_width_percentage = 0.30, -- Width as percentage (0.0 to 1.0)
			provider = "auto", -- "auto", "snacks", or "native"
			show_native_term_exit_tip = true, -- Show exit tip for native terminal
			auto_close = true, -- Auto-close terminal after command completion
		},

		-- Diff Integration
		diff_opts = {
			auto_close_on_accept = true, -- Close diff view after accepting changes
			show_diff_stats = true, -- Show diff statistics
			vertical_split = true, -- Use vertical split for diffs
			open_in_current_tab = true, -- Open diffs in current tab vs new tab
		},
	},
}
