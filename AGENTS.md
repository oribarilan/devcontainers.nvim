# AGENTS.md - AI Coding Agent Guidelines

> Guidelines for AI agents working in the devcontainers.nvim codebase.

## Project Overview

Neovim plugin for seamless development container integration. Manages Neovim config inside Dev Containers using **bob** for version management and **readonly mounts** for host configuration.

**Language**: Lua (Neovim plugin)  
**Min Neovim**: 0.8.0+  
**Testing**: Custom minimal test runner (no external dependencies)

## Build/Lint/Test Commands

```bash
# Run ALL tests
make test

# Run tests directly (verbose output)
nvim --headless --noplugin -u NONE -c "set runtimepath+=." -c "lua require('devcontainers.test_runner').run()"

# Check dependencies
make check-deps

# Clean temp files
make clean
```

### Running a Single Test File

The test runner auto-discovers `tests/unit/**/*_spec.lua`. To run a single file:

```bash
# Modify test_runner.lua temporarily, or:
nvim --headless --noplugin -u NONE -c "set runtimepath+=." -c "lua dofile('tests/unit/commands_spec.lua')"
```

### Test DSL

Tests use a minimal busted-compatible DSL:

```lua
describe("module name", function()
  before_each(function()
    -- setup
  end)
  
  after_each(function()
    -- teardown
  end)
  
  it("should do something", function()
    assert(condition, "error message")
  end)
end)
```

## File Structure

```
lua/devcontainers/
├── init.lua              -- Entry point, setup(), public API
├── config.lua            -- Configuration defaults, validation, merge
├── setup.lua             -- Plugin initialization, autocommands
├── commands.lua          -- User command definitions
├── dc_cli.lua            -- devcontainer CLI wrapper
├── utils.lua             -- File/string/table utilities
├── debug.lua             -- Logging system
├── statusline.lua        -- Terminal statusline management
├── statusline_plugins.lua-- Statusline plugin integrations
└── test_runner.lua       -- Minimal test framework

tests/unit/
├── *_spec.lua            -- Test files (auto-discovered)
```

## Code Style Guidelines

### Module Pattern

Every module follows this pattern:

```lua
local M = {}

-- Private state (module-scoped)
local state = {
  initialized = false,
}

-- Public functions
function M.setup(config)
  -- implementation
end

return M
```

### Formatting

- **Indentation**: 2 spaces (no tabs)
- **Line length**: ~100 chars soft limit
- **Strings**: Double quotes preferred (`"string"`)
- **Trailing commas**: Yes, in multi-line tables

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules | `local M = {}` | Always `M` |
| Functions | `snake_case` | `get_nvim_version()` |
| Local vars | `snake_case` | `host_path` |
| Constants | `UPPER_SNAKE` | `LOG_LEVELS` |
| Private state | `_state` or `state` | `local state = {}` |
| Boolean vars | `is_*`, `has_*` | `is_valid`, `has_config` |

### Imports

```lua
-- Always at top of file
local debug = require("devcontainers.debug")
local utils = require("devcontainers.utils")

-- Lazy require for circular dependency prevention
local function get_config()
  return require("devcontainers").get_config()
end
```

### Error Handling

```lua
-- Return tuple pattern: (result, error_string)
function M.get_nvim_version()
  local handle = io.popen("nvim --version 2>/dev/null")
  if not handle then
    return nil, "failed to execute nvim --version"
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  if not success or not output then
    return nil, "nvim command failed"
  end
  
  local version = output:match("NVIM v([%d%.]+)")
  if not version then
    return nil, "could not parse nvim version"
  end
  
  return version, nil
end

-- Usage
local version, err = utils.get_nvim_version()
if not version then
  debug.error("version check failed: " .. (err or "unknown"))
  return
end
```

### Neovim API Usage

```lua
-- Prefer vim.api over vim.cmd for programmatic operations
vim.api.nvim_create_user_command("CommandName", handler, { desc = "..." })
vim.api.nvim_create_autocmd("Event", { group = augroup, callback = fn })

-- Use vim.loop (libuv) for filesystem
local stat = vim.loop.fs_stat(path)
if stat and stat.type == "file" then ... end

-- Use vim.fn for vimscript functions
local cwd = vim.loop.cwd()
local winid = vim.fn.bufwinid(bufnr)

-- User notifications
vim.notify("message", vim.log.levels.ERROR)  -- ERROR, WARN, INFO
```

### Debug Logging

```lua
local debug = require("devcontainers.debug")

debug.error("critical failure")   -- Always shown when debug=true
debug.warn("potential issue")     -- WARN level
debug.info("operation started")   -- INFO level (default)
debug.debug("detailed info")      -- DEBUG level
debug.trace("very verbose")       -- TRACE level
```

### Configuration Validation

```lua
-- In config.lua - validate returns (bool, error_string)
function M.validate(config)
  if type(config) ~= "table" then
    return false, "configuration must be a table"
  end
  
  if config.debug ~= nil and type(config.debug) ~= "boolean" then
    return false, "debug must be a boolean"
  end
  
  return true, nil
end
```

### Command Pattern

```lua
-- In commands.lua
local commands = {}

commands.DevcontainerUp = {
  name = "DevcontainerUp",
  desc = "Spins up containers with devcontainer.json settings",
  handler = function()
    debug.info("executing DevcontainerUp command")
    local config = require("devcontainers").get_config()
    dc_cli.devcontainer_up(nil, config)
  end,
}
```

## Common Patterns

### Safe External Command Execution

```lua
function M.execute_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return false, nil, "failed to execute command"
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  return success, M.trim(output or ""), nil
end
```

### Path Expansion

```lua
-- Handle ~, $HOME, ${VAR} expansion
function M.expand_path(path)
  if path:match("^~") then
    path = path:gsub("^~", os.getenv("HOME") or "")
  end
  path = path:gsub("^%$HOME", os.getenv("HOME") or "")
  return path
end
```

## Don'ts

- **Don't** use `vim.cmd` for things `vim.api` can do
- **Don't** swallow errors silently - always log or return error
- **Don't** use global variables (except in test DSL)
- **Don't** require modules inside loops
- **Don't** assume paths exist - always check with `utils.dir_exists()`
- **Don't** hardcode `/home/vscode` without fallback logic

## Testing Guidelines

- Test files must end in `_spec.lua`
- Place in `tests/unit/`
- Use `assert(condition, "message")` for assertions
- Mock external dependencies (io.popen, vim.fn.system)
- Test both success and failure paths
