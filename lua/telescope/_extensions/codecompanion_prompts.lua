local has_telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope.nvim is required for this extension")
end

local M = {}

function M.prompts(opts)
  opts = opts or {}
  
  -- Get prompts from CodeCompanion
  local code_companion_picker = require("code-companion-picker")
  local prompts_info = code_companion_picker.get_codecompanion_prompts()
  
  if #prompts_info == 0 then
    local display = require("code-companion-picker.ui.display")
    display.show_no_prompts_error()
    return
  end
  
  -- Use the telescope picker
  local telescope_picker = require("code-companion-picker.pickers.telescope")
  local handlers = require("code-companion-picker.ui.handlers")
  
  telescope_picker.show_picker(prompts_info, handlers.handle_prompt_selection)
end

return require("telescope").register_extension({
  setup = function() end,
  exports = {
    prompts = M.prompts,
  },
})