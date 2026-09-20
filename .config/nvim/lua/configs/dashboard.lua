-- snacks.dashboard, replacing NvChad's nvdash (disabled via nvdash.load_on_startup
-- in chadrc.lua; its own config is left untouched).
--
-- Left pane  : the cwd as a header, the nvdash buttons re-keyed to single letters,
--              Quit, and a git block at the bottom.
-- Right pane : 10 most recent neovim-project projects (keys 1-9 then 0, zebra striped),
--              the 5 most recent files (Shift+1..5, shown as ^1..^5), each list followed
--              by the telescope button that opens the full picker.
--
-- No `header` *section*: that is what draws the big NEOVIM banner. The cwd header below
-- is a plain item instead.
--
-- Theming needs no work. snacks links SnacksDashboard{Header,Title,Icon,Key,Desc,File,
-- Dir,Footer} to Special / Title / Number / NonText / Normal with `default = true`, and
-- base46 themes all of those -- so the dashboard follows the active base46 theme.

local M = {}

-- Alternating row backgrounds for the project list, so it is obvious which path belongs
-- to which number key.
--
-- This cannot be done by highlighting the item's own text: snacks pads every row out to
-- `opts.width` and that padding carries no highlight, which would leave the band full of
-- holes. So paint the item's whole slice of the line instead -- from where the item
-- starts to end of line, which is safe because an item's pane is always the last thing
-- on its row, in either the one- or two-pane layout.
--
-- Priority 1 keeps this under the foreground groups; as it only sets `bg`, the two merge
-- rather than one replacing the other. `render` fires before D:render_buf writes the
-- lines, hence the schedule.
local ZEBRA_NS = vim.api.nvim_create_namespace "dashboard_zebra"
local ZEBRA_HL = "SnacksDashboardZebra"

-- CursorLine is base46-themed and is already the "one notch off the background" shade
-- wanted here, so derive from it rather than hardcoding. Re-read on every render so a
-- theme switch is picked up without a restart.
local function zebra_sync()
  local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
  vim.api.nvim_set_hl(0, ZEBRA_HL, { bg = cursorline.bg })
end

---@param index integer 1-based position in the list
local function stripe(index)
  return function(dashboard, pos)
    local row, col = pos[1], pos[2] + 1
    vim.schedule(function()
      if not (dashboard.buf and vim.api.nvim_buf_is_valid(dashboard.buf)) then
        return
      end
      -- the first item owns the reset, and runs first: vim.schedule is FIFO
      if index == 1 then
        vim.api.nvim_buf_clear_namespace(dashboard.buf, ZEBRA_NS, 0, -1)
      end
      local line = vim.api.nvim_buf_get_lines(dashboard.buf, row - 1, row, false)[1]
      if index % 2 == 1 or not line or col > #line then
        return
      end
      vim.api.nvim_buf_set_extmark(dashboard.buf, ZEBRA_NS, row - 1, col, {
        end_col = #line,
        hl_group = ZEBRA_HL,
        priority = 1,
      })
    end)
  end
end

-- neovim-project owns the project list, so go through it rather than snacks' own
-- `projects` section: that one derives directories from oldfiles + git roots and would
-- `chdir` instead of restoring the session.
local function projects()
  local ok, history = pcall(require, "neovim-project.utils.history")
  if not ok then
    return {}
  end

  zebra_sync()

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
      render = stripe(n),
      action = function()
        require("neovim-project.project").switch_project(dir)
      end,
    }
  end

  return items
end

-- Shift+<n>. The keys really are the shifted characters -- there is no way to bind
-- <S-1> as such -- but `label` is checked before `key` when the right-hand column is
-- built, so the row can advertise the sane spelling instead of "!".
local SHIFT_NUM = { "!", "@", "#", "$", "%" }

