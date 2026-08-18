-- flutter-tools setup + Android flavor auto-discovery.
--
-- Discovered flavors are registered as flutter-tools project configurations,
-- so the "Run" entry in `Telescope flutter commands` (and :FlutterRun /
-- :FlutterDebug) prompts for one. Picking "default (no flavor)" runs plain
-- `flutter run`. `:FlutterFlavors` forces re-discovery after a gradle edit.
--
-- The flutter project is found upward from the current buffer; when nothing is
-- there (repo root opened, project in a subfolder) a bounded downward scan
-- takes over. Every config carries the project's cwd, so runs work no matter
-- where nvim was opened. With several projects in one repo, entries are
-- prefixed with the project path and pure dart packages are left out.

local M = {}

local uv = vim.uv
local discover = require "configs.flutter.discover"
local applied_scope -- newline-joined roots whose configs are currently applied

--- Discover flavors for the flutter project(s) reachable from the current
--- buffer (or cwd) and register them as project configs.
---@param opts? { force?: boolean }
---@return integer flavor_count
function M.refresh(opts)
  local force = opts and opts.force or false
  local source = vim.api.nvim_buf_get_name(0)
  if source == "" or not uv.fs_stat(source) then
    source = assert(uv.cwd())
  end
  local upward = vim.fs.root(source, "pubspec.yaml")
  local roots = upward and { upward } or discover.projects(assert(uv.cwd()))
  if #roots == 0 then
    return 0
  end

  local changed, total, flavors_by_root = false, 0, {}
  for _, root in ipairs(roots) do
    local flavors, stale = discover.flavors(root, force)
    flavors_by_root[root] = flavors
    changed = changed or stale
    total = total + #flavors
  end

  local scope = table.concat(roots, "\n")
  if not force and not changed and scope == applied_scope then
    return total
  end
  applied_scope = scope

  local cwd = assert(uv.cwd())
  local configs = {}
  for _, root in ipairs(roots) do
    local flavors = flavors_by_root[root]
    local label = vim.fs.relpath(cwd, root) or root
    if #roots == 1 then
      if upward and #flavors == 0 then
        -- flavorless project we're inside of: keep stock no-prompt behavior
      elseif #flavors == 0 then
        -- single project below us: one auto-selected config just for its cwd
        configs[1] = { name = label, cwd = root }
      else
        configs[#configs + 1] = { name = "default (no flavor)", cwd = root }
        for _, flavor in ipairs(flavors) do
          configs[#configs + 1] = { name = flavor, flavor = flavor, cwd = root }
        end
      end
    elseif #flavors > 0 then
      configs[#configs + 1] = { name = label .. ": default (no flavor)", cwd = root }
      for _, flavor in ipairs(flavors) do
        configs[#configs + 1] = { name = label .. ": " .. flavor, flavor = flavor, cwd = root }
      end
    elseif discover.is_app(root) then
      -- flavorless app in a multi-project repo: entry is app choice, not flavor
      configs[#configs + 1] = { name = label, cwd = root }
    end
  end
  require("flutter-tools").setup_project(configs)
  return total
end

require("flutter-tools").setup {}
pcall(require("telescope").load_extension, "flutter")

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("FlutterFlavors", { clear = true }),
  pattern = { "*.dart", "pubspec.yaml" },
  callback = function()
    M.refresh()
  end,
})

vim.api.nvim_create_user_command("FlutterFlavors", function()
  local n = M.refresh { force = true }
  vim.notify(("flutter: %d flavor(s) registered"):format(n))
end, { desc = "Re-discover Android flavors for flutter-tools" })

M.refresh()

return M
