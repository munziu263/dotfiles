return {
  -- OSC 52 clipboard integration for remote sessions
  {
    'ojroques/nvim-osc52',
    config = function()
      require('osc52').setup {
        max_length = 0,      -- Maximum length of selection (0 for no limit)
        silent = false,      -- Disable message on successful copy
        trim = false,        -- Trim surrounding whitespaces before copy
      }

      -- Only use OSC 52 when in SSH session or when pbcopy is not available
      local function copy(lines, _)
        if vim.env.SSH_CLIENT or vim.fn.executable('pbcopy') == 0 then
          require('osc52').copy(table.concat(lines, '\n'))
        else
          -- Use system clipboard normally when local
          vim.fn.setreg('+', lines)
        end
      end

      local function paste()
        if vim.env.SSH_CLIENT or vim.fn.executable('pbpaste') == 0 then
          -- In SSH, just return what's in the vim register
          return vim.fn.getreg('+')
        else
          return vim.fn.system('pbpaste')
        end
      end

      -- Override clipboard provider when in SSH
      if vim.env.SSH_CLIENT then
        vim.g.clipboard = {
          name = 'osc52',
          copy = {
            ['+'] = copy,
            ['*'] = copy,
          },
          paste = {
            ['+'] = paste,
            ['*'] = paste,
          },
        }
      end
    end,
  },
}