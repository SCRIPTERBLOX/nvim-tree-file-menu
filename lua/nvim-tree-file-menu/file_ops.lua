local M = {}
local config = require("nvim-tree-file-menu.config")

-- Helper function to determine target directory from nvim-tree cursor
function M.get_target_directory()
  local target_dir
  local ok, tree_api = pcall(require, "nvim-tree.api")
  if ok then
    local node = tree_api.tree.get_node_under_cursor()
    if node and node.type == "directory" then
      target_dir = node.absolute_path
    elseif node then
      target_dir = node.absolute_path:match("(.*/)")
    else
      target_dir = vim.fn.getcwd()
    end
  else
    target_dir = vim.fn.getcwd()
  end
  
  -- Ensure target_dir ends with /
  if target_dir and not target_dir:match("/$") then
    target_dir = target_dir .. "/"
  end
  
  return target_dir
end

-- Helper function to create a file
function M.create_file(filepath)
  local file = io.open(filepath, "w")
  if file then
    file:close()
    return true
  end
  return false
end

-- Helper function to delete a file or directory
function M.delete_node(node)
  local cmd = node.type == "directory" and "rm -rf" or "rm"
  local result = vim.fn.system({cmd, node.absolute_path})
  
  if vim.v.shell_error == 0 then
    return true, ""
  else
    return false, result:gsub("\n", "")
  end
end

-- Helper function to refresh nvim-tree
function M.refresh_tree()
  local ok, tree_api = pcall(require, "nvim-tree.api")
  if ok and config.config.auto_refresh then
    tree_api.tree.reload()
  end
end

return M