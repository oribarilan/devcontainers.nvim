local M = {}

-- Default configuration
M.defaults = {
  -- Enable debug logging
  debug = false,
  
  -- Log level for debug output
  log_level = "INFO",
  
  -- Plugin enabled state
  enabled = true,

  -- Neovim configuration settings (optional)
  nvim = {
    -- Path to host neovim config (optional - if nil, auto-detected)
    host_config = nil,
    
    -- Path inside container where config will be mounted
    container_config = "$HOME/.config/nvim",
    
    -- Mount config as readonly (note: devcontainer CLI doesn't support readonly flag)
    readonly = true,
    
    -- XDG directory paths inside container
    xdg = {
      data  = "$HOME/.local/share/nvim",
      state = "$HOME/.local/state/nvim",
      cache = "$HOME/.cache/nvim",
    },
  },
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

  -- Validate nvim configuration if provided
  if config.nvim ~= nil then
    local valid, err = M.validate_nvim_config(config.nvim)
    if not valid then
      return false, "nvim config error: " .. err
    end
  end
  
  return true, nil
end

-- Validate nvim-specific configuration
function M.validate_nvim_config(nvim_config)
  if type(nvim_config) ~= "table" then
    return false, "nvim config must be a table"
  end

  -- host_config is optional - only validate if provided
  if nvim_config.host_config ~= nil then
    if type(nvim_config.host_config) ~= "string" or nvim_config.host_config == "" then
      return false, "nvim.host_config must be a non-empty string"
    end

    -- Validate host_config path exists
    local utils = require("devcontainers.utils")
    if not utils.dir_exists(nvim_config.host_config) then
      return false, "nvim.host_config path does not exist: " .. nvim_config.host_config
    end
  end

  -- Validate optional fields
  if nvim_config.container_config ~= nil and type(nvim_config.container_config) ~= "string" then
    return false, "nvim.container_config must be a string"
  end

  if nvim_config.readonly ~= nil and type(nvim_config.readonly) ~= "boolean" then
    return false, "nvim.readonly must be a boolean"
  end

  if nvim_config.xdg ~= nil then
    if type(nvim_config.xdg) ~= "table" then
      return false, "nvim.xdg must be a table"
    end

    for key, path in pairs(nvim_config.xdg) do
      if not vim.tbl_contains({"data", "state", "cache"}, key) then
        return false, "nvim.xdg." .. key .. " is not a valid XDG directory (must be data, state, or cache)"
      end
      
      if type(path) ~= "string" or path == "" then
        return false, "nvim.xdg." .. key .. " must be a non-empty string"
      end
    end
  end

  return true, nil
end

-- Merge configurations
function M.merge(user_config, default_config)
  local merged = vim.tbl_deep_extend("force", default_config or M.defaults, user_config or {})
  
  -- Auto-detect default nvim config path if not provided
  if merged.nvim and merged.nvim.host_config == nil then
    local utils = require("devcontainers.utils")
    local default_path, err = utils.get_default_nvim_config_path()
    
    if default_path and utils.dir_exists(default_path) then
      merged.nvim.host_config = default_path
      require("devcontainers.debug").info("auto-detected nvim config path: " .. default_path)
    else
      require("devcontainers.debug").debug("default nvim config path not found or doesn't exist: " .. (default_path or "nil") .. " (" .. (err or "unknown error") .. ")")
    end
  end
  
  return merged
end

return M