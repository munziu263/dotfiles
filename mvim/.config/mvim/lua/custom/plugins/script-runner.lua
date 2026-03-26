-- Script Runner Plugin for Neovim
-- Provides Telescope-based script and config selection with floating terminal execution
--
-- Usage:
-- 1. Create a .script-runner.lua file in your project root to configure runners
-- 2. Use <leader>rs to select and run a script with config
-- 3. Use <leader>rr to re-run the last command
-- 4. Use <leader>rc to edit the project configuration
-- 5. Use <leader>rw / <leader>ri for quick wizard/run-it shortcuts

local ScriptRunner = {}

-- State
ScriptRunner.last_command = nil
ScriptRunner.last_cwd = nil
ScriptRunner.last_runner = nil
ScriptRunner.current_term_bufnr = nil
ScriptRunner.current_runner = nil
ScriptRunner.current_project_root = nil

-- Find project root by looking for common markers
function ScriptRunner.find_project_root()
	local markers = { ".git", ".svn", ".script-runner.lua", "pyproject.toml", "package.json" }
	local path = vim.fn.expand("%:p:h")

	while path ~= "/" do
		for _, marker in ipairs(markers) do
			if vim.fn.isdirectory(path .. "/" .. marker) == 1 or vim.fn.filereadable(path .. "/" .. marker) == 1 then
				return path
			end
		end
		path = vim.fn.fnamemodify(path, ":h")
	end

	return vim.fn.getcwd()
end

-- Load project-specific configuration
function ScriptRunner.load_project_config()
	local root = ScriptRunner.find_project_root()
	local config_path = root .. "/.script-runner.lua"

	if vim.fn.filereadable(config_path) == 1 then
		-- Clear cached version to pick up changes
		package.loaded[config_path] = nil
		local ok, project_config = pcall(dofile, config_path)
		if ok and project_config then
			return project_config, root
		else
			vim.notify("Error loading .script-runner.lua: " .. tostring(project_config), vim.log.levels.ERROR)
		end
	end

	return nil, root
end

-- Get list of files from a directory matching a pattern
function ScriptRunner.get_files(dir, pattern)
	local files = {}
	local expanded_dir = vim.fn.expand(dir)

	if vim.fn.isdirectory(expanded_dir) == 0 then
		return files
	end

	local handle = vim.loop.fs_scandir(expanded_dir)
	if handle then
		while true do
			local name, ftype = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			if ftype == "file" then
				if not pattern or name:match(pattern) then
					table.insert(files, name)
				end
			end
		end
	end

	table.sort(files)
	return files
end

-- Strip ANSI escape codes from text
function ScriptRunner.strip_ansi(text)
	-- Remove all ANSI escape sequences
	return text:gsub("\27%[[%d;]*[A-Za-z]", ""):gsub("\27%].-\27\\", "")
end

-- Save current terminal output to file
function ScriptRunner.save_output()
	local bufnr = ScriptRunner.current_term_bufnr
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		vim.notify("No script runner output to save", vim.log.levels.WARN)
		return
	end

	-- Get buffer lines
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	if #lines == 0 then
		vim.notify("Output buffer is empty", vim.log.levels.WARN)
		return
	end

	-- Strip ANSI codes from each line
	local clean_lines = {}
	for _, line in ipairs(lines) do
		local cleaned = ScriptRunner.strip_ansi(line)
		table.insert(clean_lines, cleaned)
	end

	-- Determine output directory
	local output_dir = ScriptRunner.current_project_root or vim.fn.getcwd()
	if ScriptRunner.current_runner and ScriptRunner.current_runner.output_dir then
		output_dir = output_dir .. "/" .. ScriptRunner.current_runner.output_dir
		-- Create directory if it doesn't exist
		vim.fn.mkdir(output_dir, "p")
	end

	-- Determine basename
	local basename = "script-output"
	if ScriptRunner.current_runner and ScriptRunner.current_runner.output_basename then
		basename = ScriptRunner.current_runner.output_basename
	end

	-- Generate filename with timestamp
	local timestamp = os.date("%Y%m%d-%H%M%S")
	local filename = string.format("%s-%s.log", basename, timestamp)
	local filepath = output_dir .. "/" .. filename

	-- Write to file
	local file = io.open(filepath, "w")
	if file then
		file:write(table.concat(clean_lines, "\n"))
		file:close()
		vim.notify("Output saved to: " .. filepath, vim.log.levels.INFO)
	else
		vim.notify("Failed to save output to: " .. filepath, vim.log.levels.ERROR)
	end
