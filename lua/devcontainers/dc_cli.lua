local M = {}

local debug = require("devcontainers.debug")

-- cli state
local cli_state = {
  available = nil,
  version = nil,
  checked = false,
}

-- check if devcontainer cli is available
function M.check_availability()
  if cli_state.checked then
    return cli_state.available, cli_state.version
  end
  
  debug.debug("checking devcontainer cli availability")
  
  -- run devcontainer --version command
  local handle = io.popen("devcontainer --version 2>/dev/null")
  if not handle then
    debug.error("failed to execute devcontainer command")
    cli_state.available = false
    cli_state.checked = true
    return false, nil
  end
  
  local result = handle:read("*a")
  local success = handle:close()
  
  if success and result and result:match("%d+%.%d+%.%d+") then
    cli_state.version = result:match("(%d+%.%d+%.%d+)")
    cli_state.available = true
    debug.info("devcontainer cli found, version: " .. cli_state.version)
  else
    cli_state.available = false
    debug.warn("devcontainer cli not found or invalid response")
  end
  
  cli_state.checked = true
  return cli_state.available, cli_state.version
end

-- ensure devcontainer cli is available, show error if not
function M.ensure_available()
  local available, version = M.check_availability()
  
  if not available then
    local error_msg = "devcontainer CLI not found. Install with npm i -g @devcontainers/cli"
    debug.error(error_msg)
    vim.notify(error_msg, vim.log.levels.ERROR)
    return false
  end
  
  debug.debug("devcontainer cli is available, version: " .. (version or "unknown"))
  return true
end

-- get cli version if available
function M.get_version()
  local available, version = M.check_availability()
  return available and version or nil
end

-- reset cached state (useful for testing)
function M.reset_cache()
  cli_state.available = nil
  cli_state.version = nil
  cli_state.checked = false
  debug.debug("devcontainer cli cache reset")
end

-- run a devcontainer command
function M.run_command(args, opts)
  if not M.ensure_available() then
    return false, "devcontainer CLI not available"
  end
  
  opts = opts or {}
  local cmd = "devcontainer " .. (args or "")
  
  debug.debug("running devcontainer command: " .. cmd)
  
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    local error_msg = "failed to execute devcontainer command: " .. cmd
    debug.error(error_msg)
    return false, error_msg
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  if success then
    debug.debug("devcontainer command succeeded")
    return true, output
  else
    debug.error("devcontainer command failed: " .. (output or "unknown error"))
    return false, output
  end
end

-- generate mount arguments for nvim config
function M.generate_mount_args(config)
  local args = {}
  
  if not config or not config.nvim or not config.nvim.host_config then
    debug.debug("no nvim.host_config provided, skipping config mount generation")
    return args
  end
  
  -- Check if host config directory actually exists before attempting mount
  local utils = require("devcontainers.utils")
  if not utils.dir_exists(config.nvim.host_config) then
    debug.warn("nvim host_config directory does not exist: " .. config.nvim.host_config .. ", skipping mount")
    return args
  end
  
  local utils = require("devcontainers.utils")
  local nvim_config = config.nvim
  
  -- expand and resolve symlinks for host path
  local host_path = utils.expand_path(nvim_config.host_config)
  host_path = utils.resolve_symlink(host_path)
  
  -- verify the resolved path exists
  if not utils.dir_exists(host_path) then
    debug.warn("resolved nvim config path does not exist: " .. host_path)
    debug.warn("skipping nvim config mount")
    return args
  end
  
  -- Docker requires absolute paths - use common devcontainer paths
  local container_path = nvim_config.container_config
  if container_path:match("^%$HOME") then
    -- Replace $HOME with /home/vscode (default devcontainer user home)
    container_path = container_path:gsub("^%$HOME", "/home/vscode")
  elseif container_path:match("^%${containerEnv:HOME}") then
    -- Handle ${containerEnv:HOME} format
    container_path = container_path:gsub("^%${containerEnv:HOME}", "/home/vscode")
  end
  
  debug.info("generating mount for nvim config:")
  debug.info("  host: " .. host_path)
  debug.info("  container: " .. container_path)
  
  -- build mount string according to devcontainer CLI format
  -- Format: type=<bind|volume>,source=<source>,target=<target>[,external=<true|false>]
  local mount_options = "type=bind,source=" .. host_path .. ",target=" .. container_path
  
  debug.info("mount string: " .. mount_options)
  
  table.insert(args, "--mount")
  table.insert(args, mount_options)
  
  debug.debug("generated mount arg: " .. mount_options)
  
  return args
end

-- run devcontainer up command
function M.devcontainer_up(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  debug.info("starting devcontainer up for workspace: " .. workspace_folder)
  
  -- build command arguments
  local cmd_args = { "devcontainer", "up", "--workspace-folder", workspace_folder }
  
  -- add dynamic mounts if config is provided
  if config then
    local mount_args = M.generate_mount_args(config)
    for _, arg in ipairs(mount_args) do
      table.insert(cmd_args, arg)
    end
  end
  
  debug.info("executing command: " .. table.concat(cmd_args, " "))
  
  -- open in terminal instead of notifications for better UX
  vim.cmd("split")
  vim.cmd("resize 15")
  vim.cmd("terminal " .. table.concat(cmd_args, " "))
  
  return true
end

-- run devcontainer exec command to enter the container with nvim
function M.devcontainer_enter(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  debug.info("entering devcontainer with nvim for workspace: " .. workspace_folder)
  
  -- detect host nvim version for bob
  local utils = require("devcontainers.utils")
  local host_version, version_err = utils.get_nvim_version()
  
  if not host_version then
    debug.warn("could not detect host nvim version: " .. (version_err or "unknown error"))
    vim.notify("warning: could not detect host nvim version: " .. (version_err or "unknown error"), vim.log.levels.WARN)
  else
    debug.info("detected host nvim version: " .. host_version)
  end
  
  -- build the command to run inside container
  local container_cmd = {}
  
  if host_version then
    -- install and use the detected version with bob
    table.insert(container_cmd, "bob install " .. host_version)
    table.insert(container_cmd, "bob use " .. host_version)
  end
  
  -- add nvim command
  table.insert(container_cmd, "nvim")
  
  -- join commands with &&
  local full_cmd = table.concat(container_cmd, " && ")
  
  debug.info("container command: " .. full_cmd)
  
  -- open in new terminal instead of detached
  vim.cmd("terminal devcontainer exec --workspace-folder " .. workspace_folder .. " bash -c '" .. full_cmd .. "'")
  
  return true
end

-- run devcontainer up with rebuild flags to fully rebuild the container
function M.devcontainer_rebuild(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  debug.info("rebuilding devcontainer for workspace: " .. workspace_folder)
  
  -- build command arguments with rebuild flags
  local cmd_args = {
    "devcontainer", "up",
    "--remove-existing-container",  -- removes existing container
    "--build-no-cache",             -- rebuilds image without cache
    "--workspace-folder", workspace_folder
  }
  
  -- add dynamic mounts if config is provided
  if config then
    local mount_args = M.generate_mount_args(config)
    for _, arg in ipairs(mount_args) do
      table.insert(cmd_args, arg)
    end
  end
  
  debug.info("executing rebuild command: " .. table.concat(cmd_args, " "))
  
  -- open in terminal instead of notifications for better UX
  vim.cmd("split")
  vim.cmd("resize 15")
  vim.cmd("terminal " .. table.concat(cmd_args, " "))
  
  return true
end

return M