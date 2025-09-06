# Statusline Integration

The devcontainers.nvim plugin provides automatic statusline management for nested devcontainer sessions.

## Overview

When using `enter_mode = "nested"`, the plugin opens nvim inside a terminal buffer within your outer Neovim instance. This results in two statuslines being visible - one from the outer Neovim and one from the inner (nested) Neovim.

To improve the user experience, the plugin automatically customizes the outer Neovim's statusline to show "Devcontainer Mode" when a nested session is active.

## How It Works

1. **On nested mode entry**: The terminal buffer's window gets a custom statusline showing " Devcontainer Mode "
2. **During nested session**: The custom statusline remains visible in the outer Neovim
3. **On nested mode exit**: The original statusline is automatically restored when the terminal closes

## Technical Details

- **Window-local**: The statusline change only affects the terminal window, not your global statusline
- **Automatic cleanup**: Uses `TermClose` autocmds to restore the original statusline when the nested session ends
- **Multiple session support**: Each devcontainer terminal is tracked independently
- **Non-intrusive**: Works with any statusline plugin or configuration

## Configuration

The statusline integration is enabled automatically when using nested mode. No additional configuration is required.

```lua
require("devcontainers").setup({
  enter_mode = "nested", -- enables automatic statusline management
})
```

## Troubleshooting

If you experience issues with statusline restoration:

1. Check that your statusline plugin doesn't conflict with window-local statuslines
2. Ensure you're properly exiting the nested nvim (`:qa` instead of force-killing)
3. Enable debug logging to see statusline management events:

```lua
require("devcontainers").setup({
  debug = true,
  log_level = "DEBUG",
})
```

## API Reference

The statusline functionality is provided by the `devcontainers.statusline` module:

- `statusline.init()` - Initialize the statusline system
- `statusline.setup_devcontainer_statusline(bufnr)` - Set custom statusline for a buffer
- `statusline.cleanup_devcontainer_statusline(bufnr)` - Restore original statusline
- `statusline.cleanup_all()` - Clean up all tracked statuslines
- `statusline.get_state()` - Get current tracking state (for debugging)