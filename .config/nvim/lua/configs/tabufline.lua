-- Drop-in replacement for NvChad's tabufline `buffers` module.
--
-- WHY: upstream is O(n^2) in the number of listed buffers. `modules.lua` calls
-- `utils.style_buf` per buffer, and `style_buf` -> `gen_unique_name` walks all of
-- `vim.t.bufs` again, matching an UNANCHORED Lua pattern against ~110-char absolute
-- paths. Measured on a 290-buffer session: 1275 ms of blocking Lua *per tabline render*.
-- Every redraw pays it -- window switch, <leader> (which-key), <Tab> -- which is what
-- made opening a large .NET project feel like a 20 s freeze. Precomputing basename
-- counts once makes the same render 1.7 ms. Anchoring the pattern alone is not enough
-- (still quadratic: 444 ms).
--
-- Behaviour is intentionally identical to upstream, including the `parentdir/name`
-- disambiguation for buffers that share a basename.
--
-- VENDORED FROM nvchad/ui: lua/nvchad/tabufline/utils.lua (new_hl, style_buf) and
-- lua/nvchad/tabufline/modules.lua (available_space, tabs, btns, buffers). `txt`/`btn`
-- are exported upstream and reused rather than copied. If the tabline ever renders
-- wrong after updating nvchad/ui, diff against those two files.

local api = vim.api
local fn = vim.fn
local g = vim.g
local strep = string.rep
local get_opt = api.nvim_get_option_value
local get_hl = api.nvim_get_hl
local cur_buf = api.nvim_get_current_buf
local buf_name = api.nvim_buf_get_name

local utils = require "nvchad.tabufline.utils"
local txt, btn = utils.txt, utils.btn

local M = {}

-- Anchored, unlike upstream's "([^/\\]+)[/\\]*$" -- O(len) instead of O(len^2).
local function basename(path)
  return path:match "[^/\\]*$"
end

--------------------------------------------------------------------- basename counts
-- Rebuilt only when the buffer list can have changed, rather than per styled buffer.

local counts, dirty = {}, true

api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout", "BufFilePost", "TabEnter" }, {
  group = api.nvim_create_augroup("user_tabufline_names", { clear = true }),
  callback = function()
    dirty = true
  end,
})

local function name_counts()
  if dirty then
    counts = {}
    for _, nr in ipairs(vim.t.bufs or {}) do
      local name = basename(buf_name(nr))
      if name ~= "" then
        counts[name] = (counts[name] or 0) + 1
      end
    end
    dirty = false
  end
  return counts
end

--------------------------------------------------------------------------- rendering

local function new_hl(group1, group2)
  local fg = get_hl(0, { name = group1 }).fg
  local bg = get_hl(0, { name = "Tb" .. group2 }).bg
  api.nvim_set_hl(0, group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. group1 .. group2 .. "#"
end

local function style_buf(nr, w, shared)
  local icon = "󰈚 "
  local is_curbuf = cur_buf() == nr
  local tbHlName = "BufO" .. (is_curbuf and "n" or "ff")
  local icon_hl = new_hl("DevIconDefault", tbHlName)

  local path = buf_name(nr)
  local name = basename(path)

  if name == "" then
    name = " No Name "
  elseif (shared[name] or 0) > 1 then
    -- same disambiguation upstream applies, without the n^2 scan
    name = fn.fnamemodify(path, ":h:t") .. "/" .. name
  end

  if name ~= " No Name " then
    local devicon, devicon_hl = require("nvim-web-devicons").get_icon(name)
    if devicon then
      icon = " " .. devicon .. " "
      icon_hl = new_hl(devicon_hl, tbHlName)
    end
  end

  -- padding around bufname; 5 = 2 icon & space + 2 close icon + 1
  local pad = math.floor((w - #name - 5) / 2)
  pad = pad <= 0 and 1 or pad

  local maxname_len = w - 5
  name = string.sub(name, 1, maxname_len - 2) .. (#name > maxname_len and ".." or "")
  name = txt(name, tbHlName)
  name = strep(" ", pad - 1) .. (icon_hl .. icon .. name) .. strep(" ", pad - 1)

  local close_btn = btn(" 󰅖 ", nil, "KillBuf", nr)
  name = btn(name, nil, "GoToBuf", nr)

  local mod = get_opt("mod", { buf = nr })
  local cur_mod = get_opt("mod", { buf = 0 })

  if is_curbuf then
    close_btn = cur_mod and txt("  ", "BufOnModified") or txt(close_btn, "BufOnClose")
  else
    close_btn = mod and txt("  ", "BufOffModified") or txt(close_btn, "BufOffClose")
  end

  return txt(name .. close_btn, "BufO" .. (is_curbuf and "n" or "ff"))
end

-- Copies of the sibling modules, used only to measure how much width they take. They
-- are not installed as overrides -- upstream still renders them.
local function render_tabs()
  local result, tabs = "", fn.tabpagenr "$"
  if tabs > 1 then
    for nr = 1, tabs, 1 do
      local tab_hl = "TabO" .. (nr == fn.tabpagenr() and "n" or "ff")
      result = result .. btn(" " .. nr .. " ", tab_hl, "GotoTab", nr)
    end
    local new_tabtn = btn(" 󰐕 ", "TabNewBtn", "NewTab")
    local tabstoggleBtn = btn(" TABS ", "TabTitle", "ToggleTabs")
    local small_btn = btn(" 󰅁 ", "TabTitle", "ToggleTabs")
    return g.TbTabsToggled == 1 and small_btn or new_tabtn .. tabstoggleBtn .. result
  end
  return ""
end

local function render_btns()
  local toggle_theme = btn(g.toggle_theme_icon, "ThemeToggleBtn", "Toggle_theme")
  local closeAllBufs = btn(" 󰅖 ", "CloseAllBufsBtn", "CloseAllBufs")
  return toggle_theme .. closeAllBufs
end

local function tree_offset_width()
  local opts = require("nvconfig").ui.tabufline
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].ft == opts.treeOffsetFt then
      return api.nvim_win_get_width(win)
    end
  end
  return 0
end

-- Upstream calls this once per buffer inside the loop; hoisted out here.
local function available_space(opts)
  local str = ""
  for _, key in ipairs(opts.order) do
    if key == "tabs" then
      str = str .. render_tabs()
    elseif key == "btns" then
      str = str .. render_btns()
    elseif key == "treeOffset" then
      str = str .. strep(" ", tree_offset_width())
    end
  end
  return vim.o.columns - api.nvim_eval_statusline(str, { use_tabline = true }).width
end

M.buffers = function()
  local opts = require("nvconfig").ui.tabufline
  local buffers = {}
  local has_current = false

  vim.t.bufs = vim.tbl_filter(api.nvim_buf_is_valid, vim.t.bufs)

  local shared = name_counts()
  local space = available_space(opts)

  for _, nr in ipairs(vim.t.bufs) do
    if ((#buffers + 1) * opts.bufwidth) > space then
      if has_current then
        break
      end
      table.remove(buffers, 1)
    end

    has_current = cur_buf() == nr or has_current
    table.insert(buffers, style_buf(nr, opts.bufwidth, shared))
  end

  return table.concat(buffers) .. txt("%=", "Fill")
end

return M
