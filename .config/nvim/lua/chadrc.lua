-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "default-light",
  theme_toggle = { "everblush", "default-light" },
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
    load_on_startup = true,
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
      { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
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
         order = {"buffers", "tabs", "btns"}
  }
}

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

