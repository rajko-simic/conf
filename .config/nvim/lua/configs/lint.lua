local lint = require "lint"

lint.linters_by_ft = {
  dockerfile = { "hadolint" },
  yaml = { "yamllint" },
  -- ansible-language-server already runs ansible-lint, and ansible-lint runs yamllint
  -- itself. nvim-lint looks the *full* filetype up first and an empty table is truthy
  -- in Lua, so this genuinely suppresses the `yaml` entry above. (conform resolves
  -- filetypes the other way round and needs a different trick -- see configs/conform.lua.)
  ["yaml.ansible"] = {},
  spec = { "rpmlint" },
  systemd = { "systemd-analyze" },
  groovy = { "npm-groovy-lint" },
  terraform = { "tfsec" },
  markdown = { "markdownlint" },
}

-- Deliberately absent:
--   shellcheck -- bash-language-server runs it itself from PATH (mason's bin dir is
--                 prepended in lua/options.lua), so wiring it here double-reports.
--   ansible_lint -- ansible-language-server owns it, see above.
--   tflint -- enabled as a language server instead (configs/lspconfig.lua).

local function lint_buf()
  -- never shell a decrypted vault file out to a linter
  if vim.b.ansible_vault then
    return
  end
  lint.try_lint()
end

-- BufWritePost only: npm-groovy-lint spawns a JVM and rpmlint/tfsec are slow enough that
-- linting on InsertLeave would stutter. <leader>tl lints on demand.
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true }),
  callback = lint_buf,
})

return { lint_buf = lint_buf }
