require("neotest").setup({
  adapters = {
    require("neotest-vstest")({}),
    -- future: require("neotest-go"), require("neotest-python"), ...
  },
  quickfix = { open = false },
  status = { virtual_text = true },
  output = { open_on_run = true },
})
