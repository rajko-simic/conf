require("configs.lsp").defaults()

local servers = {
  "bashls",
  "bicep",
  "cmake",
  "cssls",
  "dockerls",
  "emmet_ls",
  "eslint",
  "gh_actions_ls",
  "gopls",
  "graphql",
  "harper_ls",
  "html",
  "jsonls",
  "kotlin_language_server",
  "lemminx",
  "lua_ls",
  "marksman",
  "nginx_language_server",
  "nil_ls",
  "powershell_es",
  "pyright",
  "rust_analyzer",
  "sqlls",
  "terraformls",
  "toplo",
  "ts_ls",
  "typos_lsp",
  "vimls",
  "yamlls",
}

vim.lsp.enable(servers)
-- read :h vim.lsp.config for changing options of lsp servers 
