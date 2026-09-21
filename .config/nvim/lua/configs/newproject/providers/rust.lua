---@type NewProject.Provider
local M = {
  name = "Rust",
  icon = "\u{e68b} ", -- nf-seti-rust, the file tree's glyph for .rs
  bin = "cargo",
  order = 20,

  normalize = function(name)
    return (name:lower():gsub("[^%w_%-]", "-"))
  end,

  steps = {
    {
      key = "kind",
      prompt = "Crate type",
      choices = {
        { label = "Binary (application)", value = "--bin" },
        { label = "Library", value = "--lib" },
      },
    },
  },

  -- `cargo init` rather than `cargo new`, because the directory already exists. It skips
  -- its own `git init` when the parent is already a repository, which is right.
  command = function(ctx)
    return { "cargo", "init", ctx.kind, "--name", ctx.name }
  end,
}

return M
