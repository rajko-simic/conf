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

  -- Undo history tree
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeFocus" },
    init = function()
      vim.g.undotree_WindowLayout = 2 -- tree left, diff panel full-width at the bottom
      vim.g.undotree_SetFocusWhenToggle = 1 -- land in the tree so J/K work immediately
      vim.g.undotree_ShortIndicators = 1 -- "5 s" / "2 m" timestamps, 24-col panel
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

  -- Refactoring tools (loads on first require from a <leader>r* keymap)
  {
    "ThePrimeagen/refactoring.nvim",
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
