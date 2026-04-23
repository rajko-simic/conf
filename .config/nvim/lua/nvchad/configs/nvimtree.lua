dofile(vim.g.base46_cache .. "nvimtree")

return {
  filters = { dotfiles = false },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    width = 40,
    side = "right",
    preserve_window_proportions = true,
  },
  actions = {
    open_file = {
      resize_window = false,
      window_picker = {
        enable = true,
        picker = "default",
        chars = "ASDFQWERJKLHUIO",
        exclude = {
          filetype = { "dap-view", "dap-view-term", "dap-repl" },
          buftype = { "terminal", "nofile" },
        },
      },
    },
  },
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = true,
    severity = {
      min = vim.diagnostic.severity.WARN,
      max = vim.diagnostic.severity.ERROR,
    }
    -- icons = {
    --   hint = "",
    --   info = "",
    --   warning = "",
    --   error = "",
    -- },
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = { unmerged = "" },
      },
    },
  },
}
