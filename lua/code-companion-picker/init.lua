local M = {}

local setup_done = false

function M.setup(user_config)
  if setup_done then
    return
  end
  
  require("code-companion-picker.config").setup(user_config or {})
  setup_done = true
end

-- Main function to show prompts picker
function M.show_prompts()
  local config = require("code-companion-picker.config").get()
  local pickers = require("code-companion-picker.ui.pickers")
  local handlers = require("code-companion-picker.ui.handlers")
  
  -- Get prompts from CodeCompanion prompt library
  local prompts_info = M.get_codecompanion_prompts()
  
  if #prompts_info == 0 then
    local display = require("code-companion-picker.ui.display")
    display.show_no_prompts_error()
    return
  end
  
  -- Use the configured picker
  pickers.show_picker(prompts_info, handlers.handle_prompt_selection)
end

-- Public API: Get all prompts from CodeCompanion's prompt library
function M.get_codecompanion_prompts()
  local ok, result = pcall(function()
    local prompts = require("code-companion-picker.utils.prompts")
    return prompts.get_codecompanion_prompts_info()
  end)
  
  if not ok then
    vim.notify("code-companion-picker: Failed to get prompts: " .. result, vim.log.levels.ERROR)
    return {}
  end
  
  return result
end

-- Public API: Create display text for a prompt
function M.create_prompt_display_text(prompt_info)
  if not prompt_info then
    return "Unknown prompt"
  end
  
  local ok, result = pcall(function()
    local prompts = require("code-companion-picker.utils.prompts")
    return prompts.create_display_text(prompt_info)
  end)
  
  if not ok then
    return "Error displaying prompt"
  end
  
  return result
end

-- Public API: Convert codecompanion prompt to markdown for preview
function M.codecompanion_to_markdown(prompt_data, prompt_name)
  if not prompt_data then
    return ""
  end
  
  local ok, result = pcall(function()
    local markdown_converter = require("code-companion-picker.utils.markdown_converter")
    return markdown_converter.codecompanion_to_markdown(prompt_data, prompt_name)
  end)
  
  if not ok then
    return ""
  end
  
  return result
end

-- Public API: Apply markdown highlighting to buffer
function M.apply_markdown_highlighting(bufnr, lines, highlights)
  if not bufnr or not lines then
    return
  end
  
  pcall(function()
    local highlighting = require("code-companion-picker.utils.highlighting")
    highlighting.apply_markdown_highlighting(bufnr, lines, highlights)
  end)
end

-- Slash command integration for CodeCompanion
M.select_slash_command = {
  description = "Select CodeCompanion prompt",
  callback = function()
    M.show_prompts()
  end,
}

return M