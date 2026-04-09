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
  { "nvzone/minty", cmd = { "Huefy", "Shades" } },

  --Provides Nerd Font 1 icons (glyphs) for use by Neovim plugins:
  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      dofile(vim.g.base46_cache .. "devicons")
      return { override = require "nvchad.icons.devicons" }
    end,
  },

  --This plugin adds indentation guides to Neovim
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "User FilePost",
    opts = {
      indent = { char = "│", highlight = "IblChar" },
      scope = { char = "│", highlight = "IblScopeChar" },
    },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "blankline")

      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
      require("ibl").setup(opts)

      dofile(vim.g.base46_cache .. "blankline")
    end,
  },

  -- file managing , picker etc
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      return require "nvchad.configs.nvimtree"
    end,
  },

  --WhichKey helps you remember your Neovim keymaps, by showing available keybindings in a popup as you type.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    -- keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    opts = function()
      dofile(vim.g.base46_cache .. "whichkey")
      return {
        defer = function()
          return false
        end,
      }
    end,
  },


  --Lightweight yet powerful formatter plugin for Neovim
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { lua = { "stylua" } },
    },
  },

  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "nvchad.configs.gitsigns"
    end,
  },

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
  },

  -- lsp stuff
  {
    "mason-org/mason.nvim",
    -- lazy = false,
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function()
      return require("nvchad.configs.mason").opts
    end,
    config = function(_, opts)
      require("nvchad.configs.mason").config(_, opts)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
    end,
  },

  {
    "saghen/blink.cmp",
    version = "1.*",
    build = "cargo build --release",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = require("nvchad.configs.blink"),
  },

-- {
--     "ray-x/lsp_signature.nvim",
--     event = "InsertEnter",
--     opts = {
--       bind = true,
--       handler_opts = {
--         border = "rounded"
--       }
--     },
--     -- or use config
--     -- config = function(_, opts) require'lsp_signature'.setup({you options}) end
--   },

  -- load luasnips + cmp related in insert mode only
  --A completion engine
  -- {
  --   "hrsh7th/nvim-cmp",
  --   event = "InsertEnter",
  --   dependencies = {
  --     {
  --       -- snippet plugin
  --       "L3MON4D3/LuaSnip",
  --       dependencies = "rafamadriz/friendly-snippets",
  --       opts = { history = true, updateevents = "TextChanged,TextChangedI" },
  --       config = function(_, opts)
  --         require("luasnip").config.set_config(opts)
  --         require "nvchad.configs.luasnip"
  --       end,
  --     },
  --
  --     -- autopairing of (){}[] etc
  --     {
  --       "windwp/nvim-autopairs",
  --       opts = {
  --         fast_wrap = {},
  --         disable_filetype = { "TelescopePrompt", "vim" },
  --       },
  --       config = function(_, opts)
  --         require("nvim-autopairs").setup(opts)
  --
  --         -- setup cmp for autopairs
  --         local cmp_autopairs = require "nvim-autopairs.completion.cmp"
  --         require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
  --       end,
  --     },
  --
  --     -- cmp sources plugins
  --     {
  --       "saadparwaiz1/cmp_luasnip",
  --       "hrsh7th/cmp-nvim-lua",
  --       "hrsh7th/cmp-nvim-lsp",
  --       "hrsh7th/cmp-buffer",
  --       "hrsh7th/cmp-path",
  --     },
  --   },
  --   opts = function()
  --     return require "nvchad.configs.cmp"
  --   end,
  -- },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Telescope",
    opts = function()
      return require "nvchad.configs.telescope"
    end,
  },

  {
    "coffebar/neovim-project",
    lazy = false,
    priority = 100,
    opts = function()
      return require "nvchad.configs.neovim-project"
    end,
    init = function()
      -- enable saving the state of plugins in the session
      vim.opt.sessionoptions:append("globals")
    end,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
      { "Shatur/neovim-session-manager" },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup(require("nvchad.configs.treesitter"))
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    lazy = false;
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {}
  },

  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      require "nvchad.configs.dap"
    end,
  },

  {
      "igorlfs/nvim-dap-view",
      -- let the plugin lazy load itself
      lazy = false,
      version = "1.*",
      ---@module 'dap-view'
      ---@type dapview.Config
      opts = {},
    },

  -- {
  --   "rcarriga/nvim-dap-ui",
  --   lazy = false;
  --   dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  --   config = function()
  --     require "nvchad.configs.dapui"
  --   end,
  -- },

  {
    "https://codeberg.org/Jorenar/nvim-dap-disasm.git",
    lazy=false;
    dependencies = "igorlfs/nvim-dap-view",
    config = function ()
      require "nvchad.configs.dapview"
    end
  },

