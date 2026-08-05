-- Core editing: fuzzy finding, syntax, formatting, refactoring, projects.

return {
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = function()
      return require "configs.telescope"
    end,
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = function()
      require("configs.treesitter").build()
    end,
    init = function()
      require("configs.treesitter").init()
    end,
    config = function()
      require("configs.treesitter").config()
    end,
  },

  -- Sticky context header
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "User FilePost",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },

  -- Formatter
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- Refactoring tools
  {
    "ThePrimeagen/refactoring.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "lewis6991/async.nvim",
    },
    opts = {},
  },

  -- Project manager
  {
    "coffebar/neovim-project",
    lazy = false,
    priority = 100,
    opts = function()
      return require "configs.neovim-project"
    end,
    init = function()
      vim.opt.sessionoptions:append "globals"
    end,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
      { "Shatur/neovim-session-manager" },
    },
  },
}
