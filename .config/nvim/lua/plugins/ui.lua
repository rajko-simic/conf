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
