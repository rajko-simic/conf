local lint = require "lint"

lint.linters_by_ft = {
  dockerfile = { "hadolint" },
  yaml = { "yamllint" },
  ["yaml.ansible"] = {},
  spec = { "rpmlint" },
  systemd = { "systemd-analyze" },
  groovy = { "npm-groovy-lint" },
  terraform = { "tfsec" },
  markdown = { "markdownlint" },
}

local function lint_buf()
  -- never shell a decrypted vault file out to a linter
  if vim.b.ansible_vault then
    return
  end
  lint.try_lint()
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true }),
  callback = lint_buf,
})

return { lint_buf = lint_buf }
