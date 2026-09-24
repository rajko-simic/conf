local M = {}
local map = vim.keymap.set

-- Keymaps applied on every LSP attach
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  -- Navigation (lspsaga; saga has no declaration/implementation command, so those stay native)
  map("n", "gd", "<cmd>Lspsaga goto_definition<CR>", opts "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gi", vim.lsp.buf.implementation, opts "Go to implementation")
  map("n", "gy", "<cmd>Lspsaga goto_type_definition<CR>", opts "Go to type definition")
  map("n", "gh", "<cmd>Lspsaga finder<CR>", opts "Finder (definition / references / implementation)")
  map("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts "Hover")

  -- Actions
  map({ "n", "v" }, "<leader>la", "<cmd>Lspsaga code_action<CR>", opts "Code action")
  map("n", "<leader>lp", "<cmd>Lspsaga peek_definition<CR>", opts "Peek definition")
  map("n", "<leader>lr", "<cmd>Lspsaga rename<CR>", opts "Rename")
  map("n", "<leader>lR", "<cmd>Lspsaga rename ++project<CR>", opts "Rename (project)")
  map("n", "<leader>li", "<cmd>Lspsaga incoming_calls<CR>", opts "Incoming calls")
  map("n", "<leader>lo", "<cmd>Lspsaga outgoing_calls<CR>", opts "Outgoing calls")

  -- Diagnostics
  map("n", "<leader>le", "<cmd>Lspsaga show_line_diagnostics<CR>", opts "Line diagnostics")
  map("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts "Next diagnostic")
  map("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts "Prev diagnostic")
end

-- Disable semanticTokens (noisy with NvChad themes)
M.on_init = function(client, _)
  if client:supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

M.defaults = function()
  dofile(vim.g.base46_cache .. "lsp")
  require("nvchad.lsp").diagnostic_config()

  vim.diagnostic.config {
    virtual_text = { current_line = true },
  }

  -- Apply blink.cmp capabilities + on_init to all servers globally
  local capabilities = require("blink.cmp").get_lsp_capabilities()
  vim.lsp.config("*", { capabilities = capabilities, on_init = M.on_init })

  -- Keymaps on every LSP attach (inlay hints are enabled globally in init.lua)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(_, args.buf)

      -- Ghost-text inline completion (copilot). Tab stays blink's; <leader>sa toggles.
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method("textDocument/inlineCompletion", args.buf) then
        local ic = vim.lsp.inline_completion
        ic.enable(true, { bufnr = args.buf })
        map("i", "<M-l>", ic.get, { buffer = args.buf, desc = "LSP accept inline completion" })
        map("i", "<M-]>", function()
          ic.select { count = 1 }
        end, { buffer = args.buf, desc = "LSP next inline completion" })
        map("i", "<M-[>", function()
          ic.select { count = -1 }
        end, { buffer = args.buf, desc = "LSP prev inline completion" })
      end
    end,
  })
end

return M