end

-- Run command in floating terminal using toggleterm
function ScriptRunner.run_in_terminal(cmd, cwd, runner_config)
	local Terminal = require("toggleterm.terminal").Terminal

	-- Store for re-run capability
	ScriptRunner.last_command = cmd
	ScriptRunner.last_cwd = cwd
	ScriptRunner.last_runner = runner_config

	-- Store runner config and project root for save functionality
	ScriptRunner.current_runner = runner_config
	ScriptRunner.current_project_root = cwd

	-- Wrap command to show what's being executed at the top
	local display_cmd = string.format(
		'printf "\\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\\n" && '
			.. 'printf "\\033[1;33m▶ Command:\\033[0m %s\\n" && '
			.. 'printf "\\033[1;33m▶ Working Dir:\\033[0m %s\\n" && '
			.. 'printf "\\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m\\n" && '
			.. "echo && %s",
		cmd:gsub('"', '\\"'),
		cwd,
		cmd
	)

	local term = Terminal:new({
		cmd = display_cmd,
		dir = cwd,
		direction = "horizontal",
		size = math.floor(vim.o.lines * 0.5), -- 50% of screen height
		close_on_exit = false, -- Keep open to see output
		on_open = function(t)
			-- Store buffer reference for save functionality
			ScriptRunner.current_term_bufnr = t.bufnr

			-- Set up terminal-mode keymaps to prevent accidental closing
			local opts = { buffer = t.bufnr, silent = true }

			-- Remap Ctrl-D in terminal mode to exit to normal mode + scroll down
			vim.keymap.set("t", "<C-d>", [[<C-\><C-n><C-d>]], opts)
			-- Remap Ctrl-U in terminal mode to exit to normal mode + scroll up
			vim.keymap.set("t", "<C-u>", [[<C-\><C-n><C-u>]], opts)

			-- Buffer-local save output keymap (normal mode)
			vim.keymap.set("n", "<leader>ro", function()
				ScriptRunner.save_output()
			end, { buffer = t.bufnr, desc = "[R]un [O]utput save" })

			vim.cmd("startinsert!")
		end,
	})

	term:toggle()
end

