local v = vim

local M = {}

function M.create_display_items(prompts_info)
  local prompts_util = require("code-companion-picker.utils.prompts")
  local items = {}
  for _, info in ipairs(prompts_info) do
    table.insert(items, prompts_util.create_display_text(info))
  end
  return items
end

function M.show_no_prompts_error()
  v.notify(
    "No prompts available in CodeCompanion prompt library. You may need to import some prompts first.",
    v.log.levels.WARN
  )
end

return M