local M = {}

-- Debug state
local debug_state = {
  enabled = false,
  log_file = nil,
  log_level = "INFO",
}

-- Log levels
local LOG_LEVELS = {
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  DEBUG = 4,
  TRACE = 5,
}

-- Initialize debug system
function M.setup(config)
  debug_state.enabled = config and config.debug or false
  debug_state.log_level = config and config.log_level or "INFO"
  
  if debug_state.enabled then
    -- Create log file path
    local log_dir = vim.fn.stdpath("cache") .. "/devcontainers"
    vim.fn.mkdir(log_dir, "p")
    debug_state.log_file = log_dir .. "/debug.log"
    
    M.log("Debug logging enabled", "INFO")
    M.log("Log file: " .. debug_state.log_file, "INFO")
  end
end

-- Check if debug is enabled
function M.is_enabled()
  return debug_state.enabled
end

-- Log a message
function M.log(message, level)
  level = level or "INFO"
  
  if not debug_state.enabled then
    return
  end
  
  -- Check log level
  local current_level = LOG_LEVELS[debug_state.log_level] or LOG_LEVELS.INFO
  local msg_level = LOG_LEVELS[level] or LOG_LEVELS.INFO
  
  if msg_level > current_level then
    return
  end
  
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_entry = string.format("[%s] [%s] %s", timestamp, level, message)
  
  -- Print to console in development
  if vim.env.NVIM_DEV then
    print("devcontainers.nvim: " .. log_entry)
  end
  
  -- Write to log file
  if debug_state.log_file then
    local file = io.open(debug_state.log_file, "a")
    if file then
      file:write(log_entry .. "\n")
      file:close()
    end
  end
end

-- Log error
function M.error(message)
  M.log(message, "ERROR")
end

-- Log warning
function M.warn(message)
  M.log(message, "WARN")
end

-- Log info
function M.info(message)
  M.log(message, "INFO")
end

-- Log debug
function M.debug(message)
  M.log(message, "DEBUG")
end

-- Log trace
function M.trace(message)
  M.log(message, "TRACE")
end

-- Log function entry/exit
function M.trace_function(func_name, func)
  return function(...)
    M.trace("Entering function: " .. func_name)
    local results = { func(...) }
    M.trace("Exiting function: " .. func_name)
    return unpack(results)
  end
end

-- Log table contents
function M.log_table(table_data, name, level)
  level = level or "DEBUG"
  name = name or "table"
  
  if not debug_state.enabled then
    return
  end
  
  local function serialize_table(tbl, indent)
    indent = indent or 0
    local lines = {}
    local prefix = string.rep("  ", indent)
    
    for k, v in pairs(tbl) do
      if type(v) == "table" then
        table.insert(lines, prefix .. tostring(k) .. " = {")
        local sub_lines = serialize_table(v, indent + 1)
        for _, line in ipairs(sub_lines) do
          table.insert(lines, line)
        end
        table.insert(lines, prefix .. "}")
      else
        table.insert(lines, prefix .. tostring(k) .. " = " .. tostring(v))
      end
    end
    
    return lines
  end
  
  M.log(name .. " = {", level)
  local lines = serialize_table(table_data)
  for _, line in ipairs(lines) do
    M.log(line, level)
  end
  M.log("}", level)
end

-- Get log file path
function M.get_log_file()
  return debug_state.log_file
end

-- Clear log file
function M.clear_log()
  if debug_state.log_file then
    local file = io.open(debug_state.log_file, "w")
    if file then
      file:close()
      M.log("Log file cleared", "INFO")
    end
  end
end

-- Show log file in buffer
function M.show_log()
  if not debug_state.log_file then
    vim.notify("Debug logging is not enabled", vim.log.levels.WARN)
    return
  end
  
  if not vim.fn.filereadable(debug_state.log_file) then
    vim.notify("Log file not found: " .. debug_state.log_file, vim.log.levels.WARN)
    return
  end
  
  -- Open log file in a new buffer
  vim.cmd("tabnew " .. debug_state.log_file)
  vim.bo.readonly = true
  vim.bo.filetype = "log"
end

return M