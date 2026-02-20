return { 
    "catppuccin/nvim", 
    name = "catppuccin", 
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            custom_highlights = function(colors)
                return {
                    -- Make cursor more visible with inverted colors
                    Cursor = { fg = colors.base, bg = colors.text },
                    lCursor = { fg = colors.base, bg = colors.text },
                    CursorIM = { fg = colors.base, bg = colors.text },
                }
            end,
        })
        vim.cmd.colorscheme "catppuccin-mocha"
    end, 
}
