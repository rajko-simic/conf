local dap = require("dap")

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

--Golang
local dlv_path = vim.fn.stdpath "data" .. "/mason/bin/dlv"
if vim.fn.executable(dlv_path) ~= 1 then
  dlv_path = vim.fn.expand "~" .. "/go/bin/dlv"
end
dap.adapters.go = {
  type = "server",
  port = "${port}",
  executable = {
    command = dlv_path,
    args = { "dap", "-l", "127.0.0.1:${port}" },
  },
}

dap.configurations.go = {
  {
    type = "go",
    name = "Debug",
    request = "launch",
    program = "${file}",
  },
}

--Rust
-- Adapter
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
    args = { "--port", "${port}" },
  },
}

-- Configuration
dap.configurations.rust = {
  {
    name = "Launch binary",
    type = "codelldb",
    request = "launch",
    program = function()
      -- Auto-detect binary from Cargo.toml project name
      local metadata = vim.fn.system("cargo metadata --no-deps --format-version 1 2>/dev/null")
      local ok, decoded = pcall(vim.fn.json_decode, metadata)
      local target_name = (ok and decoded.packages[1] and decoded.packages[1].name) or nil

      if target_name then
        local bin = "target/debug/" .. target_name
        if vim.fn.filereadable(bin) == 1 then
          return vim.fn.getcwd() .. "/" .. bin
        end
      end

      -- Fallback: prompt user
      return vim.fn.input("Path to binary: ", vim.fn.getcwd() .. "/target/debug/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
  {
    name = "Launch binary (with args)",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to binary: ", vim.fn.getcwd() .. "/target/debug/", "file")
    end,
    args = function()
      local input = vim.fn.input("Program arguments: ")
      return vim.split(input, " ", { trimempty = true })
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
  {
    name = "Attach to process",
    type = "codelldb",
    request = "attach",
    pid = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}",
  },
}

-- local mason_path = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg"
--
-- local netcoredbg_adapter = {
--   type = "executable",
--   command = mason_path,
--   args = { "--interpreter=vscode" },
-- }
--
-- dap.adapters.netcoredbg = netcoredbg_adapter -- needed for normal debugging
-- dap.adapters.coreclr = netcoredbg_adapter    -- needed for unit test debugging
--
-- dap.configurations.cs = {
--   {
--     type = "coreclr",
--     name = "launch - netcoredbg",
--     request = "launch",
-- program = function()
--       -- return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/src/", "file")
--       return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/net10.0/", "file")
--     end,
--
--     -- justMyCode = false,
--     -- stopAtEntry = false,
--     -- -- program = function()
--     -- --   -- todo: request input from ui
--     -- --   return "/path/to/your.dll"
--     -- -- end,
--     -- env = {
--     --   ASPNETCORE_ENVIRONMENT = function()
--     --     -- todo: request input from ui
--     --     return "Development"
--     --   end,
--     --   ASPNETCORE_URLS = function()
--     --     -- todo: request input from ui
--     --     return "http://localhost:5050"
--     --   end,
--     -- },
--     -- cwd = function()
--     --   -- todo: request input from ui
--     --   return vim.fn.getcwd()
--     -- end,
--   },
-- }
