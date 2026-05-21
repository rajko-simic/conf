require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

--Saga
map("n", "<leader>la", "<cmd>Lspsaga code_action<cr>", { desc = "LSP saga code action" })
map("n", "<leader>lp", "<cmd>Lspsaga peek_definition<cr>", { desc = "LSP saga peek definition" })
map("n", "<leader>le", "<cmd>Lspsaga show_line_diagnostics<cr>", { desc = "LSP saga line diagnostics" })
map("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<cr>", { desc = "LSP saga next diagnostic" })
map("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<cr>", { desc = "LSP saga prev diagnostic" })

local function write_unnamed(buf)
  vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(input)
    if not input or input == "" then
      return
    end
    local path = vim.fn.fnamemodify(input, ":p")
    local dir = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    vim.api.nvim_buf_set_name(buf, path)
    vim.bo[buf].buflisted = true
    vim.api.nvim_buf_call(buf, function()
      vim.cmd "noautocmd write"
      vim.cmd "filetype detect"
    end)
  end)
end

local function smart_save()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    pcall(vim.cmd, "write")
    return
  end
  if vim.api.nvim_buf_get_name(buf) == "" then
    write_unnamed(buf)
  else
    vim.cmd "write"
  end
end

map({ "n", "v" }, "<C-s>", function()
  smart_save()
end, { desc = "Save (prompt if unnamed)" })

map("i", "<C-s>", function()
  vim.cmd "stopinsert"
  smart_save()
end, { desc = "Save (prompt if unnamed)" })

local group = vim.api.nvim_create_augroup("user_smart_save", { clear = true })
vim.api.nvim_create_autocmd({ "BufNew", "VimEnter" }, {
  group = group,
  callback = function(args)
    local buf = args.buf
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if vim.bo[buf].buftype ~= "" then
      return
    end
    if vim.api.nvim_buf_get_name(buf) ~= "" then
      return
    end
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      group = group,
      buffer = buf,
      callback = function()
        if vim.api.nvim_buf_get_name(buf) == "" then
          write_unnamed(buf)
        else
          vim.api.nvim_buf_call(buf, function()
            vim.cmd "noautocmd write"
          end)
        end
      end,
    })
  end,
})
