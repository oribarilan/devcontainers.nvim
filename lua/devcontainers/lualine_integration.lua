-- lualine integration for devcontainer mode
local M = {}

-- lualine component for showing devcontainer status
M.devcontainer_component = {
  function()
    -- check if current buffer is a devcontainer terminal
    if vim.b.devcontainer_mode then
      return "🐳 Devcontainer"
    end
    return ""
  end,
  color = { fg = "#ffffff", bg = "#0066cc", gui = "bold" },
}

-- setup function to add devcontainer component to lualine
function M.setup_lualine()
  local has_lualine, lualine = pcall(require, "lualine")
  if not has_lualine then
    return false
  end
  
  -- get current lualine config
  local config = lualine.get_config()
  
  -- add devcontainer component to section_a if it doesn't exist
  if config.sections and config.sections.lualine_a then
    local has_devcontainer = false
    for _, component in ipairs(config.sections.lualine_a) do
      if type(component) == "table" and component[1] and 
         string.match(tostring(component[1]), "devcontainer") then
        has_devcontainer = true
        break
      end
    end
    
    if not has_devcontainer then
      table.insert(config.sections.lualine_a, 1, M.devcontainer_component)
      lualine.setup(config)
      return true
    end
  end
  
  return false
end

return M