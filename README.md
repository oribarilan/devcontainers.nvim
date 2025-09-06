# devcontainers.nvim

A Neovim plugin for seamless development container integration. This plugin manages your Neovim configuration inside Dev Containers using **bob** for version management and **readonly mounts** for your host configuration.

## Features

- **Automatic config mounting**: Your host Neovim config is mounted readonly into containers
- **Version synchronization**: Uses bob to automatically install your host Neovim version in containers
- **XDG directory management**: Container-local data/state/cache for optimal performance
- **Config mounting**: Live mounts your host configuration into containers
- **Terminal integration**: Opens containers in new Neovim terminals for seamless workflow

## Requirements

- [devcontainer CLI](https://github.com/devcontainers/cli) - Install with `npm i -g @devcontainers/cli`
- A `.devcontainer/devcontainer.json` file in your project

### macOS Docker Desktop Users

If you use symlinked dotfiles or your Neovim config is outside of `/Users`, you need to ensure Docker can access the resolved paths:

1. Open Docker Desktop → Settings → Resources → File Sharing
2. Add the actual path where your Neovim config is located (not just the symlink)
3. For example: if `~/.config/nvim` symlinks to `~/.config/dotfiles/nvim`, add `~/.config/dotfiles` to file sharing

Without this, you'll see "bind source path does not exist" errors when mounting your config.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/devcontainers.nvim",
  config = function()
    -- minimal setup - no configuration required
    require("devcontainers").setup({})
  end,
}
```

## Configuration

All configuration is optional. The plugin works out of the box with sensible defaults:

### Default Configuration

```lua
require("devcontainers").setup({
  -- Enable debug logging (default: false)
  -- Options: true, false
  debug = false,
  
  -- Log level for debug output (default: "INFO")
  -- Options: "ERROR", "WARN", "INFO", "DEBUG", "TRACE"
  log_level = "INFO",
  
  -- Plugin enabled state (default: true)
  -- Options: true, false
  enabled = true,
  
  -- Path to host neovim config (default: nil - auto-detected)
  -- Options: nil (auto-detect), "/path/to/config"
  -- Auto-detection finds: ~/.config/nvim (Linux/macOS), %LOCALAPPDATA%\nvim (Windows)
  host_config = nil,
  
  -- Path inside container where config will be mounted (default: "$HOME/.config/nvim")
  -- Options: any valid container path, supports $HOME and ${containerEnv:HOME}
  container_config = "$HOME/.config/nvim",
  
  -- Path to host devcontainers.nvim plugin for development (default: nil)
  -- Options: nil (disabled), "~/path/to/plugin"
  -- When set, mounts plugin to same path inside container for lazy.nvim compatibility
  dev_path = nil,
  
  -- Control how DevcontainerEnter behaves (default: "external")
  -- Options: "external" (opens WezTerm with nvim), "nested" (opens nvim in vim terminal)
  enter_mode = "external",
})
```

### Configuration Examples

```lua
-- Minimal setup (recommended)
require("devcontainers").setup({})

-- Debug mode
require("devcontainers").setup({
  debug = true,
  log_level = "DEBUG",
})

-- Custom config path
require("devcontainers").setup({
  host_config = "/custom/path/to/nvim/config",
  container_config = "$HOME/.config/custom-nvim",
})

-- Plugin development
require("devcontainers").setup({
  debug = true,
  dev_path = "~/repos/personal/devcontainers.nvim",
})

-- Use nested terminal instead of external WezTerm
require("devcontainers").setup({
  enter_mode = "nested",
})
```

## Development Configuration

If you're developing this plugin locally, you can use the `dev_path` configuration to mount your local plugin directory into the container:

```lua
require("devcontainers").setup({
  dev_path = "~/repos/personal/devcontainers.nvim",
})
```

This solves the issue where lazy.nvim expects the plugin at a specific path (like `~/repos/personal/devcontainers.nvim`) but that path doesn't exist inside the container. The `dev_path` mounts your local plugin directory to the same path inside the container, making lazy.nvim work seamlessly.

## Automatic Config Detection

The plugin automatically detects your nvim config location based on your OS:

- **macOS/Linux**: `~/.config/nvim` (respects `$XDG_CONFIG_HOME` on Linux)
- **Windows**: `%LOCALAPPDATA%\nvim`

Only existing config directories are mounted. If no config is found, the plugin works as a basic devcontainer wrapper.

## Usage

### Commands

- **`:DevcontainerUp`** - Starts the devcontainer with your config mounted readonly
- **`:DevcontainerEnter`** - Enters the container, installs your Neovim version with bob, and opens nvim
  - `enter_mode = "external"`: Opens WezTerm with nvim in container (default)
  - `enter_mode = "nested"`: Opens nvim in vim terminal buffer (legacy)
- **`:DevcontainerShell`** - Opens a shell terminal inside the devcontainer
- **`:DevcontainerRebuild`** - Fully rebuilds the container from scratch, including running postCreateCommand

### Typical Workflow

1. Configure the plugin with your host config path
2. Run `:DevcontainerUp` to start the container with proper mounts
3. Run `:DevcontainerEnter` to enter with synchronized Neovim setup
4. Your host config is live-mounted and ready to use
5. Plugins/cache stay in container volumes for performance
6. Use `:DevcontainerRebuild` when you change devcontainer.json or Dockerfile

## How It Works

- **Config mounting**: Your host config is mounted readonly at container startup
- **Version detection**: Plugin detects your host Neovim version using `nvim --version`
- **Bob integration**: Automatically runs `bob install <version> && bob use <version>` in container
- **XDG separation**: Data/state/cache directories use container volumes for performance
- **Terminal integration**: Opens container in new Neovim terminal instead of detached mode

## devcontainer.json Setup

Your `.devcontainer/devcontainer.json` should include XDG volume mounts:

```json
{
  "name": "My Dev Environment",
  "image": "your-image",
  "mounts": [
    "type=volume,source=nvim-data,target=${containerEnv:HOME}/.local/share/nvim",
    "type=volume,source=nvim-state,target=${containerEnv:HOME}/.local/state/nvim",
    "type=volume,source=nvim-cache,target=${containerEnv:HOME}/.cache/nvim"
  ],
  "postCreateCommand": "curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/install | bash"
}
```

## License

MIT License - see [LICENSE](LICENSE) file for details.