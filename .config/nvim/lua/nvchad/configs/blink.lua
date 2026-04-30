---@module 'blink.cmp'
---@type blink.cmp.Config
return {
  keymap = {
    preset = 'super-tab',
    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    ['<C-s>'] = { 'scroll_signature_down', 'fallback' },
    ['<C-S-s>'] = { 'scroll_signature_up', 'fallback' },
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

  sources = {
    default = { 'lsp', 'easy-dotnet', 'path', 'snippets', 'buffer' },
    providers = {
      ["easy-dotnet"] = {
        name = "easy-dotnet",
        enabled = true,
        module = "easy-dotnet.completion.blink",
        score_offset = 10000,
        async = true,
      },
    },
  },

  fuzzy = { implementation = "prefer_rust" },
}
