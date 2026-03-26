-- preview.lua: Send image from markdown link to a tmux preview pane
--
-- Setup: title any tmux pane as "preview" with:
--   tmux select-pane -T preview
--
-- Then use <leader>p or gp on a markdown image link to render it there.
local M = {}

M.pane_title = "preview"

--- Resolve an image path relative to the current buffer's directory
local function resolve_path(img_path)
  if img_path:sub(1, 1) == "/" then
    return img_path
  end
  local buf_dir = vim.fn.expand("%:p:h")
  return buf_dir .. "/" .. img_path
end

--- Find the tmux pane ID by its title
local function find_pane_by_title(title)
  local result = vim.fn.system("tmux list-panes -a -F '#{pane_id} #{pane_title}'")
  for line in result:gmatch("[^\n]+") do
    local id, t = line:match("^(%%%d+)%s+(.+)$")
    if t == title then
      return id
    end
  end
  return nil
end

--- Extract image path from markdown image link on or near the current line
local function get_image_path()
  local line = vim.api.nvim_get_current_line()
  local path = line:match("!%[.-%]%((.-)%)")
  if path then
    return resolve_path(path)
  end

  -- Search upward for the nearest image link (useful inside <details> blocks)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  for i = row - 1, math.max(1, row - 10), -1 do
    local prev = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    if prev then
      path = prev:match("!%[.-%]%((.-)%)")
      if path then
        return resolve_path(path)
      end
    end
  end

  return nil
end

--- Send image to the preview tmux pane
function M.show()
  local img = get_image_path()
  if not img then
    vim.notify("No image link found on or near this line", vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(img) == 0 then
    vim.notify("Image not found: " .. img, vim.log.levels.ERROR)
    return
  end

  local pane = find_pane_by_title(M.pane_title)
  if not pane then
    vim.notify(
      "No tmux pane titled '" .. M.pane_title .. "'. Run:  tmux select-pane -T preview",
      vim.log.levels.ERROR
    )
    return
  end

  -- Clear pane and render the image, auto-sized to fit the pane
  local cmd = string.format(
    "tmux send-keys -t %s 'clear && chafa --animate=off --size=\"$(tmux display -p -t %s \"#{pane_width}x#{pane_height}\")\" %s' Enter",
    pane,
    pane,
    vim.fn.shellescape(img)
  )
  vim.fn.system(cmd)
  vim.notify("Preview: " .. vim.fn.fnamemodify(img, ":t"), vim.log.levels.INFO)
end

return M
