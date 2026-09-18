-- NvChad runtime (ui/base46/volt/minty) and icon provider.
-- NOTE: the `nvchad.*` lua namespace comes from the `nvchad/ui` plugin below.

return {
  "nvim-lua/plenary.nvim",

  {
    "nvchad/base46",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "nvchad/ui",
    lazy = false,
    config = function()
      require "nvchad"
    end,
  },

  "nvzone/volt",
  { "nvzone/minty", cmd = { "Huefy", "Shades" } },

  -- Provides Nerd Font icons (glyphs) for use by Neovim plugins
  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      dofile(vim.g.base46_cache .. "devicons")
      return { override = require "nvchad.icons.devicons" }
    end,
  },
}
