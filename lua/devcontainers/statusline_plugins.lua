-- optional integrations for statusline plugins
local M = {}

local debug = require("devcontainers.debug")

-- registry of available plugin integrations
local integrations = {}

-- register a statusline plugin integration
function M.register_integration(name, integration)
  if type(integration) ~= "table" or type(integration.setup) ~= "function" then
    debug.warn("invalid integration for " .. name .. ": must have setup function")
    return false
  end
  
  integrations[name] = integration
  debug.debug("registered statusline integration: " .. name)
end

-- setup integrations for available plugins
function M.setup_available_integrations()
  for name, integration in pairs(integrations) do
    local success, result = pcall(integration.setup)
    if success and result then
      debug.info("successfully setup statusline integration: " .. name)
    else
      debug.debug("statusline integration " .. name .. " not available or failed")
    end
  end
end

-- get current registered integrations (for testing)
function M.get_integrations()
  return vim.deepcopy(integrations)
end

-- built-in lualine integration
local lualine_integration = {
  setup = function()
    local has_lualine, lualine = pcall(require, "lualine")
    if not has_lualine then
      return false
    end
    
    -- get current lualine config
    local config = lualine.get_config()
    
    -- replace mode component in section_a with devcontainer-aware version
    if config.sections and config.sections.lualine_a then
      -- find and replace the mode component
      for i, component in ipairs(config.sections.lualine_a) do
        -- check if this is the mode component
        local is_mode_component = false
        if type(component) == "string" and component == "mode" then
          is_mode_component = true
        elseif type(component) == "table" and component[1] == "mode" then
          is_mode_component = true
        end
        
        if is_mode_component then
          -- replace with devcontainer-aware mode component
          config.sections.lualine_a[i] = {
            function()
              -- show devcontainer instead of terminal mode
              if vim.b.devcontainer_mode then
                return "🐳 Devcontainer"
              end
              -- fallback to showing the actual mode
              local mode_map = {
                n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE",
                [""] = "V-BLOCK", c = "COMMAND", s = "SELECT", S = "S-LINE",
                [""] = "S-BLOCK", r = "REPLACE", R = "V-REPLACE",
                t = "TERMINAL", ["!"] = "SHELL", nt = "TERMINAL"
              }
              local current_mode = vim.api.nvim_get_mode().mode
              return mode_map[current_mode] or current_mode:upper()
            end,
            color = function()
              if vim.b.devcontainer_mode then
                return { fg = "#ffffff", bg = "#0066cc", gui = "bold" }
              end
              -- use default lualine mode colors for non-devcontainer
              return nil
            end,
          }
          lualine.setup(config)
          -- also modify the middle section to show root directory name
          local modified_middle = false
          for section_name, section in pairs(config.sections) do
            if section_name == "lualine_b" or section_name == "lualine_c" then
              for i, component in ipairs(section) do
                -- look for filename or similar components to replace
                if type(component) == "string" and (component == "filename" or component:find("term")) then
                  section[i] = {
                    function()
                      if vim.b.devcontainer_mode then
                        -- get root directory name
                        local cwd = vim.fn.getcwd()
                        return vim.fn.fnamemodify(cwd, ":t")  -- get just the directory name
                      end
                      -- fallback to original component behavior
                      if component == "filename" then
                        return vim.fn.expand("%:t")
                      end
                      return component
                    end,
                  }
                  modified_middle = true
                  break
                elseif type(component) == "table" and component[1] == "filename" then
                  section[i] = {
                    function()
                      if vim.b.devcontainer_mode then
                        -- get root directory name
                        local cwd = vim.fn.getcwd()
                        return vim.fn.fnamemodify(cwd, ":t")
                      end
                      -- fallback to filename
                      return vim.fn.expand("%:t")
                    end,
                  }
                  modified_middle = true
                  break
                end
              end
              if modified_middle then break end
            end
          end
          
          -- if no suitable component found, add directory name to lualine_c
          if not modified_middle and config.sections.lualine_c then
            table.insert(config.sections.lualine_c, 1, {
              function()
                if vim.b.devcontainer_mode then
                  local cwd = vim.fn.getcwd()
                  return vim.fn.fnamemodify(cwd, ":t")
                end
                return ""
              end,
            })
          end
          
          lualine.setup(config)
          return true
        end
      end
    end
    
    return false
  end,
}

-- register built-in integrations
M.register_integration("lualine", lualine_integration)

return M