return {
  "munziu263/tinker-nvim",
  name = "tinker",
  event = "VeryLazy",
  dependencies = { "akinsho/toggleterm.nvim" },
  config = function()
    require("tinker").setup()
  end,
}
