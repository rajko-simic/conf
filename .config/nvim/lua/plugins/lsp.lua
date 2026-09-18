-- Language server tooling: lspconfig, mason, completion, diagnostics UI.

return {
  -- LSP package manager
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function()
      return require("configs.mason").opts
    end,
    config = function(_, opts)
      require("configs.mason").config(_, opts)
    end,
  },

  -- LSP config: configs.lspconfig applies configs.lsp.defaults() then enables servers
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      require "configs.lspconfig"
    end,
  },

  { "b0o/schemastore.nvim" },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    build = "cargo build --release",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = require "configs.blink",
  },

  -- LSP UI (peek definition, line diagnostics, code action picker)
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = function()
      return require "configs.lspsaga"
    end,
    config = function(_, opts)
      require("lspsaga").setup(opts)
    end,
  },

  -- References, definitions and implementations above symbols
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    config = function()
      require "configs.symbolusage"
    end,
  },

  -- Diagnostics list
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    config = function()
      require "configs.trouble"
    end,
  },
}
