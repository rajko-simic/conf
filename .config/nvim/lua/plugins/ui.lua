-- Editor chrome: notifications, cmdline, file tree, keymap hints, guides.

return {
  -- Cmdline / messages / popupmenu / notification UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = require "configs.noice",
  },

  -- Notification backend behind noice.
  --
  -- noice's own `mini` view cannot replace a notification in place (no merge/replace in
  -- view/backend/mini.lua), so any plugin that animates a spinner by re-notifying on a
  -- timer stacks one line per tick. snacks' notifier honours the `id` that such plugins
  -- pass, so the line updates instead.
  --
  -- Only the notifier module is on: Snacks.setup enables exactly the keys it is handed,
  -- so picker/dashboard/input/terminal/lazygit stay off and do not collide with
  -- telescope, dressing, nvchad.term, nvdash or lazygit.nvim.
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      notifier = {
        -- `minimal` sets border = "none" and renders the message only -- as close to the
        -- old noice `mini` view as stock options get.
        style = "minimal",
        top_down = false,
        padding = false,
        width = { min = 1, max = 0.4 },
        margin = { top = 0, right = 1, bottom = 0 },
        timeout = 3000,
        icons = { error = "", warn = "", info = "", debug = "", trace = "" },
      },

      -- `ui_select` is the point of enabling the picker: it replaces vim.ui.select,
      -- which is otherwise nvim's bare numbered prompt (dressing only ever loaded for
      -- dart files). That covers the `\` toolchain menus, ansible-doc, <leader>dB and
      -- every other prompt. Telescope keeps its own keymaps -- nothing here rebinds them.
      picker = { ui_select = true },
      input = {},

      -- Passive. bigfile turns off treesitter/LSP/syntax past ~1.5MB or ~1000 char
      -- average line length, which matters for terraform state, generated yaml and logs.
      bigfile = {},
      quickfile = {},

      -- Indent guides + scope highlighting, replacing indent-blankline.
      indent = {
        indent = { char = "│" },
        scope = { char = "│" },
      },

      -- LSP reference highlighting; ]] / [[ are mapped in mappings.lua.
      words = {},

      -- Registers its own ii/ai textobjects and [i/]i jumps (all verified unmapped).
      scope = {},

      gitbrowse = {},
      scratch = {},

      -- Replaces NvChad's nvdash (disabled in chadrc.lua).
      dashboard = require("configs.dashboard").opts,
    },
  },

  -- Keymap hints popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    cmd = "WhichKey",
    opts = require "configs.whichkey",
  },

  -- Indentation guides
  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      return require "configs.nvimtree"
    end,
  },

  -- Motion hints
  {
    "tris203/precognition.nvim",
    cmd = { "Precognition" },
    opts = {},
  },
}
