local statusline = require("devcontainers.statusline")

describe("devcontainers.statusline", function()
  local test_bufnr
  
  before_each(function()
    -- initialize statusline system
    statusline.init()
    
    -- create a test buffer
    test_bufnr = vim.api.nvim_create_buf(false, true)
  end)
  
  after_each(function()
    -- cleanup test buffer if it exists
    if test_bufnr and vim.api.nvim_buf_is_valid(test_bufnr) then
      statusline.cleanup_devcontainer_statusline(test_bufnr)
      vim.api.nvim_buf_delete(test_bufnr, { force = true })
    end
    
    -- cleanup all statuslines
    statusline.cleanup_all()
    test_bufnr = nil
  end)
  
  it("should initialize successfully", function()
    local state = statusline.get_state()
    assert(state.augroup ~= nil, "augroup should be initialized")
    assert(vim.tbl_isempty(state.terminal_buffers), "terminal_buffers should be empty")
  end)
  
  it("should setup devcontainer statusline for valid buffer", function()
    -- display buffer in a window to make it accessible
    vim.cmd("split")
    vim.api.nvim_set_current_buf(test_bufnr)
    local winid = vim.api.nvim_get_current_win()
    
    -- set initial statusline
    vim.api.nvim_set_option_value("statusline", "original", { win = winid })
    
    -- setup devcontainer statusline
    local result = statusline.setup_devcontainer_statusline(test_bufnr)
    
    assert(result == true, "setup should succeed")
    
    -- verify statusline was changed
    local current_statusline = vim.api.nvim_get_option_value("statusline", { win = winid })
    assert(current_statusline == " Devcontainer Mode ", "statusline should be set to devcontainer mode")
    
    -- verify tracking state
    local state = statusline.get_state()
    assert(state.terminal_buffers[test_bufnr] ~= nil, "buffer should be tracked")
    assert(state.terminal_buffers[test_bufnr].original_statusline == "original", "original statusline should be stored")
    
    -- close the split
    vim.cmd("close")
  end)
  
  it("should not setup statusline for invalid buffer", function()
    local invalid_bufnr = 99999
    local result = statusline.setup_devcontainer_statusline(invalid_bufnr)
    
    assert(result == false, "setup should fail for invalid buffer")
    
    -- verify no tracking state
    local state = statusline.get_state()
    assert(state.terminal_buffers[invalid_bufnr] == nil, "invalid buffer should not be tracked")
  end)
  
  it("should cleanup devcontainer statusline correctly", function()
    -- display buffer in a window
    vim.cmd("split")
    vim.api.nvim_set_current_buf(test_bufnr)
    local winid = vim.api.nvim_get_current_win()
    
    -- setup statusline first
    vim.api.nvim_set_option_value("statusline", "original", { win = winid })
    statusline.setup_devcontainer_statusline(test_bufnr)
    
    -- cleanup statusline
    statusline.cleanup_devcontainer_statusline(test_bufnr)
    
    -- verify statusline was restored
    local current_statusline = vim.api.nvim_get_option_value("statusline", { win = winid })
    assert(current_statusline == "original", "statusline should be restored")
    
    -- verify tracking was removed
    local state = statusline.get_state()
    assert(state.terminal_buffers[test_bufnr] == nil, "buffer should not be tracked after cleanup")
    
    -- close the split
    vim.cmd("close")
  end)
  
  it("should handle double setup gracefully", function()
    -- display buffer in a window
    vim.cmd("split")
    vim.api.nvim_set_current_buf(test_bufnr)
    
    -- setup statusline twice
    local result1 = statusline.setup_devcontainer_statusline(test_bufnr)
    local result2 = statusline.setup_devcontainer_statusline(test_bufnr)
    
    assert(result1 == true, "first setup should succeed")
    assert(result2 == true, "second setup should succeed")
    
    -- verify only one entry in tracking
    local state = statusline.get_state()
    local count = 0
    for _ in pairs(state.terminal_buffers) do
      count = count + 1
    end
    assert(count == 1, "should track only one buffer")
    
    -- close the split
    vim.cmd("close")
  end)
  
  it("should cleanup all tracked buffers", function()
    -- create multiple test buffers and setup statuslines
    local buf1 = vim.api.nvim_create_buf(false, true)
    local buf2 = vim.api.nvim_create_buf(false, true)
    
    -- display buffers in windows to make them accessible
    vim.cmd("split")
    vim.api.nvim_set_current_buf(buf1)
    vim.cmd("split")
    vim.api.nvim_set_current_buf(buf2)
    
    statusline.setup_devcontainer_statusline(buf1)
    statusline.setup_devcontainer_statusline(buf2)
    
    -- verify tracking state
    local state = statusline.get_state()
    assert(state.terminal_buffers[buf1] ~= nil, "buf1 should be tracked")
    assert(state.terminal_buffers[buf2] ~= nil, "buf2 should be tracked")
    
    -- cleanup all
    statusline.cleanup_all()
    
    -- verify all tracking was removed
    state = statusline.get_state()
    assert(vim.tbl_isempty(state.terminal_buffers), "all terminal buffers should be cleaned up")
    assert(state.augroup == nil, "augroup should be cleaned up")
    
    -- cleanup test buffers and close splits
    vim.cmd("only") -- close all splits
    vim.api.nvim_buf_delete(buf1, { force = true })
    vim.api.nvim_buf_delete(buf2, { force = true })
  end)
end)