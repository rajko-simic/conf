require("notify").setup({
  stages = "fade",
  timeout = 3000,
  max_height = 5,
  top_down = false, -- grows upward, placing it above the statusline
  background_colour = "#000000",
})

vim.notify = require("notify")
