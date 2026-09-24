require("configs.lsp").defaults()

local servers = {
  -- DevOps / infrastructure
  "ansiblels",
  "bashls",
  "docker_language_server",
  "gh_actions_ls",
  "helm_ls",
  "jinja_lsp",
  "nginx_language_server",
  "rpmspec",
  "systemd_lsp",
  "terraformls",
  "tflint",
  "yamlls",

  -- Web
  "cssls",
  "emmet_ls",
  "eslint",
  "graphql",
  "html",
  "ts_ls",

  -- Azure / .NET / JVM
  "bicep",
  "kotlin_language_server",
  "powershell_es",

  -- General-purpose languages
  "cmake",
  "gopls",
  "lua_ls",
  "nil_ls",
  "pyright",
  "rust_analyzer",
  "sqlls",
  "vimls",

  -- Data & markup
  "jsonls",
  "lemminx",
  "marksman",
  "taplo",

  -- AI (inline completion; keymaps in configs/lsp.lua)
  "copilot",

  -- Prose
  "harper_ls",
  "typos_lsp",
}

vim.lsp.enable(servers)
