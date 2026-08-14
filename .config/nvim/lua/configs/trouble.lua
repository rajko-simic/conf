require("trouble").setup({
  formatters = {
    line_only = function(ctx)
      return { text = "[" .. ctx.item.pos[1] .. "] ", hl = "TroubleCode" }
    end,
    name = function(ctx)
      return { text = ctx.item.symbol.name, hl = "TroubleLspName" }
    end,
  },
  modes = {
    lsp_bottom = {
      mode = "lsp",
      focus = false,
      -- title = false,
      win = {
        position = "bottom",
        size = 0.5,
      },
    },
    symbols = {
      desc = "document symbols",
      mode = "lsp_document_symbols",
      focus = false,
      title = false,
      format = "{kind_icon}{line_only}{name}",
      win = {
        position = "left",
        size = 0.3,
      },
      filter = {
        -- remove Package since luals uses it for control flow structures
        ["not"] = { ft = "lua", kind = "Package" },
        any = {
          -- all symbol kinds for help / markdown files
          ft = { "help", "markdown" },
        },
      },
    },
  },
})
