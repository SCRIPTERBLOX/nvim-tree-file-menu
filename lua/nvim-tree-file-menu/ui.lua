local M = {}
local config = require("nvim-tree-file-menu.config")

-- Helper function to scan for file extensions
function M.scan_extensions(target_dir)
  local extensions = {}
  local handle = vim.fn.readdir(target_dir)
  for _, file in ipairs(handle) do
    local ext = file:match("^.+%.(.+)$")
    if ext then
      extensions[ext:lower()] = true
    end
  end
  return extensions
end

-- Helper function to create instructions content
function M.create_instructions_content(extensions)
  local instructions_lines = {}
  
  table.insert(instructions_lines, "Press Enter to create file")
  table.insert(instructions_lines, "Press Ctrl+q to cancel")
  table.insert(instructions_lines, "")
  
  local extension_list = {}
  for ext, _ in pairs(extensions) do
    table.insert(extension_list, ext)
  end
  table.sort(extension_list)
  
  if #extension_list > 0 then
    table.insert(instructions_lines, "Existing file extensions:")
    for _, ext in ipairs(extension_list) do
      table.insert(instructions_lines, "  • ." .. ext)
    end
  else
    table.insert(instructions_lines, "No files in this directory")
  end
  
  return instructions_lines
end

-- Helper function to create and show the file input panel
function M.show_input_panel(target_dir, on_confirm)
  local extensions = M.scan_extensions(target_dir)
  local instructions_lines = M.create_instructions_content(extensions)
  local cfg = config.config.ui
  
  -- Create input panel (for filename)
  local input_buf = vim.api.nvim_create_buf(false, true)
  local placeholder = "Filename here"
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {placeholder})
  vim.api.nvim_buf_set_option(input_buf, "modifiable", true)
  
  -- Create instructions panel
  local instructions_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(instructions_buf, 0, -1, false, instructions_lines)
  vim.api.nvim_buf_set_option(instructions_buf, "modifiable", false)
  
  -- Open input panel
  local input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = cfg.input_width,
    height = cfg.input_height,
    row = cfg.input_row,
    col = cfg.input_col,
    border = "rounded",
    style = "minimal"
  })
  
  -- Open instructions panel below input
  local instructions_win = vim.api.nvim_open_win(instructions_buf, false, {
    relative = "editor",
    width = cfg.input_width,
    height = #instructions_lines,
    row = cfg.input_row + 3,
    col = cfg.input_col,
    border = "rounded",
    style = "minimal"
  })
  
  -- Add gray highlight for placeholder and instructions
  vim.api.nvim_buf_add_highlight(input_buf, -1, "Comment", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(instructions_buf, -1, "Comment", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(instructions_buf, -1, "Comment", 1, 0, -1)
  
  return {
    input_buf = input_buf,
    input_win = input_win,
    instructions_buf = instructions_buf,
    instructions_win = instructions_win,
    placeholder = placeholder
  }
end

-- Helper function to create and show the confirmation panel
function M.show_confirmation_panel(node, on_confirm)
  local cfg = config.config.ui
  
  local confirm_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(confirm_buf, 0, -1, false, {
    "Delete " .. node.name .. "?",
    "",
    "  [ No ]  [ Yes ]"
  })
  
  vim.api.nvim_buf_set_option(confirm_buf, "modifiable", false)
  
  -- Center the panel
  local ui = vim.api.nvim_list_uis()[1]
  local width = cfg.confirm_width
  local height = cfg.confirm_height
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  
  local confirm_win = vim.api.nvim_open_win(confirm_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal"
  })
  
  return {
    confirm_buf = confirm_buf,
    confirm_win = confirm_win
  }
end

return M