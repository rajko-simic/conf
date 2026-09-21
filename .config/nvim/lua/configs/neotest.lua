require("neotest").setup {
  adapters = {
    require "easy-dotnet.neotest",
  },
  quickfix = { open = false },
  status = { virtual_text = true },
  output = { open_on_run = true },
}
