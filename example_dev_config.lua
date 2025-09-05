-- Example configuration for devcontainers.nvim plugin development
-- Place this in your nvim config where you set up the plugin

require("devcontainers").setup({
  -- Enable debug logging to see mount operations
  debug = true,
  log_level = "INFO",
  
  -- Your nvim config will be auto-detected, but you can override:
  -- host_config = "~/.config/nvim",
  container_config = "$HOME/.config/nvim",
  
  -- Set this to your local devcontainers.nvim plugin path for development
  -- This will mount the plugin to the same path inside the container
  -- so your lazy.nvim `dir = "~/repos/personal/devcontainers.nvim"` works
  dev_path = "~/repos/personal/devcontainers.nvim",
})