return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		require("toggleterm").setup({
			size = 20,
			open_mapping = [[<c-\>]],
			hide_numbers = true,
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "float",
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		})

		-- Terminal-specific keymaps
		function _G.set_terminal_keymaps()
			local opts = { buffer = 0 }
			vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
			vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
			vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
			vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
			vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
		end

		-- Apply terminal keymaps when terminal opens
		vim.api.nvim_create_autocmd("TermOpen", {
			pattern = "term://*",
			callback = function()
				set_terminal_keymaps()
			end,
		})

		-- Create specific terminal instances for your workflow
		local Terminal = require("toggleterm.terminal").Terminal

		-- Claude terminal
		local claude = Terminal:new({
			cmd = "claude",
			dir = vim.fn.getcwd(),
			direction = "float",
			hidden = true,
			count = 5,
		})

		-- IPython terminal
		local ipython = Terminal:new({
			cmd = "ipython",
			dir = vim.fn.getcwd(),
			direction = "float",
			hidden = true,
			count = 6,
		})

		-- Python REPL
		local python = Terminal:new({
			cmd = "python",
			dir = vim.fn.getcwd(),
			direction = "float",
			hidden = true,
			count = 7,
		})

		-- Mojo REPL
		local mojo = Terminal:new({
			cmd = "mojo",
			dir = vim.fn.getcwd(),
			direction = "float",
			hidden = true,
			count = 8,
		})

		-- Node REPL
		local node = Terminal:new({
			cmd = "node",
			dir = vim.fn.getcwd(),
			direction = "float",
			hidden = true,
			count = 9,
		})

		-- Terminal toggle functions
		function _CLAUDE_TOGGLE()
			claude:toggle()
		end

		function _IPYTHON_TOGGLE()
			ipython:toggle()
		end

		function _PYTHON_TOGGLE()
			python:toggle()
		end

		function _MOJO_TOGGLE()
			mojo:toggle()
		end

		function _NODE_TOGGLE()
			node:toggle()
		end
	end,
	keys = {
		-- General terminal toggles
		{ "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
		{ "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "[T]erminal [F]loat" },
		{ "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "[T]erminal [H]orizontal" },
		{ "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "[T]erminal [V]ertical" },

		-- Specific REPL terminals
		{ "<leader>tcc", "<cmd>lua _CLAUDE_TOGGLE()<CR>", desc = "[T]erminal [C]laude [C]ode" },
		{ "<leader>tip", "<cmd>lua _IPYTHON_TOGGLE()<CR>", desc = "[T]erminal [I][P]ython" },
		{ "<leader>tpy", "<cmd>lua _PYTHON_TOGGLE()<CR>", desc = "[T]erminal [Py]thon" },
		{ "<leader>tmj", "<cmd>lua _MOJO_TOGGLE()<CR>", desc = "[T]erminal [M]o[j]o" },
		{ "<leader>tjs", "<cmd>lua _NODE_TOGGLE()<CR>", desc = "[T]erminal [J]ava[S]cript" },

		-- Terminal management
		{ "<leader>ta", "<cmd>ToggleTermToggleAll<cr>", desc = "[T]erminal Toggle [A]ll" },
	},
}