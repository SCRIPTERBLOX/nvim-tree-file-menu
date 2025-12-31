local M = {}
local config = require("nvim-tree-file-menu.config")
local ui = require("nvim-tree-file-menu.ui")
local file_ops = require("nvim-tree-file-menu.file_ops")

-- Helper function to check if nvim-tree is focused
local function is_nvim_tree_focused()
  local current_buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(current_buf)
  return string.find(buf_name, "NvimTree") ~= nil
end

-- Main file creation function
function M.create_file()
  if not is_nvim_tree_focused() then
    return
  end
  
  local target_dir = file_ops.get_target_directory()
  if not target_dir then
    print("Could not determine target directory")
    return
  end
  
  local panels = ui.show_input_panel(target_dir)
  local need_clear = true
  
  -- Set up autocmd group
  local group = vim.api.nvim_create_augroup("FileInputPanel", {})
  
  -- Clear placeholder after first character is typed
  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = panels.input_buf,
    group = group,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(panels.input_buf, 0, -1, false)
      local text = lines[1] or ""
      
      -- If we still have placeholder and text changed, clear it
      if need_clear and text ~= panels.placeholder then
        if text:find(panels.placeholder) then
          local cleaned = text:gsub(panels.placeholder, "")
          vim.api.nvim_buf_set_lines(panels.input_buf, 0, -1, false, {cleaned})
        end
        vim.api.nvim_buf_clear_namespace(panels.input_buf, -1, 0, -1)
        need_clear = false
      -- If text is empty, restore placeholder
      elseif not need_clear and #text == 0 then
        vim.api.nvim_buf_set_lines(panels.input_buf, 0, -1, false, {panels.placeholder})
        vim.api.nvim_buf_add_highlight(panels.input_buf, -1, "Comment", 0, 0, -1)
        vim.api.nvim_win_set_cursor(panels.input_win, {1, 0})
        need_clear = true
      end
    end
  })
  
  -- Prevent leaving insert mode
  vim.api.nvim_create_autocmd("ModeChanged", {
    buffer = panels.input_buf,
    callback = function()
      local mode = vim.api.nvim_get_mode().mode
      if mode ~= "i" then
        vim.cmd("startinsert!")
      end
    end
  })
  
  -- Block keys that could exit insert mode
  local block_keys = {'<C-[>', '<C-c>'}
  for _, key in ipairs(block_keys) do
    vim.api.nvim_buf_set_keymap(panels.input_buf, 'i', key, '', {
      callback = function() end
    })
  end
  
  -- Cancel key handlers
  local function cleanup_and_close()
    vim.api.nvim_del_augroup_by_name("FileInputPanel")
    vim.cmd("stopinsert")
    vim.api.nvim_win_close(panels.input_win, true)
    vim.api.nvim_win_close(panels.instructions_win, true)
  end
  
  vim.api.nvim_buf_set_keymap(panels.input_buf, 'i', '<C-q>', '', {
    callback = cleanup_and_close
  })
  
  vim.api.nvim_buf_set_keymap(panels.input_buf, 'i', '<Esc>', '', {
    callback = cleanup_and_close
  })
  
  -- Prevent leaving the input window
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = panels.input_buf,
    callback = function()
      vim.api.nvim_set_current_win(panels.input_win)
    end
  })
  
  -- Handle Enter key to create file
  vim.api.nvim_buf_set_keymap(panels.input_buf, 'i', '<CR>', '', {
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(panels.input_buf, 0, -1, false)
      local filename = lines[1] and lines[1]:gsub("^%s+", ""):gsub("%s+$", "") or ""
      
      if filename ~= "" and filename ~= panels.placeholder then
        local filepath = target_dir .. filename
        if file_ops.create_file(filepath) then
          print("Created file: " .. filepath)
          file_ops.refresh_tree()
        else
          print("Failed to create file: " .. filepath)
        end
      end
      
      cleanup_and_close()
    end
  })
  
  -- Focus input panel and enter insert mode
  vim.api.nvim_set_current_win(panels.input_win)
  vim.cmd("startinsert")
end

-- Main delete function
function M.delete_node()
  if not is_nvim_tree_focused() then
    return
  end
  
  local ok, tree_api = pcall(require, "nvim-tree.api")
  if not ok then
    print("nvim-tree.api not available")
    return
  end
  
  local node = tree_api.tree.get_node_under_cursor()
  if not node then
    print("No node selected")
    return
  end
  
  local panels = ui.show_confirmation_panel(node)
  local selection = 0 -- 0 = No, 1 = Yes
  
  -- Update button highlighting
  local function update_buttons()
    vim.api.nvim_buf_clear_namespace(panels.confirm_buf, -1, 0, -1)
    
    if selection == 0 then
      vim.api.nvim_buf_add_highlight(panels.confirm_buf, -1, "Visual", 2, 2, 7)
      vim.api.nvim_buf_add_highlight(panels.confirm_buf, -1, "Comment", 2, 9, -1)
    else
      vim.api.nvim_buf_add_highlight(panels.confirm_buf, -1, "Comment", 2, 2, 9)
      vim.api.nvim_buf_add_highlight(panels.confirm_buf, -1, "Visual", 2, 11, 16)
    end
  end
  
  update_buttons()
  
  -- Navigation key handlers
  local function set_selection(sel)
    selection = sel
    update_buttons()
  end
  
  vim.api.nvim_buf_set_keymap(panels.confirm_buf, 'n', '<Left>', '', {
    callback = function() set_selection(0) end
  })
  
  vim.api.nvim_buf_set_keymap(panels.confirm_buf, 'n', '<Right>', '', {
    callback = function() set_selection(1) end
  })
  
  vim.api.nvim_buf_set_keymap(panels.confirm_buf, 'n', '<h>', '', {
    callback = function() set_selection(0) end
  })
  
  vim.api.nvim_buf_set_keymap(panels.confirm_buf, 'n', '<l>', '', {
    callback = function() set_selection(1) end
  })
  
  -- Enter key handling
  vim.api.nvim_buf_set_keymap(panels.confirm_buf, 'n', '<CR>', '', {
    callback = function()
      if selection == 1 then
        local success, error_msg = file_ops.delete_node(node)
        if success then
          print("Deleted: " .. node.name)
          file_ops.refresh_tree()
        else
          print("Failed to delete: " .. error_msg)
        end
      else
        print("Cancelled deletion")
      end
      
      vim.api.nvim_win_close(panels.confirm_win, true)
    end
  })
  
  -- Escape key to cancel
  vim.api.nvim_buf_set_keymap(panels.confirm_buf, 'n', '<Esc>', '', {
    callback = function()
      print("Cancelled deletion")
      vim.api.nvim_win_close(panels.confirm_win, true)
    end
  })
end

-- Setup function to configure keybindings
function M.setup(opts)
  config.setup(opts)
  local cfg = config.config
  
  -- Set up keybindings only in nvim-tree context
  vim.keymap.set('n', cfg.add_file_key, function()
    M.create_file()
  end, { desc = "Create file in nvim-tree" })
  
  vim.keymap.set('n', cfg.delete_key, function()
    M.delete_node()
  end, { desc = "Delete node in nvim-tree" })
end

-- Lazy.nvim plugin specification
M.spec = {
  name = "nvim-tree-file-menu",
  dir = vim.fn.stdpath("config") .. "/nvim-tree-file-menu",
  config = function()
    require("nvim-tree-file-menu").setup()
  end,
  keys = {
    "<C-n>",
    "<Delete>",
  },
  dependencies = {
    "nvim-tree/nvim-tree.lua",
  },
}

return M