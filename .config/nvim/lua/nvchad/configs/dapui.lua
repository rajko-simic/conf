local dapui = require("dapui")
local dap = require("dap")

-- open the ui as soon as we are debugging
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- https://emojipedia.org/en/stickers/search?q=circle
vim.fn.sign_define('DapBreakpoint',
  {
    text = '🔴',
    texthl = 'DapBreakpointSymbol',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })

vim.fn.sign_define('DapStopped',
  {
    text = '🟢',
    texthl = 'yellow',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })

vim.fn.sign_define('DapBreakpointRejected',
  {
    text = '🟡',
    texthl = 'DapStoppedSymbol',
    linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint'
  })

vim.fn.sign_define('DapBreakpointCondition', {
  text    = '⭕',
  texthl  = 'DapBreakpointSymbol',
  linehl  = 'DapBreakpoint',
  numhl   = 'DapBreakpoint',
})

-- more minimal ui
dapui.setup({
  expand_lines = true,
  controls = { enabled = false }, -- no extra play/step buttons
  floating = { border = "rounded" },

  render = {
    max_type_length = 60,
    max_value_lines = 200,
  },

  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.6 }, -- 1.0 100% of this panel is scopes
        { id = "console", size = 0.4 },
        -- { id = "repl", size = 0.4 },
      },
      size = 14,
      position = "bottom",
    },
    {
      elements = {
        { id = "breakpoints", size = 0.5 }, -- 1.0 100% of this panel is scopes
        -- { id = "watches", size = 0.5 },
      },
      size = 50,
      position = "left",
    },
  },
})
