---@module 'blink.cmp'
---@type blink.cmp.Config
return {
  keymap = {
    preset = 'super-tab',
    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  },

  signature = {
    enabled = true,
    window = {
      max_height = 30,
      max_width = 120,
      border = 'rounded',
      show_documentation = true,
      direction_priority = { 's', 'n' },
    },
  },

  appearance = {
    nerd_font_variant = 'mono',
  },

  completion = {
    accept = { auto_brackets = { enabled = true } },

    menu = {
      max_height = 20,
      border = 'rounded'
    },

    documentation = {
      auto_show = true,
      window = {
        max_height = 30,
        border = 'rounded',
      },
    },
  },

  snippets = {
    preset = 'default',
  },

  -- NOTE: no "easy-dotnet" provider here on purpose — easy-dotnet's own healthcheck
  -- flags it and wants completions served through its ProjX LSP (enabled in
  -- configs/easydotnet.lua), which arrives via the regular 'lsp' source.
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  fuzzy = { implementation = "prefer_rust" },
}
