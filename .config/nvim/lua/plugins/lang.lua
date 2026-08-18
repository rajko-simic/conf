-- Language-specific tooling.

return {
  -- Dotnet / C#
  {
    "GustavEikaas/easy-dotnet.nvim",
    ft = { "cs", "csproj", "sln", "slnx", "props", "csx", "targets" },
    cmd = { "Dotnet" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      require "configs.easydotnet"
    end,
  },

  -- TypeScript
  "pmizio/typescript-tools.nvim",

  -- Flutter
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = { "dart", "pubspec.yaml" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require "configs.flutter"
    end,
  },

  {
    "akinsho/pubspec-assist.nvim",
    ft = { "dart", "pubspec.yaml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },
}
