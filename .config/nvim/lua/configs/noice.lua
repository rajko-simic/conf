return {
  cmdline = {
    enabled = true,
    view = "cmdline_popup",
    opts = {},
    format = {
      cmdline     = { icon = ">" },
      search_down = { icon = "🔍⌄" },
      search_up   = { icon = "🔍⌃" },
      filter      = { icon = "$" },
      lua         = { icon = "☾" },
      help        = { icon = "?" },
    },
  },
  views = {
    cmdline_popup = {
      position = {
        row = "50%",
        col = "50%",
      },
      size = {
        width = 60,
        height = "auto",
      },
      border = {
        style = "rounded",
      },
      win_options = {
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
      },
    },
  },
  -- `notify` resolves to the snacks notifier (noice tries snacks, then nvim-notify,
  -- then falls back to its own `mini`). Unlike `mini`, it can replace a notification in
  -- place, which is what stops timer-driven spinners stacking one line per tick.
  notify = { enabled = true, view = "notify" },
  messages = { enabled = true },
  lsp = {
    -- lspsaga owns hover, blink.cmp owns signature help, NvChad statusline lsp_msg owns progress
    hover = { enabled = false },
    signature = { enabled = false },
    progress = { enabled = false },
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  presets = {
    bottom_search = false,
    command_palette = false,
    long_message_to_split = true,
  },
  routes = {
    {
      filter = { event = "msg_show", kind = { "emsg", "wmsg" } },
      view = "notify",
    },
  },
}
