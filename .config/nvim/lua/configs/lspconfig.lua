require("nvchad.configs.lspconfig").defaults()

local servers = {
  "bashls",
  "dockerls",
  "gopls",
  "graphql",
  "groovyls",
  "jsonls",
  "kotlin_language_server",
  "lua_ls",
  "marksman",
  "nginx_language_server",
  "pyright",
  "rust_analyzer",
  "sqlls",
  "terraformls",
  "toplo",
  "vimls",
  "yamlls",
  "ts_ls",
  "eslint",
  "html",
  "cssls",
  "emmet_ls",
}

vim.lsp.enable(servers)
-- read :h vim.lsp.config for changing options of lsp servers 
