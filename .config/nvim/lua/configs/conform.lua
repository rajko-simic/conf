local options = {
  formatters_by_ft = {
    lua = { "stylua" },

    sh = { "shfmt" },
    bash = { "shfmt" },
    python = { "ruff_format" },
    json = { "jq" },
    groovy = { "npm-groovy-lint" },
    -- terraform fmt handles HCL2, so it covers plain .hcl too and saves installing hclfmt
    terraform = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    hcl = { "terraform_fmt" },

    -- conform resolves yaml.ansible -> ansible -> yaml and *skips empty tables*, so
    -- ["yaml.ansible"] = {} would not stop yamlfmt from reflowing a playbook. The
    -- function form is the only thing that actually suppresses it.
    yaml = function(bufnr)
      return vim.bo[bufnr].filetype == "yaml.ansible" and {} or { "yamlfmt" }
    end,
  },

  -- format_on_save stays off on purpose: yamlfmt reflows YAML in ways that churn diffs
  -- and shfmt fights team styles. <leader>fm formats on demand.
  -- format_on_save = {
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
