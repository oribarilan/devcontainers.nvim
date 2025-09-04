# Contributing to devcontainers.nvim

This document provides information about the minimal plugin structure and development guidelines.

## File Structure

```
devcontainers.nvim/
├── lua/
│   └── devcontainers/
│       ├── init.lua           -- Plugin entry point and public API
│       ├── config.lua         -- Configuration management and defaults
│       ├── setup.lua          -- Setup logic and autocommands
│       ├── utils.lua          -- Utility functions (file, string, table ops)
│       └── debug.lua          -- Debug logging and development tools
├── tests/
│   └── unit/
│       ├── init_spec.lua      -- Tests for main plugin functionality
│       ├── config_spec.lua    -- Tests for configuration system
│       └── utils_spec.lua     -- Tests for utility functions
├── README.md                  -- User documentation and getting started guide
├── CONTRIBUTE.md              -- This file - development and contribution guidelines
├── CHANGELOG.md               -- Release notes and version history
├── LICENSE                    -- MIT license
└── .gitignore                 -- Git ignore patterns
```

## Core Components

### Plugin Architecture

This is a **minimal plugin template** with the following core components:

- **[`init.lua`](lua/devcontainers/init.lua)**: Main plugin entry point with setup() function and state management
- **[`config.lua`](lua/devcontainers/config.lua)**: Configuration management with validation and defaults
- **[`setup.lua`](lua/devcontainers/setup.lua)**: Plugin initialization and autocommand setup
- **[`utils.lua`](lua/devcontainers/utils.lua)**: Basic utility functions for common operations
- **[`debug.lua`](lua/devcontainers/debug.lua)**: Debug logging system for development

### Test Structure

- **[`tests/unit/`](tests/unit/)**: Unit tests for each module
- **Testing Framework**: Compatible with busted, plenary.nvim, or other Lua testing frameworks

## What's Included

### ✅ Basic Plugin Features

- Plugin initialization and setup
- Configuration management with validation
- Debug logging system
- Basic utility functions
- Autocommand setup
- Unit test structure

### 🚧 What's Not Included (Yet)

This template does **NOT** include actual devcontainer functionality:

- No devcontainer detection
- No Docker integration  
- No user commands
- No LSP integration
- No container management

## Development Setup

### Prerequisites

- Neovim >= 0.8.0
- Lua 5.1+
- Testing framework (busted, plenary.nvim, etc.)

### Local Development

1. Clone the repository
2. Install dependencies for testing
3. Use your preferred Neovim package manager to load the plugin locally
4. Enable debug logging:

```lua
require("devcontainers").setup({
  debug = true,
  log_level = "DEBUG"
})
```

### Running Tests

```bash
# With busted
busted tests/

# Run specific test file
busted tests/unit/config_spec.lua

# With plenary.nvim (in Neovim)
:PlenaryBustedDirectory tests/unit/
```

## Code Style and Guidelines

### Lua Code Style

- Use 2 spaces for indentation
- Follow standard Lua naming conventions
- Use descriptive variable and function names
- Keep functions focused and small
- Add comments for complex logic

### Testing

- Write unit tests for all modules
- Use descriptive test names
- Test both success and failure cases
- Mock external dependencies where needed

### Documentation

- Update README.md for user-facing changes
- Update this file for structural changes
- Add inline documentation for complex functions
- Update CHANGELOG.md for all changes

## Extending This Template

This is a minimal template that can be extended with actual functionality:

### 1. Add New Modules

Create new `.lua` files in `lua/devcontainers/` for specific functionality:

```lua
-- lua/devcontainers/new_feature.lua
local M = {}

function M.do_something()
  -- Implementation here
end

return M
```

### 2. Add User Commands

Extend [`setup.lua`](lua/devcontainers/setup.lua) to register user commands:

```lua
vim.api.nvim_create_user_command("YourCommand", function()
  require("devcontainers.your_module").do_something()
end, { desc = "Description of your command" })
```

### 3. Add Configuration Options

Extend [`config.lua`](lua/devcontainers/config.lua) defaults:

```lua
M.defaults = {
  -- existing options...
  your_new_option = "default_value",
}
```

### 4. Add Tests

Create corresponding test files in `tests/unit/`:

```lua
-- tests/unit/new_feature_spec.lua
describe("devcontainers.new_feature", function()
  it("should do something", function()
    -- Your test here
  end)
end)
```

## Example Extensions

### Devcontainer Detection

```lua
-- lua/devcontainers/detector.lua
local M = {}

function M.detect_devcontainer()
  -- Look for .devcontainer/devcontainer.json
  -- Parse configuration
  -- Return results
end

return M
```

### Docker Integration

```lua
-- lua/devcontainers/docker.lua
local M = {}

function M.build_container()
  -- Docker build logic
end

function M.start_container()
  -- Docker run logic
end

return M
```

## Contributing Process

1. **Fork** the repository
2. **Create** a feature branch
3. **Add** your functionality with tests
4. **Update** documentation
5. **Submit** a pull request

## Questions?

This is a template project. Feel free to:
- Fork and extend it
- Use it as a starting point for your own plugins
- Submit improvements to the template itself

Thank you for using devcontainers.nvim template!