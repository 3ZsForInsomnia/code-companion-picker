local v = vim

local M = {}

function M.get_current_chat()
  if v.bo.filetype ~= "codecompanion" then
    return nil
  end

  local chat_strategy = require("codecompanion.strategies.chat")
  if not chat_strategy then
    return nil
  end

  local bufnr = v.api.nvim_get_current_buf()
  local chat = chat_strategy.buf_get_chat(bufnr)

  if not chat then
    chat = chat_strategy.last_chat()
  end

  return chat
end

function M.ensure_chat_open()
  if v.bo.filetype == "codecompanion" then
    return true
  end

  -- Check if CodeCompanion is available before trying to use it
  local has_codecompanion = pcall(require, "codecompanion")
  if not has_codecompanion then
    v.notify("code-companion-picker: CodeCompanion plugin not found", v.log.levels.ERROR)
    return false
  end
  
  local ok, err = pcall(v.cmd, "CodeCompanionChat Toggle")
  if not ok then
    v.notify("code-companion-picker: Error opening CodeCompanion chat: " .. tostring(err), v.log.levels.ERROR)
    return false
  end

  -- Wait a bit for the chat to open and check if it worked
  local attempts = 0
  local max_attempts = 10
  
  local function check_chat()
    attempts = attempts + 1
    if v.bo.filetype == "codecompanion" then
      return true
    elseif attempts >= max_attempts then
      v.notify("code-companion-picker: Could not open CodeCompanion chat - ensure CodeCompanion is properly configured", v.log.levels.ERROR)
      return false
    else
      v.defer_fn(check_chat, 50)
      return nil -- still waiting
    end
  end
  
  -- Start checking
  v.defer_fn(check_chat, 50)

  return true
end

return M