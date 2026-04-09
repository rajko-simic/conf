---@module 'blink.cmp'
---@type blink.cmp.Config
return {
  keymap = { preset = 'super-tab' },

  signature = { enabled = true },

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

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  fuzzy = { implementation = "prefer_rust" },
}
