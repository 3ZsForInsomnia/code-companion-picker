local M = {}

function M.handle_tool_selection(tool_info)
  -- Get or create a chat instance
  local chat_utils = require("code-companion-picker.codecompanion.chat_utils")
  local chat_instance = chat_utils.get_current_chat()
  
  -- If no chat is open, ensure one is opened
  if not chat_instance then
    if not chat_utils.ensure_chat_open() then
      vim.notify("code-companion-picker: Could not open CodeCompanion chat", vim.log.levels.ERROR)
      return
    end
    
    -- Wait a bit for the chat to open, then try again
    vim.defer_fn(function()
      M.handle_tool_selection(tool_info)
    end, 200)
    return
  end
  
  -- Insert the tool as a slash command at the cursor position
  local tool_name = tool_info.name
  if tool_name then
    M.insert_tool_slash_command(tool_name)
  else
    vim.notify("code-companion-picker: Tool name not found", vim.log.levels.ERROR)
  end
end

function M.insert_tool_slash_command(tool_name)
  local chat_module = require("code-companion-picker.codecompanion.chat")
  local slash_command = "@{" .. tool_name .. "}"
  
  -- Insert the slash command at the current cursor position
  chat_module.insert_at_cursor(slash_command)
end

return M