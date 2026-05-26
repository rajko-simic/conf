dofile(vim.g.base46_cache .. "mason")

local M = {}

M.opts = {
  PATH = "skip",
  ui = {
    icons = {
      package_pending = " ",
      package_installed = " ",
      package_uninstalled = " ",
    },
  },
  registries = {
    "github:mason-org/mason-registry",
  },
  max_concurrent_installers = 10,
  ensure_installed = {
    -- Formatters & Linters
    "buf",
    "ktlint",
    "eslint-lsp",
    "gofumpt",
    "golangci-lint",
    "gdtoolkit",
    "gitleaks",
    "gitlint",
    "markdownlint",
    "markuplint",
    "nginx-config-formatter",
    "sql-formatter",
    "stylua",
    "yamllint",
    "eslint_d",
    "prettier",

    -- Debuggers
    "codelldb",
    "delve",
    "kotlin-debug-adapter",
    "bash-debug-adapter",
    "dart-debug-adapter",
    "js-debug-adapter",
    "go-debug-adapter",
    "local-lua-debugger-vscode",
    "netcoredbg",

    -- Language Servers
    "powershell-editor-services",
    "gradle-language-server",
    "postgres-language-server",
    "golangci-lint-langserver",
    "azure-pipelines-language-server",
    "bash-language-server",
    "bicep-lsp",
    "cmake-language-server",
    "css-lsp",
    "cypher-language-server",
    "docker-compose-language-service",
    "gh-actions-language-server",
    "harper-ls",
    "html-lsp",
    "lemminx",
    "nil",
    "typescript-language-server",
    "emmet-ls",
    "tailwindcss-language-server",
    "taplo",
    "typos-lsp",
  }
}

M.config = function(_, opts)
  require("mason").setup(opts)
  local mr = require("mason-registry")
  mr.refresh(function()
    for _, tool in ipairs(opts.ensure_installed or {}) do
      local p = mr.get_package(tool)
      if not p:is_installed() then
        p:install()
      end
    end
  end)
end

return M
