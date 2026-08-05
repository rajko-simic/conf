-- Markdown rendering and authoring.

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    -- latex disabled: no latex treesitter parser and neither utftex nor latex2text
    -- is installed, which the plugin's healthcheck warns about.
    opts = { latex = { enabled = false } },
  },

  {
    "yousefhadder/markdown-plus.nvim",
    ft = "markdown",
    opts = {},
  },

  -- Markdown / HTML / LaTeX previewer
  -- {
  --   "OXY2DEV/markview.nvim",
  --   ft = { "markdown", "rmd", "quarto", "mdx", "html", "latex" },
  --   lazy = false,
  --   priority = 49,
  -- },
}
