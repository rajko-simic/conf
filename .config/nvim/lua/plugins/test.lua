-- Test runner.

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "GustavEikaas/easy-dotnet.nvim",
    },
    ft = { "cs" },
    config = function()
      require "configs.neotest"
    end,
  },
}
