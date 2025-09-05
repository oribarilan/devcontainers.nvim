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


-- generate mount arguments for nvim config
function M.generate_mount_args(config)
  if not config or not config.nvim or not config.nvim.host_config then
    debug.debug("no nvim.host_config provided, skipping config mount")
    return {}
  end
  
  local utils = require("devcontainers.utils")
  local nvim_config = config.nvim
  
  -- expand and resolve symlinks for host path
  local host_path = utils.expand_path(nvim_config.host_config)
  host_path = utils.resolve_symlink(host_path)
  
  -- verify the resolved path exists
  if not utils.dir_exists(host_path) then
    debug.warn("nvim config path does not exist: " .. host_path .. ", skipping mount")
    return {}
  end
  
  -- resolve container path variables
  local container_path = nvim_config.container_config
    :gsub("^%$HOME", "/home/vscode")
    :gsub("^%${containerEnv:HOME}", "/home/vscode")
  
  debug.info("mounting nvim config: " .. host_path .. " -> " .. container_path)
  
  return { "--mount", "type=bind,source=" .. host_path .. ",target=" .. container_path }
end

-- helper function to execute devcontainer command in terminal
local function execute_in_terminal(cmd_args, action_name)
  debug.info("executing " .. action_name .. ": " .. table.concat(cmd_args, " "))
  
  vim.cmd("split")
  vim.cmd("resize 15")
  vim.cmd("terminal " .. table.concat(cmd_args, " "))
  
  return true
end

-- helper function to build base devcontainer up command
local function build_up_command(workspace_folder, config, rebuild_flags)
  workspace_folder = workspace_folder or vim.loop.cwd()
  
  local cmd_args = { "devcontainer", "up", "--workspace-folder", workspace_folder }
  
  -- add rebuild flags if provided
  if rebuild_flags then
    vim.list_extend(cmd_args, rebuild_flags)
  end
  
  -- add dynamic mounts if config is provided
  if config then
    vim.list_extend(cmd_args, M.generate_mount_args(config))
  end
  
  return cmd_args, workspace_folder
end

-- run devcontainer up command
function M.devcontainer_up(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  local cmd_args, ws_folder = build_up_command(workspace_folder, config)
  debug.info("starting devcontainer up for workspace: " .. ws_folder)
  
  return execute_in_terminal(cmd_args, "devcontainer up")
end

-- run devcontainer up with rebuild flags to fully rebuild the container
function M.devcontainer_rebuild(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  local rebuild_flags = { "--remove-existing-container", "--build-no-cache" }
  local cmd_args, ws_folder = build_up_command(workspace_folder, config, rebuild_flags)
  debug.info("rebuilding devcontainer for workspace: " .. ws_folder)
  
  return execute_in_terminal(cmd_args, "devcontainer rebuild")
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

return M