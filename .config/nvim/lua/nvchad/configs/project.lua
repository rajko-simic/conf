return {
  manual_mode = false,
  silent_chdir = false,
  display_type = 'full',
  show_hidden = true,
  sync_with_nvim_tree = true,
  detection_methods = { "pattern", "lsp" },
  patterns = {
    ".git",             -- common VCS
    "*.sln",            -- .NET solution
    "Program.cs",       -- .NET entry
    "Cargo.toml",       -- Rust
    "go.mod",           -- Go
    "main.go",          -- Go entry
    "init.lua",         -- Lua config
    "*.lua",            -- Lua script
    "*.md",             -- Markdown
    "*.sql",            -- SQL files
    "pubspec.yaml",     -- Flutter
    "android/app",      -- Flutter Android structure
    "*.dart",           -- Flutter/Dart files
    "*.kt",             -- Kotlin files:
    "build.gradle",     -- Kotlin/Android build
  },
}
