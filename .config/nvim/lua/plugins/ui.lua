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
    config = function(_, opts)
      -- Colors message text by level (hl groups defined in chadrc hl_add)
      local hl = { info = "NoiceNotifyInfo", warn = "NoiceNotifyWarn", error = "NoiceNotifyError" }
      require("noice.text.format.formatters").level_text = function(message, _, input)
        local group = input.level and hl[input.level]
        if group then
          message:append(input:content(), group)
        else
          message:append(input)
        end
      end
      require("noice").setup(opts)
    end,
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
}
