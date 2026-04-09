return function()
  dofile(vim.g.base46_cache .. "whichkey")
  return {
    defer = function() return false end,
  }
end
