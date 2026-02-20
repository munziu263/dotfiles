return { 
    'echasnovski/mini.nvim', 
    config = function()
        require("mini.statusline").setup{use_icons = true}
        require("mini.ai").setup{use_icons = true}
        require("mini.surround").setup{use_icons = true}
        require("mini.pairs").setup{use_icons = true}
    end,
    version = '*' 
}
