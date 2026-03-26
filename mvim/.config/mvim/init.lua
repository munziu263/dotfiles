vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
require("options")
require("keymaps")
require("custom.linting")
require("lazy-bootstrap")
require("lazy-plugins")
print("mvim.config loaded...")
