-- DevOps tooling. Diagnostics from linters that have no language server behind them;
-- everything else in this domain is wired into the existing lsp/conform/dap/cmdpicker
-- configs rather than adding plugins.

return {
  -- Linters (see configs/lint.lua for what is deliberately *not* wired up)
  {
    "mfussenegger/nvim-lint",
    event = "User FilePost",
    config = function()
      require "configs.lint"
    end,
  },
}
