local SymbolKind = vim.lsp.protocol.SymbolKind

local function h(name)
  return vim.api.nvim_get_hl(0, { name = name })
end

vim.api.nvim_set_hl(0, "SymbolUsageContent", { fg = h("Comment").fg, italic = true })
vim.api.nvim_set_hl(0, "SymbolUsageRef", { fg = h("Function").fg, italic = true })
vim.api.nvim_set_hl(0, "SymbolUsageDef", { fg = h("Type").fg, italic = true })
vim.api.nvim_set_hl(0, "SymbolUsageImpl", { fg = h("@keyword").fg, italic = true })

---@param symbol Symbol
local function text_format(symbol)
  local res = {}

  local stacked = symbol.stacked_count > 0 and ("+%s"):format(symbol.stacked_count) or ""

  if symbol.references then
    local usage = symbol.references <= 1 and "usage" or "usages"
    local num = symbol.references == 0 and "no" or symbol.references
    table.insert(res, { "󰌹 ", "SymbolUsageRef" })
    table.insert(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
  end

  if symbol.definition then
    if #res > 0 then
      table.insert(res, { " ", "NonText" })
    end
    table.insert(res, { "󰳽 ", "SymbolUsageDef" })
    table.insert(res, { symbol.definition .. " defs", "SymbolUsageContent" })
  end

  if symbol.implementation then
    if #res > 0 then
      table.insert(res, { " ", "NonText" })
    end
    table.insert(res, { "󰡱 ", "SymbolUsageImpl" })
    table.insert(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
  end

  if stacked ~= "" then
    if #res > 0 then
      table.insert(res, { " ", "NonText" })
    end
    table.insert(res, { " ", "SymbolUsageImpl" })
    table.insert(res, { stacked, "SymbolUsageContent" })
  end

  return res
end

require("symbol-usage").setup {
  ---@type table<string, any> `nvim_set_hl`-like options for highlight virtual text
  hl = { link = "Comment" },

  ---@type lsp.SymbolKind[] Symbol kinds to count
  kinds = {
    SymbolKind.Function,
    SymbolKind.Method,
    SymbolKind.Constructor,
    SymbolKind.Interface,
    SymbolKind.Class,
    SymbolKind.Struct,
    SymbolKind.Enum,
  },

  ---Additional filter for kinds (see README #filter-kinds)
  ---@type table<lsp.SymbolKind, filterKind[]>
  kinds_filter = {},

  ---@type 'above'|'end_of_line'|'textwidth'|'signcolumn'
  vt_position = "above",

  ---@type integer|nil Virtual text priority
  vt_priority = nil,

  ---Text to display while the LSP request is pending.
  ---Use false to show nothing until the request finishes (avoids line jumping).
  ---@type string|table|false
  request_pending_text = "loading...",

  ---Custom format function (bubble style — edit to taste)
  text_format = text_format,

  references = { enabled = true, include_declaration = false },
  definition = { enabled = true },
  implementation = { enabled = true },

  ---Disable for specific LSPs, filetypes, or custom conditions
  ---@type { lsp?: string[], filetypes?: string[], cond?: function[] }
  disable = { lsp = {}, filetypes = {}, cond = {} },

  ---Per-filetype overrides (see lua/symbol-usage/langs.lua for examples)
  -- filetypes = {},

  ---@type 'start'|'end' Where on selectionRange to send the LSP request from
  symbol_request_pos = "end",

  ---Optional filter for references/definitions/implementations
  ---@type (fun(ctx: lsp.HandlerContext):fun(symbol: lsp.Location): boolean)?
  symbol_filter = nil,

  ---@type { enabled: boolean }
  log = { enabled = false },
}
