local M = {}

-- Default configuration
M.defaults = {
  -- Enable debug logging
  debug = false,
  
  -- Log level for debug output
  log_level = "INFO",
  
  -- Plugin enabled state
  enabled = true,

  -- Path to host neovim config (optional - if nil, auto-detected)
  host_config = nil,
  
  -- Path inside container where config will be mounted
  container_config = "$HOME/.config/nvim",
  
  -- Path to host devcontainers.nvim plugin for development (optional)
  -- When set, this path will be mounted to the same path inside the container
  -- Example: "~/repos/personal/devcontainers.nvim"
  dev_path = nil,
}

-- Validate configuration
function M.validate(config)
  if type(config) ~= "table" then
    return false, "configuration must be a table"
  end
  
  -- Basic validation
  if config.debug ~= nil and type(config.debug) ~= "boolean" then
    return false, "debug must be a boolean"
  end
  
  if config.enabled ~= nil and type(config.enabled) ~= "boolean" then
    return false, "enabled must be a boolean"
  end

  -- host_config is optional - only validate if provided
  if config.host_config ~= nil then
    if type(config.host_config) ~= "string" or config.host_config == "" then
      return false, "host_config must be a non-empty string"
    end

    -- Validate host_config path exists
    local utils = require("devcontainers.utils")
    if not utils.dir_exists(config.host_config) then
      return false, "host_config path does not exist: " .. config.host_config
    end
  end

  -- Validate optional fields
  if config.container_config ~= nil and type(config.container_config) ~= "string" then
    return false, "container_config must be a string"
  end

  -- dev_path is optional - only validate if provided
  if config.dev_path ~= nil then
    if type(config.dev_path) ~= "string" or config.dev_path == "" then
      return false, "dev_path must be a non-empty string"
    end

    -- Validate dev_path exists
    local utils = require("devcontainers.utils")
    local expanded_path = utils.expand_path(config.dev_path)
    if not utils.dir_exists(expanded_path) then
      return false, "dev_path does not exist: " .. expanded_path
    end
  end
  
  return true, nil
end

-- Merge configurations
function M.merge(user_config, default_config)
  local merged = vim.tbl_deep_extend("force", default_config or M.defaults, user_config or {})
  
  -- Auto-detect default nvim config path if not provided
  if merged.host_config == nil then
    local utils = require("devcontainers.utils")
    local default_path, err = utils.get_default_nvim_config_path()
    
    if default_path and utils.dir_exists(default_path) then
      merged.host_config = default_path
      require("devcontainers.debug").info("auto-detected nvim config path: " .. default_path)
    else
      require("devcontainers.debug").debug("default nvim config path not found or doesn't exist: " .. (default_path or "nil") .. " (" .. (err or "unknown error") .. ")")
    end
  end
  
  return merged
end

return M