dofile(vim.g.base46_cache .. "mason")

local M = {}

M.opts = {
  PATH = "skip",
  ui = {
    icons = {
      package_pending = " ",
      package_installed = " ",
      package_uninstalled = " ",
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

    -- Formatters & Linters: DevOps
    -- shellcheck is NOT wired into nvim-lint on purpose: bash-language-server runs it
    -- itself from PATH (mason's bin dir is prepended in lua/options.lua). It is installed
    -- here only so bashls can find it.
    "shellcheck",
    "shfmt",
    "hadolint",
    "rpmlint",
    "npm-groovy-lint",
    "actionlint",
    "yamlfmt",
    "ruff",
    "tfsec",
    "terraform",

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
    "debugpy",

    -- Language Servers
    "powershell-editor-services",
    "gradle-language-server",
    "postgres-language-server",
    "golangci-lint-langserver",
    "azure-pipelines-language-server",
    "bash-language-server",
    "bicep-lsp",
    "copilot-language-server",
    -- cmake-language-server: installed outside mason (mason pins python <3.14, system is 3.14):
    --   pipx install cmake-language-server && pipx inject cmake-language-server "pygls<2"
    -- The pygls pin is required — 0.1.11 imports pygls.server.LanguageServer, removed in pygls 2.
    "css-lsp",
    "cypher-language-server",
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

    -- Language Servers: DevOps
    -- ansible-core / ansible-lint deliberately absent: mason has no `ansible`/`ansible-doc`
    -- package and ansible-language-server shells out to them. They come from dnf
    -- (ansible-core, python3-ansible-lint) so they match the CLI and CI.
    "ansible-language-server",
    "helm-ls",
    "jinja-lsp",
    "systemd-lsp",
    "rpm_lsp_server",
    "docker-language-server",
    "terraform-ls",
    "tflint",

    -- Language Servers: previously installed by hand, listed so a fresh machine reproduces
    "gopls",
    "lua-language-server",
    "rust-analyzer",
    "pyright",
    "marksman",
    "json-lsp",
    "sqlls",
    "nginx-language-server",
    "vim-language-server",
    "kotlin-language-server",
  },
}

-- Install anything in ensure_installed that is missing. Each lookup is wrapped: an unknown
-- or renamed package name would otherwise throw and abort every install after it.
M.ensure = function(ensure_installed)
  local mr = require "mason-registry"
  mr.refresh(function()
    for _, tool in ipairs(ensure_installed or M.opts.ensure_installed) do
      local ok, pkg = pcall(mr.get_package, tool)
      if not ok then
        vim.notify("mason: unknown package '" .. tool .. "'", vim.log.levels.WARN)
      elseif not pkg:is_installed() then
        pkg:install()
      end
    end
  end)
end

M.config = function(_, opts)
  require("mason").setup(opts)

  vim.api.nvim_create_user_command("MasonEnsure", function()
    M.ensure(opts.ensure_installed)
  end, { desc = "Install every mason package in ensure_installed" })

  M.ensure(opts.ensure_installed)
end

return M
