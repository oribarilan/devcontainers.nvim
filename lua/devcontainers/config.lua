local M = {}

-- Default configuration
M.defaults = {
  -- Enable debug logging
  debug = false,
  
  -- Log level for debug output
  log_level = "INFO",
  
  -- Plugin enabled state
  enabled = true,
}

-- Validate configuration
function M.validate(config)
  if type(config) ~= "table" then
    return false, "Configuration must be a table"
  end
  
  -- Basic validation
  if config.debug ~= nil and type(config.debug) ~= "boolean" then
    return false, "debug must be a boolean"
  end
  
  if config.enabled ~= nil and type(config.enabled) ~= "boolean" then
    return false, "enabled must be a boolean"
  end
  
  return true, nil
end

-- Merge configurations
function M.merge(user_config, default_config)
  return vim.tbl_deep_extend("force", default_config or M.defaults, user_config or {})
end

return M