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


-- generate mount arguments for nvim config and dev paths
function M.generate_mount_args(config)
  local mount_args = {}
  
  -- Handle nvim config mounting
  if config and config.host_config then
    local utils = require("devcontainers.utils")
    
    -- expand and resolve symlinks for host path
    local host_path = utils.expand_path(config.host_config)
    host_path = utils.resolve_symlink(host_path)
    
    -- verify the resolved path exists
    if utils.dir_exists(host_path) then
      -- resolve container path variables
      local container_path = config.container_config
        :gsub("^%$HOME", "/home/vscode")
        :gsub("^%${containerEnv:HOME}", "/home/vscode")
      
      debug.info("mounting nvim config: " .. host_path .. " -> " .. container_path)
      vim.list_extend(mount_args, { "--mount", "type=bind,source=" .. host_path .. ",target=" .. container_path })
    else
      debug.warn("nvim config path does not exist: " .. host_path .. ", skipping mount")
    end
  else
    debug.debug("no host_config provided, skipping config mount")
  end
  
  -- Handle dev path mounting
  if config and config.dev_path then
    local utils = require("devcontainers.utils")
    
    -- expand host path
    local host_dev_path = utils.expand_path(config.dev_path)
    host_dev_path = utils.resolve_symlink(host_dev_path)
    
    -- verify the resolved path exists
    if utils.dir_exists(host_dev_path) then
      -- mount to the same path inside container (maintaining the original path structure)
      -- but ensure we use the expanded path, not the original tilde path
      local container_dev_path = utils.expand_path(config.dev_path):gsub("^/Users/[^/]+", "/home/vscode")
      
      debug.info("mounting dev path: " .. host_dev_path .. " -> " .. container_dev_path)
      vim.list_extend(mount_args, { "--mount", "type=bind,source=" .. host_dev_path .. ",target=" .. container_dev_path })
    else
      debug.warn("dev path does not exist: " .. host_dev_path .. ", skipping mount")
    end
  else
    debug.debug("no dev_path provided, skipping dev mount")
  end
  
  return mount_args
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


-- run devcontainer up and exec command to enter the container with nvim
function M.devcontainer_enter(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  config = config or {}
  local enter_mode = config.enter_mode or "external"
  
  debug.info("starting devcontainer and entering with nvim for workspace: " .. workspace_folder)
  
  -- ensure container is up first with mount args
  local mount_args = ""
  if config then
    local args = M.generate_mount_args(config)
    if #args > 0 then
      mount_args = " " .. table.concat(args, " ")
    end
  end
  
  -- start container with mounts
  local up_cmd = "devcontainer up --workspace-folder " .. workspace_folder .. mount_args
  debug.info("ensuring container is up: " .. up_cmd)
  
  if vim.fn.system(up_cmd) and vim.v.shell_error ~= 0 then
    vim.notify("Failed to start devcontainer", vim.log.levels.ERROR)
    return false
  end
  
  -- detect host nvim version for bob setup
  local utils = require("devcontainers.utils")
  local host_version, version_err = utils.get_nvim_version()
  
  -- build nvim command with bob setup
  local nvim_cmd
  if host_version then
    debug.info("detected host nvim version: " .. host_version)
    -- setup bob and run nvim with the detected version
    nvim_cmd = "export PATH=$HOME/.cargo/bin:$HOME/.local/share/bob/nvim-bin:$PATH && " ..
               "$HOME/.cargo/bin/bob use " .. host_version .. " 2>/dev/null || true && " ..
               "$HOME/.cargo/bin/bob run " .. host_version
  else
    debug.warn("could not detect host nvim version: " .. (version_err or "unknown error"))
    nvim_cmd = "nvim"
  end
  
  -- execute based on enter_mode - using reliable devcontainer exec approach
  if enter_mode == "external" then
    -- use devcontainer exec directly (like DevcontainerShell) but with nvim command
    local exec_cmd = string.format("open -na WezTerm --args start -- devcontainer exec --workspace-folder %s bash -lc '%s'",
                                   workspace_folder, nvim_cmd)
    debug.info("launching wezterm with nvim: " .. exec_cmd)
    vim.notify("Starting WezTerm with nvim in devcontainer...", vim.log.levels.INFO)
    
    local result = vim.fn.system(exec_cmd)
    if vim.v.shell_error ~= 0 then
      debug.error("wezterm command failed: " .. result)
      vim.notify("Failed to start WezTerm: " .. result, vim.log.levels.ERROR)
      return false
    else
      debug.info("wezterm with nvim started successfully")
      return true
    end
  else -- "nested"
    -- use devcontainer exec directly in vim terminal with nvim command
    vim.notify("Starting nvim in devcontainer...", vim.log.levels.INFO)
    local exec_terminal_cmd = string.format("devcontainer exec --workspace-folder %s bash -lc '%s'",
                                           workspace_folder, nvim_cmd)
    vim.cmd("terminal " .. exec_terminal_cmd)
    
    -- get the terminal buffer number immediately after creation
    local terminal_bufnr = vim.api.nvim_get_current_buf()
    
    -- setup custom statusline for the devcontainer terminal
    vim.schedule(function()
      local statusline = require("devcontainers.statusline")
      statusline.setup_devcontainer_statusline(terminal_bufnr)
      
      -- ensure terminal gets focus and enter insert mode so user can interact with inner nvim
      vim.cmd("startinsert")
    end)
    return true
  end
end

-- run devcontainer exec command to get a shell in the container
function M.devcontainer_exec(workspace_folder, config)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  debug.info("opening shell in devcontainer for workspace: " .. workspace_folder)
  
  -- open shell in container
  vim.cmd("terminal devcontainer exec --workspace-folder " .. workspace_folder .. " bash")
  
  return true
end

return M