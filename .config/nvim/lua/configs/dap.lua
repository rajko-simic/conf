local dap = require "dap"

-- https://emojipedia.org/en/stickers/search?q=circle
vim.fn.sign_define("DapBreakpoint", {
  text = "🔴",
  texthl = "DapBreakpointSymbol",
  linehl = "DapBreakpoint",
  numhl = "DapBreakpoint",
})

vim.fn.sign_define("DapStopped", {
  text = "🟢",
  texthl = "yellow",
  linehl = "DapBreakpoint",
  numhl = "DapBreakpoint",
})

vim.fn.sign_define("DapBreakpointRejected", {
  text = "🟡",
  texthl = "DapStoppedSymbol",
  linehl = "DapBreakpoint",
  numhl = "DapBreakpoint",
})

vim.fn.sign_define("DapBreakpointCondition", {
  text = "⭕",
  texthl = "DapBreakpointSymbol",
  linehl = "DapBreakpoint",
  numhl = "DapBreakpoint",
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
    command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
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
      local metadata = vim.fn.system "cargo metadata --no-deps --format-version 1 2>/dev/null"
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
      local input = vim.fn.input "Program arguments: "
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

--Python
local mason = vim.fn.stdpath "data" .. "/mason"

dap.adapters.python = {
  type = "executable",
  command = mason .. "/bin/debugpy-adapter",
}

dap.configurations.python = {
  {
    type = "python",
    name = "Launch file",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    justMyCode = false,
    -- Prefer the project's own venv so imports resolve; fall back to whatever is on PATH.
    pythonPath = function()
      for _, venv in ipairs { ".venv", "venv" } do
        local exe = vim.uv.cwd() .. "/" .. venv .. "/bin/python"
        if vim.fn.executable(exe) == 1 then
          return exe
        end
      end
      return vim.fn.exepath "python3"
    end,
  },
  {
    type = "python",
    name = "Attach to port",
    request = "attach",
    connect = function()
      return { host = "127.0.0.1", port = tonumber(vim.fn.input "Port: " or "5678") }
    end,
  },
}

--Bash / sh
dap.adapters.bashdb = {
  type = "executable",
  command = mason .. "/bin/bash-debug-adapter",
  name = "bashdb",
}

dap.configurations.sh = {
  {
    type = "bashdb",
    request = "launch",
    name = "Debug script",
    program = "${file}",
    cwd = "${workspaceFolder}",
    pathBashdb = mason .. "/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
    pathBashdbLib = mason .. "/packages/bash-debug-adapter/extension/bashdb_dir",
    pathBash = "bash",
    pathCat = "cat",
    pathMkfifo = "mkfifo",
    pathPkill = "pkill",
    env = {},
    args = {},
    terminalKind = "integrated",
  },
}
dap.configurations.bash = dap.configurations.sh

--Ansible (ansibug -- optional, only wired when `pip install --user ansibug` has been run)
if vim.fn.executable "ansibug" == 1 then
  dap.adapters.ansibug = {
    type = "executable",
    command = "ansibug",
    args = { "dap" },
  }

  dap.configurations["yaml.ansible"] = {
    {
      type = "ansibug",
      request = "launch",
      name = "Run playbook",
      playbook = "${file}",
      args = function()
        return vim.split(vim.fn.input "ansible-playbook args: ", " ", { trimempty = true })
      end,
    },
  }
end

