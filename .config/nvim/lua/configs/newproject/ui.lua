-- Prompts and notifications shared by the wizard runner and the toolchain providers.
-- Kept in their own file so providers.lua never has to require init.lua back.
--
-- vim.ui.select is snacks.picker (`picker = { ui_select = true }` in plugins/ui.lua) and
-- vim.ui.input is snacks input, so every prompt here is a floating window already themed
-- with the rest of the editor. snacks calls back inside vim.schedule *after* closing its
-- window, which is what makes it safe to open the next prompt straight from a callback.

local M = {}

-- One id for the whole wizard: the notifier replaces a line with the same id rather than
-- stacking, so the spinner and its outcome are a single row.
local NOTIFY_ID = "newproject"

---@param msg string
---@param level? integer
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { id = NOTIFY_ID, title = "New Project" })
end

-- Items carry their own `label`; every other field on them is the caller's business.
---@param prompt string
---@param items table[]
---@param cb fun(choice?: table)
function M.select(prompt, items, cb)
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return item.label
    end,
  }, cb)
end

-- vim.ui.input answers nil when the prompt is cancelled but "" when an empty box is
-- confirmed. An empty project name would resolve to the current directory and scaffold
-- in place, so both are folded into a cancel here.
---@param prompt string
---@param default? string
---@param cb fun(value?: string)
function M.input(prompt, default, cb)
  vim.ui.input({ prompt = prompt, default = default }, function(value)
    value = value and vim.trim(value) or ""
    cb(value ~= "" and value or nil)
  end)
end

-- Both streams, trimmed: `dotnet new` writes most of its diagnostics to stdout, so
-- reporting stderr alone loses the actual reason a scaffold failed.
---@param res vim.SystemCompleted
---@return string
function M.output(res)
  local text = vim.trim((res.stderr or "") .. "\n" .. (res.stdout or ""))
  local lines = vim.split(text, "\n", { trimempty = true })
  if #lines > 20 then
    lines = vim.list_slice(lines, 1, 20)
    lines[#lines + 1] = "…"
  end
  return table.concat(lines, "\n")
end

return M
