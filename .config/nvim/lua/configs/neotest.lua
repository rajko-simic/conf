require("neotest").setup {
  adapters = {
    -- easy-dotnet's built-in adapter; requires test_runner.neotest_integration = true
    -- in configs/easydotnet.lua so the two do not both draw signs and keymaps.
    require "easy-dotnet.neotest",
    -- future: require("neotest-go"), require("neotest-python"), ...
    -- Add the matching filetype to `ft` in lua/plugins/test.lua when you do.
  },
  quickfix = { open = false },
  status = { virtual_text = true },
  output = { open_on_run = true },
}
