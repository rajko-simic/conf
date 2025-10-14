require("nvchad.configs.lspconfig").defaults()

local servers = {
  "bashls",
  "bufls",
  "dartls",
  "dockerls",
  "gopls",
  "graphql",
  "groovyls",
  "jsonls",
  "kotlin_language_server",
  "lua_ls",
  "marksman",
  "nginx_language_server",
  "omnisharp",
  "pyright",
  "rust_analyzer",
  "sqlls",
  "terraformls",
  "vimls",
  "yamlls",
  "ts_ls",
  "eslint",
}

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
