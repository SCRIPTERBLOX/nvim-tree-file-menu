local M = {}

-- Default configuration
local default_config = {
  add_file_key = '<C-n>',
  delete_key = '<Del>',
  ui = {
    input_width = 40,
    input_height = 1,
    input_row = 5,
    input_col = 10,
    confirm_width = 30,
    confirm_height = 4,
  },
  auto_refresh = true,
}

M.config = default_config

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', default_config, opts or {})
end

return M