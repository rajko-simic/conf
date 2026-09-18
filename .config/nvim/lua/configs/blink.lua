---@module 'blink.cmp'
---@type blink.cmp.Config
return {
  keymap = {
    preset = "super-tab",
    ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
  },

  signature = {
    enabled = true,
    window = {
      max_height = 30,
      max_width = 120,
      border = "rounded",
      show_documentation = true,
      direction_priority = { "s", "n" },
    },
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    accept = { auto_brackets = { enabled = true } },

    menu = {
      max_height = 20,
      border = "rounded",
    },

    documentation = {
      auto_show = true,
      window = {
        max_height = 30,
        border = "rounded",
      },
    },
  },

  snippets = {
    preset = "default",
  },

  -- NOTE: no "easy-dotnet" provider here on purpose — easy-dotnet's own healthcheck
  -- flags it and wants completions served through its ProjX LSP (enabled in
  -- configs/easydotnet.lua), which arrives via the regular 'lsp' source.
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },

    providers = {
      -- The snippet source keys on the *exact* filetype, so yaml.ansible, helm and
      -- yaml.helm-values would otherwise see nothing at all -- not even
      -- friendly-snippets' kubernetes/docker-compose sets, which are scoped to "yaml".
      snippets = {
        opts = {
          extended_filetypes = {
            ["yaml.ansible"] = { "yaml", "ansible" },
            ["yaml.helm-values"] = { "yaml" },
            ["yaml.docker-compose"] = { "yaml" },
            ["yaml.gitlab"] = { "yaml" },
            helm = { "yaml" },
          },
        },
      },
    },
  },

  fuzzy = { implementation = "prefer_rust" },
}
