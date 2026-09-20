-- Test runner.

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- The adapter ships inside easy-dotnet and reuses its test-runner RPC server,
      -- so no separate discovery or build step. Replaces Nsidorenco/neotest-vstest.
      "GustavEikaas/easy-dotnet.nvim",
    },
    -- `ft`, not `event = "VeryLazy"`: easy-dotnet is a dependency, so a VeryLazy trigger
    -- would drag the whole .NET toolchain (RPC server, Roslyn, testrunner discovery)
    -- into startup for every project -- the exact problem fixed in 3c83a43c. The
    -- <leader>T* maps in mappings.lua still load neotest on demand in any filetype.
    ft = { "cs" },
    config = function()
      require "configs.neotest"
    end,
  },
}
