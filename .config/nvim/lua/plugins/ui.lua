-- Editor chrome: notifications, cmdline, file tree, keymap hints, guides.

return {
  -- Notification UI
  {
    "rcarriga/nvim-notify",
    config = function()
      require "configs.notify"
    end,
  },

  -- Cmdline / messages / popupmenu UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = require "configs.noice",
  },

  -- Keymap hints popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    cmd = "WhichKey",
    opts = require "configs.whichkey",
  },

  -- Indentation guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "User FilePost",
    opts = function()
      return require("configs.indentblankline").opts
    end,
    config = function(_, opts)
      require("configs.indentblankline").config(_, opts)
    end,
  },

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

  -- Window layout manager (config kept in configs/edgy.lua)
  -- {
  --   "folke/edgy.nvim",
  --   event = "VeryLazy",
  --   init = function()
  --     vim.opt.laststatus = 3
  --     vim.opt.splitkeep = "screen"
  --   end,
  --   opts = function()
  --     return require "configs.edgy"
  --   end,
  -- },
}
