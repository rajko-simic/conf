dofile(vim.g.base46_cache .. "nvimtree")

return {
  filters = { dotfiles = false },
  -- netrw stays enabled so remote editing (:e scp://host//etc/foo.conf) works;
  -- nvim-tree hijacks the netrw *directory* browser instead of replacing netrw.
  disable_netrw = false,
  hijack_netrw = true,
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
    },
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
  -- on_attach = function(bufnr)
  --   local api = require('nvim-tree.api')
  --
  --   local function opts(desc)
  --     return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  --   end
  --
  --   vim.keymap.set('n', 'A', function()
  --     local node = api.tree.get_node_under_cursor()
  --     local path = node.type == "directory" and node.absolute_path or vim.fs.dirname(node.absolute_path)
  --     require("easy-dotnet").create_new_item(path)
  --   end, opts('Create file from dotnet template'))
  -- end
}