{
    "theHamsta/nvim-dap-virtual-text",
    event = "VeryLazy",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        commented = false,
        all_frames = false,
        highlight_changed_variables = true,
      })
    end,
  },

  --A library for asynchronous IO in Neovim
  {
    "nvim-neotest/nvim-nio",
    requires = { "mfussenegger/nvim-dap" },
  },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter"
    }
  },

  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup {
        stages = "fade",
        timeout = 3000,
        max_height = 5,
        top_down = false, -- false = grows upward, placing it above the statusline
        background_colour = "#000000", -- optional: make it opaque
      }

      vim.notify = require("notify") -- override default `vim.notify`
    end,
  },

  --A pretty list for showing diagnostics, references, telescope results, quickfix and location lists
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
  },

  {
    "ThePrimeagen/refactoring.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {},
  },

  --A hackable Markdown, HTML, LaTeX, Typst & YAML previewer for Neovim
  {
      "OXY2DEV/markview.nvim",
      ft = { "markdown", "rmd", "quarto", "mdx", "html", "latex" },
      lazy = false,
      priority = 49,
  },

  --A sidebar with a tree-like outline of symbols from your code, powered by LSP.
  {
    "hedyhli/outline.nvim",
    -- lazy = false;
    cmd = {"Outline", "OutlineOpen", "OutlineStatus"},
    opts = function()
      return require("nvchad.configs.outline")
    end,
  },

  --precognition.nvim assists with discovering motions (Both vertical and horizontal) to navigate your current buffer
  {
    "tris203/precognition.nvim",
    cmd = {"Precognition"},
    opts = {},
  },

  --Dotnet
  {
    "GustavEikaas/easy-dotnet.nvim",
    ft = { "cs", "csproj", "sln", "slnx", "props", "csx", "targets" },
    dependencies = { "nvim-lua/plenary.nvim", 'nvim-telescope/telescope.nvim', },
    config = function()
      require("easy-dotnet").setup({
        lsp = {
          enabled = true, -- Enable builtin roslyn lsp
          preload_roslyn = false, -- Roslyn starts when a cs file is opened (matches ft lazy-loading)
          roslynator_enabled = true, -- Automatically enable roslynator analyzer
          easy_dotnet_analyzer_enabled = true, -- Enable roslyn analyzer from easy-dotnet-server
          auto_refresh_codelens = true,
          analyzer_assemblies = {}, -- Any additional roslyn analyzers you might use like SonarAnalyzer.CSharp
          config = {},
        },
      })
    end
  },

  --Flutter
  {
      'nvim-flutter/flutter-tools.nvim',
      -- lazy = false,
      ft = {"dart", "pubspec.yaml"},
      dependencies = {
          'nvim-lua/plenary.nvim',
          'stevearc/dressing.nvim', -- optional for vim.ui.select
      },
      config = true,
  },

  {
      'akinsho/pubspec-assist.nvim',
      -- lazy = false,
      ft = {"dart", "pubspec.yaml"},
      dependencies = {
          'nvim-lua/plenary.nvim'
      },
      config = true,
  },

  {
    "nickjvandyke/opencode.nvim",
    lazy = false,
    version = "*",
    config = function()
      require "nvchad.configs.opencode"
    end,
  },
}