-- Telescope picker for selecting items
function ScriptRunner.telescope_pick(items, opts, on_select)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = opts.prompt_title or "Select",
			finder = finders.new_table({
				results = items,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display or entry.name or entry,
						ordinal = entry.name or entry,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection and on_select then
						on_select(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Main function to run scripts with config selection
function ScriptRunner.run_script()
	local project_config, project_root = ScriptRunner.load_project_config()

	if not project_config or not project_config.runners or #project_config.runners == 0 then
		vim.notify(
			"No runners configured. Create a .script-runner.lua file in your project root.",
			vim.log.levels.WARN
		)
		ScriptRunner.create_example_config()
		return
	end

	-- Step 1: Select a runner
	local runner_items = {}
	for _, runner in ipairs(project_config.runners) do
		table.insert(runner_items, {
			name = runner.name,
			display = runner.name .. " (" .. runner.description .. ")",
			runner = runner,
		})
	end

	ScriptRunner.telescope_pick(runner_items, {
		prompt_title = "Select Runner",
	}, function(selected_runner)
		local runner = selected_runner.runner
		local scripts_dir = project_root .. "/" .. runner.scripts_dir
		local configs_dir = project_root .. "/" .. runner.configs_dir

		-- Step 2: Select a script
		local scripts = ScriptRunner.get_files(scripts_dir, runner.script_pattern)
		if #scripts == 0 then
			vim.notify("No scripts found in " .. scripts_dir, vim.log.levels.WARN)
			return
		end

		local script_items = {}
		for _, script in ipairs(scripts) do
			table.insert(script_items, {
				name = script,
				display = script,
				path = scripts_dir .. "/" .. script,
			})
		end

		ScriptRunner.telescope_pick(script_items, {
			prompt_title = "Select Script",
		}, function(selected_script)
			-- Step 3: Select a config
			local configs = ScriptRunner.get_files(configs_dir, runner.config_pattern)
			if #configs == 0 then
				vim.notify("No configs found in " .. configs_dir, vim.log.levels.WARN)
				return
			end

			local config_items = {}
			for _, config in ipairs(configs) do
				table.insert(config_items, {
					name = config,
					display = config,
					path = configs_dir .. "/" .. config,
				})
			end

			ScriptRunner.telescope_pick(config_items, {
				prompt_title = "Select Config",
			}, function(selected_config)
				-- Build and run the command
				local cmd = runner.command_template
				cmd = cmd:gsub("{script}", selected_script.path)
				cmd = cmd:gsub("{script_name}", selected_script.name:gsub("%.py$", ""))
				cmd = cmd:gsub("{config}", selected_config.path)
				cmd = cmd:gsub("{config_name}", selected_config.name)
				cmd = cmd:gsub("{project_root}", project_root)

				-- Handle module-style execution
				if runner.use_module then
					local module_path = runner.scripts_dir:gsub("/", ".") .. "." .. selected_script.name:gsub("%.py$", "")
					cmd = cmd:gsub("{module}", module_path)
				end

				vim.notify("Running: " .. cmd, vim.log.levels.INFO)
				ScriptRunner.run_in_terminal(cmd, project_root, runner)
			end)
		end)
	end)
end

-- Re-run the last command
function ScriptRunner.rerun_last()
	if ScriptRunner.last_command then
		vim.notify("Re-running: " .. ScriptRunner.last_command, vim.log.levels.INFO)
		ScriptRunner.run_in_terminal(ScriptRunner.last_command, ScriptRunner.last_cwd, ScriptRunner.last_runner)
	else
		vim.notify("No previous command to re-run", vim.log.levels.WARN)
	end
end

-- Prompt user for argument input
function ScriptRunner.prompt_for_args(prompt_text, default_value, callback)
	vim.ui.input({
		prompt = prompt_text or "Enter arguments: ",
		default = default_value or "",
	}, function(input)
		if input ~= nil then -- nil means cancelled
			callback(input)
		end
	end)
end

-- Build command with substitutions, only replacing placeholders that have values
function ScriptRunner.build_command(template, substitutions)
	local cmd = template
	for placeholder, value in pairs(substitutions) do
		if value and value ~= "" then
			cmd = cmd:gsub(placeholder, value)
		end
	end
	return cmd
end

-- Quick run: select config only for a predefined runner
function ScriptRunner.quick_run(runner_name)
	local project_config, project_root = ScriptRunner.load_project_config()

	if not project_config then
		vim.notify("No .script-runner.lua found", vim.log.levels.WARN)
		return
	end

	local runner = nil
	for _, r in ipairs(project_config.runners) do
		if r.name == runner_name then
			runner = r
			break
		end
	end

	if not runner then
		vim.notify("Runner '" .. runner_name .. "' not found", vim.log.levels.WARN)
		return
	end

	-- Check if this runner needs args instead of config
	if runner.needs_args then
		ScriptRunner.prompt_for_args(runner.args_prompt, runner.args_default, function(args)
			local cmd = runner.quick_command or runner.command_template
			cmd = ScriptRunner.build_command(cmd, {
				["{args}"] = args,
				["{project_root}"] = project_root,
			})
			vim.notify("Running: " .. cmd, vim.log.levels.INFO)
			ScriptRunner.run_in_terminal(cmd, project_root, runner)
		end)
		return
	end

	-- Check if config selection should be skipped
	if runner.no_config then
		local cmd = runner.quick_command or runner.command_template
		cmd = ScriptRunner.build_command(cmd, {
			["{project_root}"] = project_root,
		})
		vim.notify("Running: " .. cmd, vim.log.levels.INFO)
		ScriptRunner.run_in_terminal(cmd, project_root, runner)
		return
	end

	local configs_dir = project_root .. "/" .. runner.configs_dir
	local configs = ScriptRunner.get_files(configs_dir, runner.config_pattern)

	if #configs == 0 then
		vim.notify("No configs found in " .. configs_dir, vim.log.levels.WARN)
		return
	end

	local config_items = {}
	for _, config in ipairs(configs) do
		table.insert(config_items, {
			name = config,
			display = config,
			path = configs_dir .. "/" .. config,
		})
	end

	ScriptRunner.telescope_pick(config_items, {
		prompt_title = "Select Config for " .. runner_name,
	}, function(selected_config)
		local cmd = runner.quick_command or runner.command_template

		-- If runner also wants args after config selection
		if runner.also_needs_args then
			ScriptRunner.prompt_for_args(runner.args_prompt, runner.args_default, function(args)
				cmd = ScriptRunner.build_command(cmd, {
					["{config}"] = selected_config.path,
					["{config_name}"] = selected_config.name,
					["{project_root}"] = project_root,
					["{args}"] = args,
				})
				vim.notify("Running: " .. cmd, vim.log.levels.INFO)
				ScriptRunner.run_in_terminal(cmd, project_root, runner)
			end)
		else
			cmd = ScriptRunner.build_command(cmd, {
				["{config}"] = selected_config.path,
				["{config_name}"] = selected_config.name,
				["{project_root}"] = project_root,
			})
			vim.notify("Running: " .. cmd, vim.log.levels.INFO)
			ScriptRunner.run_in_terminal(cmd, project_root, runner)
		end
	end)
end

-- Create example configuration file
function ScriptRunner.create_example_config()
	local root = ScriptRunner.find_project_root()
	local config_path = root .. "/.script-runner.lua"

	if vim.fn.filereadable(config_path) == 1 then
		vim.cmd("edit " .. config_path)
		return
	end

	local example = [[
-- Script Runner Configuration
-- This file configures how scripts are run with config files
--
-- Each runner defines:
--   name: Display name for the runner
--   description: Short description
--   scripts_dir: Directory containing scripts (relative to project root)
--   configs_dir: Directory containing config files (relative to project root)
--   script_pattern: Lua pattern to filter script files (optional)
--   config_pattern: Lua pattern to filter config files (optional)
--   command_template: Command to run, with placeholders:
--     {script} - Full path to selected script
--     {script_name} - Script filename without extension
--     {config} - Full path to selected config
--     {config_name} - Config filename
--     {project_root} - Project root directory
--     {module} - Python module path (when use_module=true)
--   use_module: If true, runs Python scripts as modules (python -m)
--   quick_command: Optional simplified command for quick_run (config-only selection)
--   output_dir: Directory for saved output logs (relative to project root, optional)
--   output_basename: Prefix for output filenames (optional, defaults to "script-output")
--
-- Output Saving:
--   Press <leader>ro in the output terminal to save output to a file.
--   Files are named: {output_basename}-YYYYMMDD-HHMMSS.log

return {
  runners = {
    {
      name = "Debug Wizard",
      description = "Run wizard debug scripts",
      scripts_dir = "scripts",
      configs_dir = "scripts/configs",
      script_pattern = "^debug.*%.py$",
      config_pattern = "%.yaml$",
      command_template = "python -m scripts.{script_name} {config}",
      use_module = true,
      quick_command = "python -m scripts.debug_wizard {config}",
      output_dir = "logs",        -- saves to {project}/logs/
      output_basename = "wizard", -- wizard-20231215-143022.log
    },
    {
      name = "Run It",
      description = "Full pipeline runner",
      scripts_dir = "scripts",
      configs_dir = "scripts/configs",
      script_pattern = "^run.*%.py$",
      config_pattern = "^wizard.*%.yaml$",
      command_template = "python -m scripts.{script_name} {config}",
      use_module = true,
      quick_command = "python -m scripts.run_it {config}",
      -- output_dir and output_basename are optional
      -- defaults to project root and "script-output" prefix
    },
  },
}
]]

	local file = io.open(config_path, "w")
	if file then
		file:write(example)
		file:close()
		vim.notify("Created .script-runner.lua in " .. root, vim.log.levels.INFO)
		vim.cmd("edit " .. config_path)
	else
		vim.notify("Failed to create config file", vim.log.levels.ERROR)
	end
end

-- Edit the project configuration
function ScriptRunner.edit_config()
	local root = ScriptRunner.find_project_root()
	local config_path = root .. "/.script-runner.lua"

	if vim.fn.filereadable(config_path) == 1 then
		vim.cmd("edit " .. config_path)
	else
		ScriptRunner.create_example_config()
	end
end

-- Lazy.nvim plugin spec
-- Use a local plugin approach to avoid conflicting with existing telescope config
return {
	dir = vim.fn.stdpath("config") .. "/lua/custom/plugins",
	name = "script-runner",
	event = "VeryLazy",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"akinsho/toggleterm.nvim",
	},
	config = function()
		-- Register keymaps
		vim.keymap.set("n", "<leader>rs", function()
			ScriptRunner.run_script()
		end, { desc = "[R]un [S]cript with config" })

		vim.keymap.set("n", "<leader>rr", function()
			ScriptRunner.rerun_last()
		end, { desc = "[R]e-[R]un last command" })

		vim.keymap.set("n", "<leader>rc", function()
			ScriptRunner.edit_config()
		end, { desc = "[R]un [C]onfig edit" })

		vim.keymap.set("n", "<leader>rw", function()
			ScriptRunner.quick_run("Debug Wizard")
		end, { desc = "[R]un [W]izard (quick)" })

		vim.keymap.set("n", "<leader>ri", function()
			ScriptRunner.quick_run("Run It")
		end, { desc = "[R]un [I]t (quick)" })

		vim.keymap.set("n", "<leader>ra", function()
			ScriptRunner.quick_run("Wizard Analysis")
		end, { desc = "[R]un [A]nalysis (quick)" })

		vim.keymap.set("n", "<leader>ro", function()
			ScriptRunner.save_output()
		end, { desc = "[R]un [O]utput save" })

		-- Register user commands
		vim.api.nvim_create_user_command("ScriptRun", function()
			ScriptRunner.run_script()
		end, { desc = "Run script with config selection" })

		vim.api.nvim_create_user_command("ScriptRerun", function()
			ScriptRunner.rerun_last()
		end, { desc = "Re-run last script" })

		vim.api.nvim_create_user_command("ScriptConfig", function()
			ScriptRunner.edit_config()
		end, { desc = "Edit script runner config" })

		vim.api.nvim_create_user_command("ScriptQuick", function(opts)
			ScriptRunner.quick_run(opts.args)
		end, {
			nargs = 1,
			complete = function()
				local project_config, _ = ScriptRunner.load_project_config()
				if project_config and project_config.runners then
					local names = {}
					for _, runner in ipairs(project_config.runners) do
						table.insert(names, runner.name)
					end
					return names
				end
				return {}
			end,
			desc = "Quick run with config selection only",
		})
	end,
}
