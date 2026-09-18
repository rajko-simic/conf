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
  "regex",
  "rust",
  "sql",
  "ssh_config",
  "terraform",
  "textproto",
  "typescript",
  "tsx",
  "yaml",
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

-- nvim-treesitter `main` only manages parser installs; highlighting and
-- indentation are started per buffer here (nvim itself only auto-starts
-- treesitter for a handful of built-in ftplugins).
M.config = function()
  require("nvim-treesitter").setup()

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true }),
    callback = function(args)
      local lang = vim.treesitter.language.get_lang(args.match)
      if not lang or not vim.treesitter.language.add(lang) then
        return
      end
      pcall(vim.treesitter.start, args.buf, lang)
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return M
