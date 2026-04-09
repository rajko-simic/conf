pcall(function()
  dofile(vim.g.base46_cache .. "syntax")
  dofile(vim.g.base46_cache .. "treesitter")
end)

local M = {}

M.ensure_installed = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "c_sharp",
  "css",
  "bash",
  "dart",
  "desktop",
  "dockerfile",
  "gitcommit",
  "gitignore",
  "go",
  "godot_resource",
  "graphql",
  "groovy",
  "http",
  "html",
  "javascript",
  "json",
  "json5",
  "kotlin",
  "kusto",
  "make",
  "markdown",
  "markdown_inline",
  "nginx",
  "passwd",
  "proto",
  "properties",
  "python",
  "query",
  "rust",
  "sql",
  "ssh_config",
  "terraform",
  "textproto",
  "typescript",
  "tsx",
  "yaml",
}

M.opts = {
  ensure_installed = M.ensure_installed,
  highlight = {
    enable = true,
    use_languagetree = true,
  },
  indent = { enable = true },
}

-- Runs on :Lazy build nvim-treesitter and first install
M.build = function()
  require("nvim-treesitter.install").install(
    M.ensure_installed,
    { force = false, summary = true }
  )
end

-- Runs on every startup — installs any parsers missing from ensure_installed
M.init = function()
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      local ok, ts_config = pcall(require, "nvim-treesitter.config")
      if not ok then return end
      local installed = ts_config.get_installed()
      local missing = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, M.ensure_installed)
      if #missing > 0 then
        require("nvim-treesitter.install").install(missing, { force = false, summary = true })
      end
    end,
  })
end

M.config = function()
  require("nvim-treesitter").setup(M.opts)
end

return M
