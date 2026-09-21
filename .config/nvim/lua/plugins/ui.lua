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

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      notifier = {
        style = "minimal",
        top_down = false,
        padding = false,
        width = { min = 1, max = 0.4 },
        margin = { top = 0, right = 1, bottom = 0 },
        timeout = 3000,
        icons = { error = "", warn = "", info = "", debug = "", trace = "" },
      },

      picker = { ui_select = true },
      input = {},
      bigfile = {},
      quickfile = {},
      indent = {
        indent = { char = "│" },
        scope = { char = "│" },
      },
      words = {},
      scope = {},
      gitbrowse = {},
      scratch = {},
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
