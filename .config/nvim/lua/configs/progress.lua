-- Sources for the `progress` statusline slot (see lua/chadrc.lua).
--
-- Language servers are NOT listed here: they report through `lsp_msg`, which NvChad
-- drives off the LspProgress autocmd and which is already in the statusline order. This
-- list is for tools that bypass vim.lsp and report progress their own way.
--
-- Each entry returns a display string, or "" / nil when idle. The first non-empty one
-- wins. Adding a new producer is one entry -- nothing here is language-specific.
--
-- vim.lsp.status() is deliberately absent: it *consumes* progress messages and returns
-- empty when there are none new, so calling it once per statusline redraw flickers.

return {
  -- easy-dotnet speaks StreamJsonRpc over its own libuv pipe rather than vim.lsp, so its
  -- $/progress never reaches the LspProgress autocmd.
  --
  -- NOTE: read package.loaded, never `require`. lazy.nvim force-loads a plugin the
  -- moment one of its modules is required, and the statusline renders constantly -- a
  -- `require` here defeated easy-dotnet's `ft = { cs, csproj, sln, ... }` trigger and
  -- started Roslyn at init in every project. The same rule applies to any source added
  -- to this list.
  function()
    local easy_dotnet = package.loaded["easy-dotnet"]
    return easy_dotnet and easy_dotnet.lualine.jobs() or ""
  end,
}
