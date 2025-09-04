local M = {}

-- File and path utilities
function M.file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

function M.dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
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

return M