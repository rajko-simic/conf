-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "default-light",
  theme_toggle = { "material-deep-ocean", "default-light" },
	hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},
}

M.cheatsheet = {
    theme = "grid", -- simple/grid
    excluded_groups = {}, -- can add group name or with mode
  }

M.nvdash = {
  -- Replaced by snacks.dashboard (lua/configs/dashboard.lua). Everything below is
  -- left as it was so flipping this back restores the old dashboard verbatim.
    load_on_startup = false,
    header = {
      "                            ",
      "           eovim           ",
      "                            ",
    },

    buttons = {
      { txt = "  Last Project", keys = "pl", cmd = "NeovimProjectLoadRecent" },
      { txt = "  Recent Projects", keys = "ph", cmd = "NeovimProjectHistory" },
      { txt = "  Projects (Alphabet)", keys = "pda", cmd = "NeovimProjectDiscover alphabetical_name" },
      { txt = "  Projects (History)", keys = "pdh", cmd = "NeovimProjectDiscover history" },
      { txt = "  Projects (Path)", keys = "pdp", cmd = "NeovimProjectDiscover alphabetical_path" },
      { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
      { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
      { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
      { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },

      { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

      {
        txt = function()
          local stats = require("lazy").stats()
          local ms = math.floor(stats.startuptime) .. " ms"
          return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
        end,
        hl = "NvDashFooter",
        no_gap = true,
      },

      { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
    },
}

M.ui = {
  tabufline = {
    lazyload = false,
    order = { "buffers", "tabs", "btns" },
    modules = {
      -- Upstream's `buffers` is O(n^2) in buffer count; a 290-buffer session cost
      -- 1275 ms per tabline render, i.e. per redraw. See lua/configs/tabufline.lua.
      buffers = function()
        return require("configs.tabufline").buffers()
      end,
    },
  },

  statusline = {
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "progress", "dap_frame", "dap_session", "diagnostics", "lsp", "cwd", "cursor" },
    modules = {
      -- Progress from tools that bypass vim.lsp. Sources are listed in
      -- configs/progress.lua; language servers report through lsp_msg instead.
      progress = function()
        for _, source in ipairs(require "configs.progress") do
          local ok, text = pcall(source)
          if ok and type(text) == "string" and text ~= "" then
            return "%#St_LspMsg# " .. text .. " "
          end
        end
        return ""
      end,

      dap_session = function()
        local ok, dap = pcall(require, "dap")
        if not ok then return "" end
        local session = dap.session()
        if not session then return "" end
        local adapter = session.config and session.config.type or "dap"
        local status = dap.status()
        status = (status ~= "" and status) or "Running"
        return "%#St_lspError#  " .. adapter .. ": " .. status .. " "
      end,

      dap_frame = function()
        local ok, dap = pcall(require, "dap")
        if not ok then return "" end
        local session = dap.session()
        if not session or not session.current_frame then return "" end
        local frame = session.current_frame
        local file = (frame.source and frame.source.name) or "?"
        local lnum = frame.line or "?"
        local name = frame.name or "?"
        return "%#St_LspInfo#  " .. file .. ":" .. lnum .. " in " .. name .. " "
      end,

      lsp = function()
        if rawget(vim, "lsp") then
          for _, client in ipairs(vim.lsp.get_clients()) do
            if client.attached_buffers[require("nvchad.stl.utils").stbufnr()] then
              return (vim.o.columns > 100 and "%#St_Lsp# " .. client.name .. " ") or "%#St_Lsp# LSP"
            end
          end
        end
        return ""
      end,
    },
  },
}

-- blink.cmp owns signature help; disable NvChad's TextChangedI signature autocmd
M.lsp = { signature = false }

M.term = {
  float = {
    relative = "editor",
    row = 0.1,
    col = 0.1,
    width = 0.8,
    height = 0.8,
    border = "single",
  },
}

return M

