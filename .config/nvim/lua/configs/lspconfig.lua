require("configs.lsp").defaults()

-- Server definitions come from nvim-lspconfig; it is the only source for 19 of the
-- names below. Customizations live in `after/lsp/<name>.lua` and contain *only* what
-- differs -- `after/` is last on the runtimepath, so those files win, whereas a file in
-- a plain `lsp/` directory would be overwritten by lspconfig's own.
-- `:checkhealth lsp_overrides` flags any override that has drifted into a no-op.
local servers = {
  -- DevOps / infrastructure
  "ansiblels", -- after/lsp: resolved ansible / ansible-lint paths
  "bashls", -- runs shellcheck itself when it is on PATH
  "docker_language_server", -- dockerfile + compose + bake, one process
  "gh_actions_ls",
  "helm_ls", -- after/lsp: internal yaml server disabled
  "jinja_lsp",
  "nginx_language_server",
  "rpmspec",
  "systemd_lsp",
  "terraformls",
  "tflint",
  "yamlls", -- after/lsp: schemastore + kubernetes schemas

  -- Web
  "cssls",
  "emmet_ls", -- after/lsp: narrowed filetypes
  "eslint",
  "graphql",
  "html",
  "ts_ls", -- after/lsp: root markers

  -- Azure / .NET / JVM
  "bicep", -- after/lsp: cmd -- lspconfig ships none, so this is load-bearing
  "kotlin_language_server",
  "powershell_es", -- after/lsp: mason bundle path (upstream needs pwsh)

  -- General-purpose languages
  "cmake",
  "gopls",
  "lua_ls", -- after/lsp: nvim runtime + plugin type libraries
  "nil_ls",
  "pyright",
  "rust_analyzer",
  "sqlls",
  "vimls",

  -- Data & markup
  "jsonls", -- after/lsp: schemastore
  "lemminx", -- MSBuild fragments reach it via lua/filetypes.lua, not a filetypes override
  "marksman",
  "taplo",

  -- Prose
  "harper_ls",
  "typos_lsp", -- after/lsp: restricted filetypes (upstream sets none => every buffer)
}

vim.lsp.enable(servers)
-- read :h vim.lsp.config for changing options of lsp servers
