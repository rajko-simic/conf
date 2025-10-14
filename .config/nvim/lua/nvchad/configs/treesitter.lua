pcall(function()
  dofile(vim.g.base46_cache .. "syntax")
  dofile(vim.g.base46_cache .. "treesitter")
end)

return {
  ensure_installed = {
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
    "yaml" },

  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true },
}


