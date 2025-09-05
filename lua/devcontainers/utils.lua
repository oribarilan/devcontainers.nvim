local M = {}

-- File and path utilities
function M.file_exists(path)
  -- Try using vim.loop if available (when running inside Neovim)
  if vim and vim.loop then
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == "file"
  end
  
  -- Fallback: use system test command
  local success, _, _ = M.execute_command("test -f '" .. path .. "'")
  return success
end

function M.dir_exists(path)
  -- Try using vim.loop if available (when running inside Neovim)
  if vim and vim.loop then
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == "directory"
  end
  
  -- Fallback: use system test command
  local success, _, _ = M.execute_command("test -d '" .. path .. "'")
  return success
end

-- Resolve symlinks to get the actual target path
function M.resolve_symlink(path)
  -- Try using vim.loop if available (when running inside Neovim)
  if vim and vim.loop then
    local stat = vim.loop.fs_lstat(path) -- lstat doesn't follow symlinks
    if stat and stat.type == "link" then
      -- Read the symlink target
      local target = vim.loop.fs_readlink(path)
      if target then
        -- If target is relative, make it absolute relative to the symlink's directory
        if not target:match("^/") then
          local parent = path:match("^(.*)/[^/]*$")
          if parent then
            target = parent .. "/" .. target
          end
        end
        return target
      end
    end
    return path
  end
  
  -- Fallback: use system readlink command when vim.loop is not available
  local handle = io.popen("readlink '" .. path .. "' 2>/dev/null")
  if not handle then
    return path
  end
  
  local target = handle:read("*a")
  local success = handle:close()
  
  if not success or not target or target:match("^%s*$") then
    return path
  end
  
  -- Clean up the target (remove trailing whitespace)
  target = target:gsub("%s+$", "")
  
  -- If target is relative, make it absolute relative to the symlink's directory
  if not target:match("^/") then
    local parent = path:match("^(.*)/[^/]*$")
    if parent then
      target = parent .. "/" .. target
    end
  end
  
  return target
end

function M.path_join(...)
  local parts = { ... }
  return table.concat(parts, "/"):gsub("//+", "/")
end

-- String utilities
function M.trim(str)
  return str:match("^%s*(.-)%s*$")
end

function M.split(str, delimiter)
  delimiter = delimiter or "%s"
  local result = {}
  
  for match in str:gmatch("([^" .. delimiter .. "]+)") do
    table.insert(result, match)
  end
  
  return result
end

-- Table utilities
function M.merge_tables(t1, t2)
  local result = {}
  
  for k, v in pairs(t1 or {}) do
    result[k] = v
  end
  
  for k, v in pairs(t2 or {}) do
    result[k] = v
  end
  
  return result
end

function M.deep_merge(t1, t2)
  local result = vim.deepcopy(t1 or {})
  
  for k, v in pairs(t2 or {}) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

-- Neovim version detection
function M.get_nvim_version()
  local handle = io.popen("nvim --version 2>/dev/null")
  if not handle then
    return nil, "failed to execute nvim --version"
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  if not success or not output then
    return nil, "nvim command failed"
  end
  
  -- Parse version from output like "NVIM v0.9.1"
  local version = output:match("NVIM v([%d%.]+)")
  if not version then
    return nil, "could not parse nvim version from output: " .. output
  end
  
  return version, nil
end

-- Check if nvim is installed
function M.is_nvim_installed()
  local version, err = M.get_nvim_version()
  return version ~= nil, err
end

-- Execute command and return output
function M.execute_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return false, nil, "failed to execute command: " .. cmd
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  return success, M.trim(output or ""), nil
end

-- Check if a command exists in PATH
function M.command_exists(cmd)
  local success, _, _ = M.execute_command("command -v " .. cmd)
  return success
end

-- Expand environment variables in path
function M.expand_path(path)
  if not path then
    return nil
  end
  
  -- Handle ~ expansion (tilde to HOME)
  if path:match("^~") then
    path = path:gsub("^~", os.getenv("HOME") or "")
  end
  
  -- Handle $HOME expansion
  path = path:gsub("^%$HOME", os.getenv("HOME") or "")
  
  -- Handle ${var} expansion
  path = path:gsub("%$%{([^}]+)%}", function(var)
    return os.getenv(var) or ""
  end)
  
  -- Handle $VAR expansion
  path = path:gsub("%$([%w_]+)", function(var)
    return os.getenv(var) or ""
  end)
  
  return path
end

-- Get default nvim config path based on OS
function M.get_default_nvim_config_path()
  local home = os.getenv("HOME")
  if not home then
    return nil, "HOME environment variable not set"
  end
  
  -- Detect OS
  local os_name
  if vim and vim.loop then
    os_name = vim.loop.os_uname().sysname
  else
    -- Fallback: use system uname command
    local success, output, _ = M.execute_command("uname -s")
    if success then
      os_name = output
    else
      os_name = "Linux" -- default fallback
    end
  end
  
  local config_path
  
  if os_name == "Darwin" then
    -- macOS
    config_path = home .. "/.config/nvim"
  elseif os_name == "Linux" then
    -- Linux
    local xdg_config = os.getenv("XDG_CONFIG_HOME")
    if xdg_config then
      config_path = xdg_config .. "/nvim"
    else
      config_path = home .. "/.config/nvim"
    end
  elseif os_name:match("Windows") then
    -- Windows
    local appdata = os.getenv("LOCALAPPDATA")
    if appdata then
      config_path = appdata .. "\\nvim"
    else
      config_path = home .. "\\AppData\\Local\\nvim"
    end
  else
    -- fallback to unix-style
    config_path = home .. "/.config/nvim"
  end
  
  return config_path, nil
end

return M