local M = {}

local function has_client(name)
  return #vim.lsp.get_clients({ bufnr = 0, name = name }) > 0
end

local function is_dotnet_ft(ft)
  return ft == "cs" or ft == "csproj" or ft == "sln" or ft == "slnx"
      or ft == "props" or ft == "targets" or ft == "csx"
end

local function is_flutter_ft(ft, bufname)
  return ft == "dart" or (ft == "yaml" and vim.fs.basename(bufname) == "pubspec.yaml")
end

local function open_flutter()
  local ok = pcall(require, "flutter-tools")
  if not ok then
    vim.notify("flutter-tools not available", vim.log.levels.ERROR)
    return
  end
  pcall(require("telescope").load_extension, "flutter")
  vim.cmd("Telescope flutter commands")
end

function M.open()
  if has_client("easy_dotnet") then
    vim.cmd("Dotnet")
    return
  end
  if has_client("dartls") then
    open_flutter()
    return
  end
  local ft, bufname = vim.bo.filetype, vim.api.nvim_buf_get_name(0)
  if is_dotnet_ft(ft) then
    vim.cmd("Dotnet")
  elseif is_flutter_ft(ft, bufname) then
    open_flutter()
  else
    vim.notify("No Dotnet or Flutter context in this buffer", vim.log.levels.WARN)
  end
end

return M
