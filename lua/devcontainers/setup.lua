local M = {}

local debug = require("devcontainers.debug")

-- Setup state
local setup_state = {
  initialized = false,
  augroup = nil,
}

-- Initialize the plugin setup
function M.init(user_config)
  if setup_state.initialized then
    debug.log("Setup already initialized, skipping...")
    return
  end

  debug.log("Initializing devcontainers.nvim setup...")

  -- Create autocommand group
  setup_state.augroup = vim.api.nvim_create_augroup("DevcontainersNvim", { clear = true })

  -- Setup basic autocommands
  M.setup_autocommands(user_config)
  
  -- Setup commands
  M.setup_commands(user_config)
  
  -- Initialize statusline system
  M.setup_statusline()

  setup_state.initialized = true
  debug.log("Setup initialization complete")
end

-- Setup basic autocommands
function M.setup_autocommands(user_config)
  debug.log("Setting up autocommands...")

  -- Example autocommand - can be extended later
  vim.api.nvim_create_autocmd("VimEnter", {
    group = setup_state.augroup,
    callback = function()
      debug.log("Plugin loaded successfully")
    end,
  })

  -- Clean up on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = setup_state.augroup,
    callback = function()
      debug.log("Plugin cleanup on exit")
      -- cleanup statusline system
      local statusline = require("devcontainers.statusline")
      statusline.cleanup_all()
    end,
  })
end

-- Setup commands
function M.setup_commands(user_config)
  debug.log("Setting up commands...")
  
  local commands = require("devcontainers.commands")
  commands.setup()
end

-- Setup statusline system
function M.setup_statusline()
  debug.log("Setting up statusline system...")
  
  local statusline = require("devcontainers.statusline")
  statusline.init()
  
  debug.log("Statusline system setup complete")
end

-- Cleanup setup
function M.cleanup()
  if setup_state.augroup then
    vim.api.nvim_del_augroup_by_id(setup_state.augroup)
    setup_state.augroup = nil
  end
  
  -- cleanup commands
  local commands = require("devcontainers.commands")
  commands.cleanup()
  
  -- cleanup statusline system
  local statusline = require("devcontainers.statusline")
  statusline.cleanup_all()
  
  setup_state.initialized = false
  debug.log("Setup cleanup complete")
end

return M