-- example usage of devcontainers.nvim

-- setup the plugin
require("devcontainers").setup({
  debug = true,
  log_level = "INFO"
})

-- after setup, these commands will be available:

-- :DevcontainerUp
-- 1. check if devcontainer CLI is installed
-- 2. if not available: show error "devcontainer CLI not found. Install with npm i -g @devcontainers/cli"
-- 3. if available: execute "devcontainer up --workspace-folder <current-dir>" and show all output
--    - stdout messages shown as INFO notifications with "devcontainer: " prefix
--    - stderr messages shown as WARN notifications with "devcontainer: " prefix
--    - completion status shown when command finishes

-- :DevcontainerEnter
-- 1. check if devcontainer CLI is installed
-- 2. if not available: show error message
-- 3. if available: execute "devcontainer exec --workspace-folder <current-dir> nvim" in detached mode