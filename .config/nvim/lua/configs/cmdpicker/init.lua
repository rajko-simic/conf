local M = {}

local providers = require "configs.cmdpicker.providers"

-- Search upward from the current file, falling back to cwd, so the picker also
-- works from nvim-tree, the dashboard, a terminal or any scratch buffer.
local function search_root()
  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= "" and vim.uv.fs_stat(buf) then
    return vim.fs.dirname(buf)
  end
  return vim.uv.cwd()
end

-- A provider is active when its project marker is somewhere above us, or when
-- its language server is already running anywhere in this session.
local function detect()
  local root, matched = search_root(), {}

  for _, p in ipairs(providers) do
    local marker = vim.fs.find(p.match, { path = root, upward = true, type = "file", limit = 1 })[1]
    if marker or (p.lsp and #vim.lsp.get_clients { name = p.lsp } > 0) then
      table.insert(matched, p)
    end
  end

  return matched
end

-- Providers are lazy-loaded by filetype, so their commands do not exist yet
-- when we are triggered from an unrelated buffer.
local function ensure_loaded(p)
  if p.plugin then
    pcall(function() require("lazy").load { plugins = { p.plugin } } end)
  end
  if p.ensure then
    pcall(p.ensure)
  end
end

local function open_provider(p)
  ensure_loaded(p)

  local ok, err = pcall(p.commands)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

function M.open()
  local matched = detect()

  if #matched == 0 then
    vim.notify("No known project toolchain found here", vim.log.levels.WARN)
  elseif #matched == 1 then
    open_provider(matched[1])
  else
    vim.ui.select(matched, {
      prompt = "Toolchain",
      format_item = function(p) return p.name end,
    }, function(choice)
      if choice then
        open_provider(choice)
      end
    end)
  end
end

return M
