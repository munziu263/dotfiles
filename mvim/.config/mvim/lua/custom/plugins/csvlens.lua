return {
  "theKnightsOfRohan/csvlens.nvim",
  dependencies = {
    "akinsho/toggleterm.nvim",
  },
  config = true,
  ft = { "csv", "tsv" },
  keys = {
    { "<leader>cv", "<cmd>Csvlens<cr>", desc = "[C]SV [V]iew", ft = { "csv", "tsv" } },
    { "<leader>ct", "<cmd>Csvlens '\t'<cr>", desc = "[C]SV [T]ab delimiter", ft = { "csv", "tsv" } },
    { "<leader>cp", "<cmd>Csvlens '|'<cr>", desc = "[C]SV [P]ipe delimiter", ft = { "csv", "tsv" } },
    { "<leader>cs", "<cmd>Csvlens ';'<cr>", desc = "[C]SV [S]emicolon delimiter", ft = { "csv", "tsv" } },
  },
}
