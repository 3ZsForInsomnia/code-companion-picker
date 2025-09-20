local M = {}

function M.show_picker(prompts_info, selection_handler)
  local config = require("code-companion-picker.config").get()
  
  if config.picker == "snacks" then
    return M.use_snacks_picker(prompts_info, selection_handler)
  elseif config.picker == "telescope" then
    return M.use_telescope_picker(prompts_info, selection_handler)
  else
    vim.notify("code-companion-picker: Unknown picker: " .. config.picker, vim.log.levels.ERROR)
    return false
  end
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

return M