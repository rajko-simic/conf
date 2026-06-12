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
  "nvzone/menu",
  "rafamadriz/friendly-snippets",
  "pmizio/typescript-tools.nvim",
  { "nvzone/minty", cmd = { "Huefy", "Shades" } },



  -- Provides Nerd Font icons (glyphs) for use by Neovim plugins
  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      dofile(vim.g.base46_cache .. "devicons")
      return { override = require "nvchad.icons.devicons" }
    end,
  },

  -- Lightweight icon provider (alongside devicons; NvChad base46 highlights unaffected)
  {
    "echasnovski/mini.icons",
    version = false,
    lazy = false,
    opts = {},
  },

  -- Indentation guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "User FilePost",
    opts = function() return require("nvchad.configs.indentblankline").opts end,
    config = function(_, opts) require("nvchad.configs.indentblankline").config(_, opts) end,
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      return require "nvchad.configs.nvimtree"
    end,
  },

  -- Keymap hints popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    cmd = "WhichKey",
    opts = require("nvchad.configs.whichkey"),
  },

  -- Formatter
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { lua = { "stylua" } },
    },
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "nvchad.configs.gitsigns"
    end,
  },

  -- Git UI
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- LSP package manager
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function()
      return require("nvchad.configs.mason").opts
    end,
    config = function(_, opts)
      require("nvchad.configs.mason").config(_, opts)
    end,
  },

  -- LSP config
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
    end,
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    build = "cargo build --release",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = require("nvchad.configs.blink"),
  },

  { "b0o/schemastore.nvim" },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = function()
      return require "nvchad.configs.telescope"
    end,
  },

  -- Project manager
  {
    "coffebar/neovim-project",
    lazy = false,
    priority = 100,
    opts = function()
      return require "nvchad.configs.neovim-project"
    end,
    init = function()
      vim.opt.sessionoptions:append("globals")
    end,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
      { "Shatur/neovim-session-manager" },
    },
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = function() require("nvchad.configs.treesitter").build() end,
    init = function() require("nvchad.configs.treesitter").init() end,
    config = function() require("nvchad.configs.treesitter").config() end,
  },

  -- Sticky context header
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "User FilePost",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },

  -- Debug adapter protocol
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      require "nvchad.configs.dap"
    end,
  },

  -- DAP UI
  {
    "igorlfs/nvim-dap-view",
    event = "VeryLazy",
    version = "1.*",
    config = function()
      require "nvchad.configs.dapview"
    end,
  },

  -- DAP virtual text (variable values inline while debugging)
  {
    "theHamsta/nvim-dap-virtual-text",
    event = "VeryLazy",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require "nvchad.configs.dapvirtualtext"
    end,
  },

  -- Async IO library
  {
    "nvim-neotest/nvim-nio",
    requires = { "mfussenegger/nvim-dap" },
  },

  -- Test runner
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "Nsidorenco/neotest-vstest",
    },
    event = "VeryLazy",
    config = function()
      require "nvchad.configs.neotest"
    end,
  },

  -- Notification UI
  {
    "rcarriga/nvim-notify",
    config = function()
      require "nvchad.configs.notify"
    end,
  },

  -- Diagnostics list
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    config = function() require "nvchad.configs.trouble" end,
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

  -- Markdown / HTML / LaTeX previewer
  -- {
  --   "OXY2DEV/markview.nvim",
  --   ft = { "markdown", "rmd", "quarto", "mdx", "html", "latex" },
  --   lazy = false,
  --   priority = 49,
  -- },

  {
      'MeanderingProgrammer/render-markdown.nvim',
      ft = "markdown",
      dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
      ---@module 'render-markdown'
      ---@type render.md.UserConfig
      opts = {},
  },

  {
    "yousefhadder/markdown-plus.nvim",
    ft = "markdown",
    opts = {},
  },

  -- Motion hints
  {
    "tris203/precognition.nvim",
    cmd = { "Precognition" },
    opts = {},
  },

  -- References, definitions and implementations above symbols
  {
    'Wansmer/symbol-usage.nvim',
    event = 'LspAttach',
    config = function()
      require 'nvchad.configs.symbolusage'
    end,
  },

  -- Dotnet / C#
  {
    "GustavEikaas/easy-dotnet.nvim",
    ft = { "cs", "csproj", "sln", "slnx", "props", "csx", "targets" },
    cmd = { "Dotnet" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      require "nvchad.configs.easydotnet"
    end,
  },

  -- Flutter
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = { "dart", "pubspec.yaml" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("flutter-tools").setup({})
      pcall(require("telescope").load_extension, "flutter")
    end,
  },

  {
    "akinsho/pubspec-assist.nvim",
    ft = { "dart", "pubspec.yaml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = require("nvchad.configs.noice"), -- adjust path to match your setup
  },

  -- Window layout manager
  -- {
  --   "folke/edgy.nvim",
  --   event = "VeryLazy",
  --   init = function()
  --     vim.opt.laststatus = 3
  --     vim.opt.splitkeep = "screen"
  --   end,
  --   opts = function()
  --     return require "nvchad.configs.edgy"
  --   end,
  -- },

  -- LSP UI (peek definition, line diagnostics, code action picker)
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = function()
      return require "nvchad.configs.lspsaga"
    end,
    config = function(_, opts)
      require("lspsaga").setup(opts)
    end,
  },

}
