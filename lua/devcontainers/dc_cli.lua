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

-- run devcontainer up command
function M.devcontainer_up(workspace_folder)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  debug.info("starting devcontainer up for workspace: " .. workspace_folder)
  
  local stdout_buffer = {}
  local stderr_buffer = {}
  
  vim.fn.jobstart({ "devcontainer", "up", "--workspace-folder", workspace_folder }, {
    on_stdout = function(_, data, _)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            table.insert(stdout_buffer, line)
          end
        end
        
        -- show accumulated output
        if #stdout_buffer > 0 then
          local output = table.concat(stdout_buffer, "\n")
          vim.notify("devcontainer:\n" .. output, vim.log.levels.INFO)
          stdout_buffer = {}
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            table.insert(stderr_buffer, line)
          end
        end
        
        -- show accumulated errors
        if #stderr_buffer > 0 then
          local output = table.concat(stderr_buffer, "\n")
          vim.notify("devcontainer:\n" .. output, vim.log.levels.WARN)
          stderr_buffer = {}
        end
      end
    end,
    on_exit = function(_, code, _)
      if code == 0 then
        vim.notify("devcontainer up completed successfully", vim.log.levels.INFO)
      else
        vim.notify("devcontainer up failed with code: " .. code, vim.log.levels.ERROR)
      end
    end,
  })
  
  return true
end

-- run devcontainer exec command to enter the container with nvim
function M.devcontainer_enter(workspace_folder)
  if not M.ensure_available() then
    return false
  end
  
  workspace_folder = workspace_folder or vim.loop.cwd()
  debug.info("entering devcontainer with nvim for workspace: " .. workspace_folder)
  
  vim.fn.jobstart({
    "devcontainer", "exec", "--workspace-folder", workspace_folder, "nvim"
  }, { detach = true })
  
  return true
end

return M