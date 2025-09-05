-- example usage of devcontainers.nvim

-- minimal setup - auto-detects nvim config location
require("devcontainers").setup({})

-- with optional debug logging
require("devcontainers").setup({
  debug = true,
  log_level = "INFO",
})

-- with custom nvim configuration path (overrides auto-detection)
require("devcontainers").setup({
  debug = true,
  log_level = "INFO",
  
  -- nvim configuration (optional - auto-detected if not provided)
  nvim = {
    -- custom path to your host neovim config (optional - auto-detected if nil)
    host_config = "/custom/path/to/nvim",
    
    -- path inside container where config will be mounted (optional)
    container_config = "$HOME/.config/nvim",
    
    -- mount as readonly to protect host config (optional, default: true)
    readonly = true,
    
    -- XDG directories inside container (optional)
    xdg = {
      data  = "$HOME/.local/share/nvim",
      state = "$HOME/.local/state/nvim",
      cache = "$HOME/.cache/nvim",
    },
  },
})

-- after setup, these commands will be available:

-- :DevcontainerUp
-- 1. check if devcontainer CLI is installed
-- 2. if not available: show error "devcontainer CLI not found. Install with npm i -g @devcontainers/cli"
-- 3. if available: execute "devcontainer up" with:
--    - auto-detected config mount: host_config -> container_config
--    - show progress in a small terminal window (15 lines)

-- :DevcontainerEnter
-- 1. check if devcontainer CLI is installed
-- 2. if not available: show error message
-- 3. detect host nvim version using "nvim --version"
-- 4. execute "devcontainer exec" with:
--    - "bob install <detected-version>"
--    - "bob use <detected-version>"
--    - open container in new nvim terminal (not detached)

-- :DevcontainerRebuild
-- 1. check if devcontainer CLI is installed
-- 2. if not available: show error message
-- 3. execute "devcontainer up" with rebuild flags:
--    - --remove-existing-container (removes old container)
--    - --build-no-cache (rebuilds image without cache)
--    - completely rebuilds container and image from scratch
--    - runs postCreateCommand again
--    - show progress in a small terminal window (15 lines)
--    - useful when devcontainer.json or Dockerfile changes