-- snacks' recent_files items carry `autokey = true`; strip it so they take the keys set
-- here instead of being handed whatever is left in the autokey pool.
local function recent_files()
  local items = require("snacks.dashboard").sections.recent_files { limit = #SHIFT_NUM }()
  for i, item in ipairs(items) do
    item.autokey = nil
    item.key = SHIFT_NUM[i]
    item.label = { "^" .. i, hl = "key" }
  end
  return items
end

--------------------------------------------------------------------------------- git

-- Icons are lifted verbatim from NvChad's statusline (nvchad/stl/utils.lua M.git) so the
-- two agree: branch U+EA68, added U+F055, changed U+F459, removed U+F146. The statusline
-- has no ahead/behind, so the arrow-circle pair is a choice, picked to sit with the
-- plus-circle it does use.
local ICON = {
  branch = "\u{ea68}",
  incoming = "\u{f0ab}",
  outgoing = "\u{f0aa}",
  added = "\u{f055}",
  changed = "\u{f459}",
  removed = "\u{f146}",
}

-- The statusline paints every git icon with St_gitIcons. The working-tree counts here use
-- base46's semantic Added/Changed/Removed instead, which reads better on a dashboard; set
-- them all to St_gitIcons to match the statusline exactly.
local HL = { head = "St_gitIcons", added = "Added", changed = "Changed", removed = "Removed" }

local SPINNER = { "/", "-", "\\", "|" }
local FETCH_EVERY = 5 * 60 -- seconds; throttled off .git/FETCH_HEAD mtime
local PANE_WIDTH = 60 -- snacks dashboard defaults, mirrored so the header can centre itself
local PANE_GAP = 4

local git_state = { root = nil, data = nil, fetching = false, frame = 1, timer = nil }

local function sh(root, args)
  local res = vim.system(args, { cwd = root, text = true }):wait(5000)
  if res.code ~= 0 or not res.stdout then
    return {}
  end
  return vim.split(res.stdout, "\n", { trimempty = true })
end

-- All local plumbing: no network, measured at ~15 ms for all three commands together,
-- which is why this stays synchronous. Only the `git fetch` below is async.
local function read_local(root)
  local d = { branch = "?", ahead = 0, behind = 0, added = 0, changed = 0, removed = 0, commits = {}, branches = {} }

  -- "## b...origin/b [ahead 1, behind 2]" | "## b...origin/b" | "## b" | "## No commits yet on b"
  local status = sh(root, { "git", "status", "--porcelain=v1", "--branch" })
  local head = status[1] or ""
  d.branch = head:match "^## No commits yet on (%S+)" or head:match "^## ([^%.%s]+)" or "?"
  d.behind = tonumber(head:match "behind (%d+)") or 0
  d.ahead = tonumber(head:match "ahead (%d+)") or 0
  for i = 2, #status do
    local xy = status[i]:sub(1, 2)
    if xy == "??" or xy:find "A" then -- untracked counts as added
      d.added = d.added + 1
    elseif xy:find "D" then
      d.removed = d.removed + 1
    else
      d.changed = d.changed + 1
    end
  end

  for _, line in ipairs(sh(root, { "git", "log", "--max-count=3", "--format=%h\t%s" })) do
    local hash, subject = line:match "^(%S+)\t(.*)$"
    if hash then
      d.commits[#d.commits + 1] = { hash = hash, subject = subject }
    end
  end

  -- %(upstream:track,nobracket) is local knowledge, i.e. as of the last fetch
  local fmt = "%(refname:short)\t%(upstream:short)\t%(upstream:track,nobracket)"
  for _, line in
    ipairs(sh(root, { "git", "for-each-ref", "--sort=-committerdate", "--count=3", "--format=" .. fmt, "refs/heads/" }))
  do
    local name, upstream, track = line:match "^([^\t]*)\t([^\t]*)\t(.*)$"
    if name and name ~= "" then
      d.branches[#d.branches + 1] = {
        name = name,
        tracked = upstream ~= "",
        ahead = tonumber((track or ""):match "ahead (%d+)") or 0,
        behind = tonumber((track or ""):match "behind (%d+)") or 0,
      }
    end
  end

  return d
end

local function stop_spinner()
  if git_state.timer then
    git_state.timer:stop()
    git_state.timer:close()
    git_state.timer = nil
  end
  git_state.fetching = false
end

local function redraw()
  pcall(function()
    require("snacks.dashboard").update()
  end)
end

-- A real `git fetch` costs ~1.1 s here, so it never blocks: the dashboard renders from
-- local data first and this refreshes the ahead/behind numbers when it lands.
-- Throttled off FETCH_HEAD so opening nvim repeatedly does not hammer the remote, and
-- run with prompts disabled so a credential request can never hang the editor.
local function maybe_fetch(root)
  if git_state.fetching then
    return
  end
  local head = vim.uv.fs_stat(root .. "/.git/FETCH_HEAD")
  if head and os.time() - head.mtime.sec < FETCH_EVERY then
    return
  end

  git_state.fetching = true
  git_state.frame = 1
  git_state.timer = vim.uv.new_timer()
  git_state.timer:start(
    150,
    150,
    vim.schedule_wrap(function()
      git_state.frame = git_state.frame % #SPINNER + 1
      redraw()
    end)
  )

  vim.system({ "git", "fetch", "--quiet", "--no-tags" }, {
    cwd = root,
    env = { GIT_TERMINAL_PROMPT = "0", GIT_SSH_COMMAND = "ssh -o BatchMode=yes -o ConnectTimeout=5" },
    timeout = 20000,
  }, function()
    vim.schedule(function()
      stop_spinner()
      -- offline or auth failure is fine: the local snapshot is simply not newer
      git_state.data = read_local(root)
      redraw()
    end)
  end)
end

local function truncate(s, n)
  return #s > n and (s:sub(1, n - 1) .. "\u{2026}") or s
end

local function render(d)
  local items = {}
  local function row(text)
    items[#items + 1] = { text = text }
  end

  -- 1. branch, with the fetch spinner while the remote is being checked
  local head = { { ICON.branch .. "  " .. d.branch, hl = HL.head } }
  if git_state.fetching then
    head[#head + 1] = { "  " .. SPINNER[git_state.frame], hl = "dir" }
  end
  row(head)

  -- 2. working tree; zeros omitted, the way the statusline suppresses them
  local counts = {}
  local function part(icon, n, hl)
    if n > 0 then
      counts[#counts + 1] = { ("%s %d   "):format(icon, n), hl = hl }
    end
  end
  part(ICON.incoming, d.behind, HL.head)
  part(ICON.outgoing, d.ahead, HL.head)
  part(ICON.added, d.added, HL.added)
  part(ICON.changed, d.changed, HL.changed)
  part(ICON.removed, d.removed, HL.removed)
  if #counts > 0 then
    row(counts)
  end

  -- 3. three most recent commits
  for _, c in ipairs(d.commits) do
    row {
      { c.hash .. "  ", hl = HL.head },
      { truncate(c.subject, PANE_WIDTH - #c.hash - 8), hl = "desc" },
    }
  end

  -- 4. three most recently committed branches, with their drift from origin
  for _, b in ipairs(d.branches) do
    local parts = { { truncate(b.name, 30), hl = "dir" } }
    if not b.tracked then
      parts[#parts + 1] = { "  (local)", hl = "desc" }
    else
      if b.behind > 0 then
        parts[#parts + 1] = { ("  %s %d"):format(ICON.incoming, b.behind), hl = HL.head }
      end
      if b.ahead > 0 then
        parts[#parts + 1] = { ("  %s %d"):format(ICON.outgoing, b.ahead), hl = HL.head }
      end
    end
    row(parts)
  end

  return items
end

local function git()
  local ok, snacks_git = pcall(require, "snacks.git")
  if not ok then
    return {}
  end
  local root = snacks_git.get_root()
  if not root then
    return {}
  end

  -- cached, so spinner frames and resizes re-render without re-running git
  if git_state.root ~= root or not git_state.data then
    git_state.root = root
    git_state.data = read_local(root)
    maybe_fetch(root)
  end

  return render(git_state.data)
end

------------------------------------------------------------------------------ header

-- The cwd, centred over the whole board.
--
-- D:render gives a pane-1 line an indent of `col - (width - PANE_WIDTH) / 2`, which
-- centres it on *pane 1's* midpoint however wide it grows, and a negative indent is
-- clamped to column 0. Either way a header dropped in pane 1 lands over the left column
-- rather than over the board, and leading spaces inside the line are the only lever on
-- that. So replay the placement and walk the padding up until the text sits on the
-- board's midpoint: each space moves it right by one column or none, so the walk lands
-- exactly on the target and always terminates.
--
-- Pane 2 opens with a spacer item covering these rows, because a pane-1 line wider than
-- PANE_WIDTH pushes whatever shares its row to the right.
local function header()
  -- D:layout's own formula. vim.o.columns rather than the dashboard window width, which
  -- is not reachable from here; the two agree for the full-screen window it opens in.
  -- Clamped to the two panes this config actually fills.
  local panes = math.floor((vim.o.columns + PANE_GAP) / (PANE_WIDTH + PANE_GAP))
  panes = math.min(math.max(panes, 1), 2)

  local board = PANE_WIDTH * panes + PANE_GAP * (panes - 1)
  local margin = (vim.o.columns - board) / 2

  local cwd = vim.fn.fnamemodify(vim.uv.cwd() or "", ":~")
  if vim.api.nvim_strwidth(cwd) > board then
    cwd = vim.fn.pathshorten(cwd)
  end
  local len = vim.api.nvim_strwidth(cwd)

  -- the column D:render would start the text at, for a given amount of padding
  local function text_start(pad)
    local line = math.max(PANE_WIDTH, pad + len) -- D:align pads the line out to PANE_WIDTH
    local indent = line > PANE_WIDTH and margin - math.floor((line - PANE_WIDTH) / 2) or margin
    return math.floor(math.max(indent, 0)) + pad
  end

  local target = math.floor(margin + board / 2 - len / 2)
  local pad = 0
  while pad < vim.o.columns and text_start(pad) < target do
    pad = pad + 1
  end

  return { { text = { { (" "):rep(pad) .. cwd, hl = "header" } } } }
end

-- The telescope picker behind each list, parked directly under it.
---@param key string
---@param desc string
---@param action string
local function picker(key, desc, action)
  return { pane = 2, indent = 2, padding = 1, icon = " ", key = key, desc = desc, action = action }
end

M.opts = {
  preset = {
    keys = {
      { icon = " ", key = "l", desc = "Last Project", action = ":NeovimProjectLoadRecent" },
      { icon = " ", key = "a", desc = "Projects (Alphabet)", action = ":NeovimProjectDiscover alphabetical_name" },
      { icon = " ", key = "h", desc = "Projects (History)", action = ":NeovimProjectDiscover history" },
      { icon = " ", key = "d", desc = "Projects (Path)", action = ":NeovimProjectDiscover alphabetical_path" },
      { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
      { icon = "󰈭 ", key = "w", desc = "Find Word", action = ":Telescope live_grep" },
      { icon = " ", key = "c", desc = "Mappings", action = ":NvCheatsheet" },
      -- snacks binds q to `:bd` in D:init, but item keys are applied later in
      -- D:update -> D:keys, so this wins.
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    },
  },

  -- `padding` is { below, above }, and on a section D:resolve hangs it off the first and
  -- last *child* -- so padding above a section lands under its title, not over it. Gaps
  -- between blocks are therefore set on the items themselves.
  sections = {
    { pane = 1, padding = 1, header },
    { pane = 1, section = "keys", gap = 1, padding = 1 },
    { pane = 1, icon = " ", title = "Git", indent = 2, padding = 1, git },

    -- Two dead rows to sit out the header and the blank line under it: a pane-1 line
    -- wider than PANE_WIDTH shoves whatever shares its row to the right.
    { pane = 2, padding = 1, text = "" },

    -- the section's own padding is the blank row asked for between the list and its button
    { pane = 2, icon = " ", title = "Projects", indent = 2, padding = 1, projects },
    picker("p", "Recent Projects", ":NeovimProjectHistory"),

    { pane = 2, icon = " ", title = "Recent Files", indent = 2, recent_files },
    picker("o", "Recent Files", ":Telescope oldfiles"),

    -- last, so it also lands at the bottom when a narrow window folds both panes into one
    { pane = 1, section = "startup" },
  },
}

return M
