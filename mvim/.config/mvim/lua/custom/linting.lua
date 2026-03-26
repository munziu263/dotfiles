-- Linting commands: populate quickfix list from ty and ruff
-- Usage:  :TyCheck   :RuffCheck

vim.api.nvim_create_user_command("TyCheck", function()
  -- ty has no concise output mode, so grep the " --> file:line:col" lines
  vim.opt_local.makeprg = [[ty check 2>&1 | grep -P ' --> \S+\.py:\d+' | grep -v '\.venv/']]
  vim.opt_local.errorformat = "%*[ ]--> %f:%l:%c"
  vim.cmd("make!")
  vim.cmd("copen")
end, { desc = "Run ty type checker -> quickfix" })

vim.api.nvim_create_user_command("RuffCheck", function()
  -- concise format: one line per issue, no code context
  vim.opt_local.makeprg = "ruff check --output-format concise ."
  vim.opt_local.errorformat = "%f:%l:%c: %m"
  vim.cmd("make!")
  vim.cmd("copen")
end, { desc = "Run ruff linter -> quickfix" })
