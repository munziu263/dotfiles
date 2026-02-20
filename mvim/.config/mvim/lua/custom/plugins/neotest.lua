return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
        }),
      },
    })

    -- Keymaps (using <leader>nt prefix to avoid conflicts with existing <leader>t* keymaps)
    local neotest = require("neotest")
    vim.keymap.set("n", "<leader>ntr", function() neotest.run.run() end, { desc = "[N]eotest Run nearest [T]est" })
    vim.keymap.set("n", "<leader>ntf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "[N]eotest Run tests in [F]ile" })
    vim.keymap.set("n", "<leader>ntd", function() neotest.run.run({strategy = "dap"}) end, { desc = "[N]eotest [D]ebug nearest test" })
    vim.keymap.set("n", "<leader>nts", function() neotest.summary.toggle() end, { desc = "[N]eotest Toggle [S]ummary" })
    vim.keymap.set("n", "<leader>nto", function() neotest.output.open({ enter = true }) end, { desc = "[N]eotest Open [O]utput" })
    vim.keymap.set("n", "<leader>ntp", function() neotest.output_panel.toggle() end, { desc = "[N]eotest Toggle output [P]anel" })
  end,
}