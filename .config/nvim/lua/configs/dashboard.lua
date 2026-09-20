-- snacks.dashboard, replacing NvChad's nvdash (disabled via nvdash.load_on_startup
-- in chadrc.lua; its own config is left untouched).
--
-- Left pane  : the nvdash buttons, re-keyed to single letters.
-- Right pane : the 10 most recent neovim-project projects (keys 1-9 then 0) and the
--              3 most recent files (deliberately keyless -- informational only).
--
-- No `header` section: that is what draws the big NEOVIM banner, and it is omitted on
-- purpose.
--
-- Theming needs no work. snacks links SnacksDashboard{Header,Title,Icon,Key,Desc,File,
-- Dir,Footer} to Special / Title / Number / NonText / Normal with `default = true`, and
-- base46 themes all of those -- so the dashboard picks up the active base46 theme and
-- follows a theme switch with it.

local M = {}

-- neovim-project owns the project list, so go through it rather than snacks' own
-- `projects` section: that one derives directories from oldfiles + git roots and would
-- `chdir` instead of restoring the session.
local function projects()
  local ok, history = pcall(require, "neovim-project.utils.history")
  if not ok then
    return {}
  end

  local dirs = history.get_recent_projects() or {}
  local items = {}

  -- history is oldest-first; show most recent first
  for i = #dirs, 1, -1 do
    if #items >= 10 then
      break
    end
    local dir = dirs[i]
    local n = #items + 1
    items[#items + 1] = {
      file = dir,
      icon = "directory",
      key = n == 10 and "0" or tostring(n),
      action = function()
        require("neovim-project.project").switch_project(dir)
      end,
    }
  end

  return items
end

-- snacks' recent_files items carry `autokey = true`; strip it so these stay keyless and
-- do not eat keys from the autokey pool.
local function recent_files()
  local items = require("snacks.dashboard").sections.recent_files { limit = 3 }()
  for _, item in ipairs(items) do
    item.autokey, item.key = nil, nil
  end
  return items
end

M.opts = {
  preset = {
    keys = {
      { icon = " ", key = "l", desc = "Last Project", action = ":NeovimProjectLoadRecent" },
      { icon = " ", key = "p", desc = "Recent Projects", action = ":NeovimProjectHistory" },
      { icon = " ", key = "a", desc = "Projects (Alphabet)", action = ":NeovimProjectDiscover alphabetical_name" },
      { icon = " ", key = "h", desc = "Projects (History)", action = ":NeovimProjectDiscover history" },
      { icon = " ", key = "d", desc = "Projects (Path)", action = ":NeovimProjectDiscover alphabetical_path" },
      { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
      { icon = " ", key = "o", desc = "Recent Files", action = ":Telescope oldfiles" },
      { icon = "󰈭 ", key = "w", desc = "Find Word", action = ":Telescope live_grep" },
      { icon = " ", key = "c", desc = "Mappings", action = ":NvCheatsheet" },
    },
  },

  sections = {
    { pane = 1, section = "keys", gap = 1, padding = 1 },
    { pane = 2, icon = " ", title = "Projects", indent = 2, padding = 1, projects },
    { pane = 2, icon = " ", title = "Recent Files", indent = 2, padding = 1, recent_files },
    { pane = 1, section = "startup" },
  },
}

return M
