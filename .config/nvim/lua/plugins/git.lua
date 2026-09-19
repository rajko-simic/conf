-- Git integration.

return {
  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "configs.gitsigns"
    end,
  },

  -- Git UI is snacks.lazygit (lua/plugins/ui.lua); it layers its theme onto the
  -- existing ~/.config/lazygit/config.yml rather than replacing it.
}
