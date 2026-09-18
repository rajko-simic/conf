-- Teach lua-language-server about the nvim runtime and this config's plugin types.
-- Purely additive: upstream sets settings.Lua.hint and settings.Lua.codeLens, not
-- settings.Lua.workspace, so both survive the merge.
-- Inherited: cmd, filetypes, root_markers (upstream's are priority-grouped:
-- .emmyrc/.luarc first, then .luacheckrc/.stylua.toml/selene.toml, then .git).
---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  },
}
