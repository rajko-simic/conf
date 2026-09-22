-- Telescope jumplist restricted to buffers under the current working directory.
-- The builtin (`telescope.builtin.jumplist`) hardcodes its entry_maker, so filtering has to
-- happen while collecting results; everything else is the builtin's own picker layout.

local M = {}

function M.project(opts)
  opts = opts or {}
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require("telescope.config").values

  local cwd = vim.fn.getcwd()
  local jumps = vim.fn.getjumplist()[1]
  local results = {}
  for i = #jumps, 1, -1 do -- newest first, like the builtin
    local jump = jumps[i]
    if vim.api.nvim_buf_is_valid(jump.bufnr) then
      local name = vim.api.nvim_buf_get_name(jump.bufnr)
      if name ~= "" and vim.fs.relpath(cwd, name) then
        jump.text = vim.api.nvim_buf_get_lines(jump.bufnr, jump.lnum - 1, jump.lnum, false)[1] or ""
        table.insert(results, jump)
      end
    end
  end

  pickers
    .new(opts, {
      prompt_title = "Jumplist: " .. vim.fn.fnamemodify(cwd, ":t"),
      finder = finders.new_table {
        results = results,
        entry_maker = make_entry.gen_from_quickfix(opts),
      },
      previewer = conf.qflist_previewer(opts),
      sorter = conf.generic_sorter(opts),
    })
    :find()
end

return M
