# nvim-tree-file-menu

A lazy.nvim plugin that provides enhanced file creation and deletion functionality for nvim-tree.

## Features

- **Ctrl+n**: Create new files with a floating input interface
- **Delete**: Delete files/directories with confirmation dialog
- Shows existing file extensions in the directory for reference
- Persistent insert mode with placeholder handling
- Auto-refresh nvim-tree after operations
- Fully configurable UI and keybindings

## Configuration

```lua
require("nvim-tree-file-menu").setup({
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
})
```

## Usage

1. Focus nvim-tree with `<leader>e`
2. Press `<C-n>` to create a new file
3. Press `<Delete>` to delete a file/directory

## Dependencies

- nvim-tree.lua
- lazy.nvim