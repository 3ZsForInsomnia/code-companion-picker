-- code-companion-picker.nvim
-- A picker for CodeCompanion prompts with preview support

if vim.g.loaded_code_companion_picker then
  return
end
vim.g.loaded_code_companion_picker = 1

-- Create user commands
vim.api.nvim_create_user_command("CodeCompanionPrompts", function()
  require("code-companion-picker").show_prompts()
end, {
  desc = "Show CodeCompanion prompts with preview",
})