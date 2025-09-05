local M = {}

local debug = require("devcontainers.debug")
local dc_cli = require("devcontainers.dc_cli")

-- command definitions
local commands = {}

-- DevcontainerUp command
commands.DevcontainerUp = {
  name = "DevcontainerUp",
  desc = "Spins up containers with devcontainer.json settings applied",
  handler = function()
    debug.info("executing DevcontainerUp command")
    dc_cli.devcontainer_up()
  end,
}

-- DevcontainerEnter command
commands.DevcontainerEnter = {
  name = "DevcontainerEnter",
  desc = "enter devcontainer with nvim",
  handler = function()
    debug.info("executing DevcontainerEnter command")
    dc_cli.devcontainer_enter()
  end,
}

-- register all commands
function M.setup()
  debug.debug("setting up devcontainer commands")
  
  for _, cmd in pairs(commands) do
    vim.api.nvim_create_user_command(
      cmd.name,
      cmd.handler,
      {
        desc = cmd.desc,
        force = true,
      }
    )
    debug.debug("registered command: " .. cmd.name)
  end
  
  debug.info("devcontainer commands registered successfully")
end

-- cleanup commands
function M.cleanup()
  debug.debug("cleaning up devcontainer commands")
  
  for _, cmd in pairs(commands) do
    pcall(vim.api.nvim_del_user_command, cmd.name)
    debug.debug("removed command: " .. cmd.name)
  end
  
  debug.info("devcontainer commands cleanup complete")
end

-- get list of available commands
function M.get_commands()
  local cmd_list = {}
  for _, cmd in pairs(commands) do
    table.insert(cmd_list, {
      name = cmd.name,
      desc = cmd.desc,
    })
  end
  return cmd_list
end

return M