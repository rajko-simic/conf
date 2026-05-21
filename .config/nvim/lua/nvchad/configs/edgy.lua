return {
  animate = { enabled = false },
  wo = {
    winbar = false,
  },
  left = {
    {
      title = "Files",
      ft = "NvimTree",
      size = { width = 30 },
      pinned = true,
      open = "NvimTreeFocus",
    },
  },
  bottom = {
    {
      title = "Trouble",
      ft = "trouble",
      size = { height = 0.3 },
    },
    {
      title = "DAP",
      ft = "dap-view",
      size = { height = 0.3 },
    },
    {
      title = "DAP Terminal",
      ft = "dap-view-term",
      size = { height = 0.3 },
    },
    {
      ft = "qf",
      title = "QuickFix",
      size = { height = 0.25 },
    },
  },
  right = {
    {
      title = "Neotest",
      ft = "neotest-summary",
      size = { width = 0.25 },
    },
    {
      title = "Neotest Output",
      ft = "neotest-output-panel",
      size = { height = 0.25 },
    },
  },
}
