local M = {}

local debug = require("devcontainers.debug")

-- statusline state tracking
local statusline_state = {
  terminal_buffers = {}, -- { bufnr = { original_statusline = "...", autocmd_id = 123 } }
  augroup = nil,        -- autocmd group for cleanup
}

-- initialize the statusline system
function M.init()
  if statusline_state.augroup then
    debug.debug("statusline system already initialized")
    return
  end
  
  -- create autocmd group for statusline management
  statusline_state.augroup = vim.api.nvim_create_augroup("DevcontainersStatusline", { clear = true })
  
  -- setup optional plugin integrations
  local statusline_plugins = require("devcontainers.statusline_plugins")
  statusline_plugins.setup_available_integrations()
  
  debug.debug("statusline system initialized")
end

-- setup custom statusline for a devcontainer terminal buffer
function M.setup_devcontainer_statusline(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    debug.warn("invalid buffer number for statusline setup: " .. bufnr)
    return false
  end
  
  -- check if buffer is already being tracked
  if statusline_state.terminal_buffers[bufnr] then
    debug.debug("buffer " .. bufnr .. " statusline already managed")
    return true
  end
  
  debug.info("setting up devcontainer statusline for buffer: " .. bufnr)
  
  -- get current window for this buffer
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    debug.warn("buffer " .. bufnr .. " not displayed in any window")
    return false
  end
  
  debug.info("setting up statusline for buffer " .. bufnr .. " in window " .. winid)
  
  -- get current statusline (may be empty)
  local original_statusline = vim.api.nvim_get_option_value("statusline", { win = winid })
  debug.debug("original statusline: '" .. original_statusline .. "'")
  
  -- check if we have a global statusline that might override window-local ones
  local global_statusline = vim.api.nvim_get_option_value("statusline", { scope = "global" })
  debug.debug("global statusline: '" .. global_statusline .. "'")
  
  -- determine if we need to override global statusline
  local needs_global_override = (global_statusline ~= "" and original_statusline == "")
  local original_global_statusline = needs_global_override and global_statusline or nil
  
  -- set buffer variables for statusline plugins to read
  vim.b[bufnr].devcontainer_mode = true
  vim.b[bufnr].devcontainer_statusline = " Devcontainer Mode "
  
  -- set appropriate statusline based on context
  if needs_global_override then
    debug.info("overriding global statusline because window-local is empty")
    vim.api.nvim_set_option_value("statusline", " Devcontainer Mode ", { scope = "global" })
  else
    -- set window-local statusline directly for simplicity and predictability
    vim.api.nvim_set_option_value("statusline", " Devcontainer Mode ", { win = winid })
  end
  
  debug.info("set custom statusline: ' Devcontainer Mode '")
  
  -- verify the statusline was set
  local new_statusline = vim.api.nvim_get_option_value("statusline", { win = winid })
  debug.debug("verified statusline: '" .. new_statusline .. "'")
  
  -- create buffer-specific autocmd for cleanup when terminal closes
  local autocmd_id = vim.api.nvim_create_autocmd("TermClose", {
    group = statusline_state.augroup,
    buffer = bufnr,
    callback = function()
      debug.debug("terminal closed, cleaning up statusline for buffer: " .. bufnr)
      M.cleanup_devcontainer_statusline(bufnr)
    end,
  })
  
  -- track this buffer
  statusline_state.terminal_buffers[bufnr] = {
    original_statusline = original_statusline,
    original_global_statusline = original_global_statusline,
    needs_global_override = needs_global_override,
    autocmd_id = autocmd_id,
  }
  
  debug.info("devcontainer statusline setup complete for buffer: " .. bufnr)
  return true
end

-- cleanup custom statusline for a devcontainer terminal buffer
function M.cleanup_devcontainer_statusline(bufnr)
  local buffer_state = statusline_state.terminal_buffers[bufnr]
  if not buffer_state then
    debug.debug("buffer " .. bufnr .. " not tracked for statusline cleanup")
    return
  end
  
  debug.info("cleaning up devcontainer statusline for buffer: " .. bufnr)
  
  -- restore original statusline if buffer still exists and is displayed
  if vim.api.nvim_buf_is_valid(bufnr) then
    -- clean up buffer variables
    vim.b[bufnr].devcontainer_mode = nil
    vim.b[bufnr].devcontainer_statusline = nil
    
    if buffer_state.needs_global_override and buffer_state.original_global_statusline then
      -- restore global statusline
      vim.api.nvim_set_option_value("statusline", buffer_state.original_global_statusline, { scope = "global" })
      debug.debug("restored original global statusline for buffer: " .. bufnr)
    else
      -- restore window-local statusline
      local winid = vim.fn.bufwinid(bufnr)
      if winid ~= -1 then
        vim.api.nvim_set_option_value("statusline", buffer_state.original_statusline, { win = winid })
        debug.debug("restored original window-local statusline for buffer: " .. bufnr)
      end
    end
  end
  
  -- remove autocmd if it exists
  if buffer_state.autocmd_id then
    pcall(vim.api.nvim_del_autocmd, buffer_state.autocmd_id)
  end
  
  -- remove from tracking
  statusline_state.terminal_buffers[bufnr] = nil
  debug.info("statusline cleanup complete for buffer: " .. bufnr)
end

-- cleanup all tracked devcontainer terminal statuslines
function M.cleanup_all()
  debug.debug("cleaning up all devcontainer statuslines")
  
  -- cleanup all tracked buffers
  for bufnr, _ in pairs(statusline_state.terminal_buffers) do
    M.cleanup_devcontainer_statusline(bufnr)
  end
  
  -- cleanup autocmd group
  if statusline_state.augroup then
    vim.api.nvim_del_augroup_by_id(statusline_state.augroup)
    statusline_state.augroup = nil
  end
  
  debug.info("all devcontainer statuslines cleaned up")
end

-- get current tracking state (for debugging/testing)
function M.get_state()
  return {
    terminal_buffers = vim.deepcopy(statusline_state.terminal_buffers),
    augroup = statusline_state.augroup,
  }
end

return M