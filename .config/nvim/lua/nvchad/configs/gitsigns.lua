dofile(vim.g.base46_cache .. "git")

return {
  signs = {
    delete = { text = "󰍵" },
    changedelete = { text = "󱕖" },
  },
  numhl = true,
  current_line_blame = true
}
