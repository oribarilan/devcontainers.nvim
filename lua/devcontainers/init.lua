local M = {}

-- Plugin version
M.version = "0.1.0"

-- Plugin state
local state = {
  initialized = false,
  config = {},
}

-- Initialize the plugin
function M.setup(user_config)
  if state.initialized then
    return
  end

  -- Merge user config with defaults
  local config = require("devcontainers.config")
  state.config = config.merge(user_config, config.defaults)
  
  -- Initialize debug system
  require("devcontainers.debug").setup(state.config)
  
  -- Initialize plugin components
  require("devcontainers.setup").init(state.config)
  
  state.initialized = true
end

-- Get current configuration
function M.get_config()
  return vim.deepcopy(state.config)
end

-- Check if plugin is initialized
function M.is_initialized()
  return state.initialized
end

return M