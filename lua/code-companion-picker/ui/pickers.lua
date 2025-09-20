local M = {}

-- Main function to show picker based on config
function M.show_picker(prompts_info, selection_handler)
  local config = require("code-companion-picker.config").get()
  
  if config.picker == "snacks" then
    return M.use_snacks_picker(prompts_info, selection_handler)
  elseif config.picker == "telescope" then
    return M.use_telescope_picker(prompts_info, selection_handler)
  elseif config.picker == "vim_ui" then
    return M.use_vim_ui_select(prompts_info, selection_handler)
  elseif config.picker == "auto" then
    -- Try Snacks first, then Telescope, then vim.ui.select
    if M.try_snacks_picker(prompts_info, selection_handler) then
      return true
    elseif M.try_telescope_picker(prompts_info, selection_handler) then
      return true
    else
      return M.use_vim_ui_select(prompts_info, selection_handler)
    end
  else
    vim.notify("code-companion-picker: Unknown picker: " .. config.picker, vim.log.levels.ERROR)
    return false
  end
end

-- Try Snacks picker (returns true if successful, false if not available)
function M.try_snacks_picker(prompts_info, selection_handler)
  local has_snacks = pcall(require, "snacks")
  if not has_snacks then
    return false
  end
  
  return M.use_snacks_picker(prompts_info, selection_handler)
end

-- Use Snacks picker
function M.use_snacks_picker(prompts_info, selection_handler)
  local has_snacks, snacks = pcall(require, "snacks")
  if not has_snacks then
    vim.notify("code-companion-picker: snacks.nvim not found", vim.log.levels.ERROR)
    return false
  end
  
  if not snacks.picker then
    vim.notify("code-companion-picker: snacks.picker not available", vim.log.levels.ERROR)
    return false
  end
  
  local snacks_picker = require("code-companion-picker.pickers.snacks")
  return snacks_picker.show_picker(prompts_info, selection_handler)
end

-- Try Telescope picker (returns true if successful, false if not available)
function M.try_telescope_picker(prompts_info, selection_handler)
  local has_telescope = pcall(require, "telescope")
  if not has_telescope then
    return false
  end
  
  return M.use_telescope_picker(prompts_info, selection_handler)
end

-- Use Telescope picker
function M.use_telescope_picker(prompts_info, selection_handler)
  local has_telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("code-companion-picker: telescope.nvim not found", vim.log.levels.ERROR)
    return false
  end
  
  local telescope_picker = require("code-companion-picker.pickers.telescope")
  return telescope_picker.show_picker(prompts_info, selection_handler)
end

-- Use vim.ui.select as fallback
function M.use_vim_ui_select(prompts_info, selection_handler)
  local display = require("code-companion-picker.ui.display")
  local items = display.create_display_items(prompts_info)

  vim.ui.select(items, {
    prompt = "Select CodeCompanion Prompt",
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if choice and idx then
      local selected_prompt = prompts_info[idx]
      selection_handler(selected_prompt)
    end
  end)
  
  return true
end

return M