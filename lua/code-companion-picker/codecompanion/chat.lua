local v = vim

local M = {}

local chat_utils = require("code-companion-picker.codecompanion.chat_utils")

-- For now, append full_stack_dev tool to user prompts
function M.append_tool_instruction_if_needed(content)
  return content .. "\nPlease use the @{full_stack_dev} tool"
end

function M.add_user_message(content)
  if not content or content == "" then
    v.notify("code-companion-picker: Cannot add empty message to chat", v.log.levels.WARN)
    return false
  end

  local chat = chat_utils.get_current_chat()
  if chat and chat.add_buf_message then
    chat:add_buf_message({
      content = content .. "\n",
    })
    return true
  end

  if chat_utils.ensure_chat_open() then
    v.defer_fn(function()
      local new_chat = chat_utils.get_current_chat()
      if new_chat and new_chat.add_buf_message then
        new_chat:add_buf_message({
          content = content,
        })
      else
        v.notify("code-companion-picker: Failed to add message - CodeCompanion chat is not responding", v.log.levels.ERROR)
      end
    end, 100)
  end

  return true
end

-- Add system message - we'll need this for handling system prompts
function M.add_system_message(content)
  if not content or content == "" then
    v.notify("code-companion-picker: Cannot add empty system message to chat", v.log.levels.WARN)
    return false
  end

  local chat = chat_utils.get_current_chat()
  if not chat then
    if not chat_utils.ensure_chat_open() then
      return false
    end
    -- Wait for chat to open
    v.defer_fn(function()
      M.add_system_message(content)
    end, 100)
    return true
  end

  -- For system prompts, we need to set the system prompt on the chat
  if chat.set_system_prompt then
    chat:set_system_prompt(content)
    v.notify("code-companion-picker: System prompt updated", v.log.levels.INFO)
    return true
  else
    v.notify("code-companion-picker: Cannot set system prompt - CodeCompanion API may have changed", v.log.levels.WARN)
    return false
  end
end

return M