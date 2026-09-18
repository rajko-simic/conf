-- Debug Adapter Protocol stack. Adapters live in configs/dap.lua.

return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      require "configs.dap"
    end,
  },

  -- DAP UI
  {
    "igorlfs/nvim-dap-view",
    event = "VeryLazy",
    version = "1.*",
    config = function()
      require "configs.dapview"
    end,
  },

  -- DAP virtual text (variable values inline while debugging)
  {
    "theHamsta/nvim-dap-virtual-text",
    event = "VeryLazy",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require "configs.dapvirtualtext"
    end,
  },

  -- Async IO library (also a neotest dependency)
  "nvim-neotest/nvim-nio",
}
