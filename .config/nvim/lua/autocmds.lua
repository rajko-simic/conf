local autocmd = vim.api.nvim_create_autocmd

-- user event that loads after UIEnter + only if file buf is there
autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("NvFilePost", { clear = true }),
  callback = function(args)
    local file = vim.api.nvim_buf_get_name(args.buf)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })

    if not vim.g.ui_entered and args.event == "UIEnter" then
      vim.g.ui_entered = true
    end

    if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
      vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })
      vim.api.nvim_del_augroup_by_name "NvFilePost"

      vim.schedule(function()
        vim.api.nvim_exec_autocmds("FileType", {})

        if vim.g.editorconfig then
          require("editorconfig").config(args.buf)
        end
      end)
    end
  end,
})

-- Report the cwd to the terminal (OSC 7) so a new Konsole tab/window opened from
-- this one starts in the current project, not where nvim was launched. Empty host
-- on purpose: Konsole only accepts file:// urls whose host is empty or matches the
-- machine hostname.
local function osc7_encode(path)
  return (path:gsub("[^A-Za-z0-9%-%._~/]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("Osc7Cwd", { clear = true }),
  callback = function()
    local cwd = vim.uv.cwd()
    if cwd then
      vim.api.nvim_ui_send("\27]7;file://" .. osc7_encode(cwd) .. "\27\\")
    end
  end,
})
