local M = {}
local map = vim.keymap.set

-- Keymaps applied on every LSP attach
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "ga", vim.lsp.buf.code_action, opts "Do action")
  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>ra", require "nvchad.lsp.renamer", opts "NvRenamer")
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

  -- Disable native signature help — blink.cmp handles this
  vim.lsp.handlers["textDocument/signatureHelp"] = function() end

  -- Apply blink.cmp capabilities + on_init to all servers globally
  local capabilities = require("blink.cmp").get_lsp_capabilities()
  vim.lsp.config("*", { capabilities = capabilities, on_init = M.on_init })

  -- Enable inlay hints and keymaps on every LSP attach
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(_, args.buf)
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end,
  })
end

return M
