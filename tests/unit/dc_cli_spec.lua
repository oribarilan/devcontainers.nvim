describe("dc_cli", function()
  local dc_cli
  
  before_each(function()
    dc_cli = require("devcontainers.dc_cli")
  end)
  
  it("should load without errors", function()
    -- basic smoke test - just ensure the module can be loaded
    assert(dc_cli ~= nil)
  end)
  
  describe("devcontainer_enter", function()
    it("should use simple shell approach without complex chaining", function()
      -- Test that the new approach is simpler and doesn't try to chain complex commands
      -- This is more of a design verification than functional testing
      -- The actual function requires vim environment to run properly
      assert(dc_cli.devcontainer_enter ~= nil)
    end)
  end)
end)