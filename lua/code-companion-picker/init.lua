local M = {}

local setup_done = false

function M.setup(user_config)
	if setup_done then
		return
	end

	require("code-companion-picker.config").setup(user_config or {})
	setup_done = true
end

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

function M.show_tools()
	local config = require("code-companion-picker.config").get()
	local pickers = require("code-companion-picker.ui.pickers")
	local handlers = require("code-companion-picker.ui.tool_handlers")

	-- Get tools from CodeCompanion tools configuration
	local tools_info = M.get_codecompanion_tools()

	if #tools_info == 0 then
		vim.notify("code-companion-picker: No tools available", vim.log.levels.WARN)
		return
	end

	-- Use the configured picker
	pickers.show_tool_picker(tools_info, handlers.handle_tool_selection)
end

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

-- Public API: Get all tools from CodeCompanion's tools configuration
function M.get_codecompanion_tools()
	local ok, result = pcall(function()
		local tools = require("code-companion-picker.utils.tools")
		return tools.get_codecompanion_tools_info()
	end)

	if not ok then
		vim.notify("code-companion-picker: Failed to get tools: " .. result, vim.log.levels.ERROR)
		return {}
	end

	return result
end

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

-- Public API: Create display text for a tool
function M.create_tool_display_text(tool_info)
	if not tool_info then
		return "Unknown tool"
	end

	local ok, result = pcall(function()
		local tools = require("code-companion-picker.utils.tools")
		return tools.create_display_text(tool_info)
	end)

	if not ok then
		return "Error displaying tool"
	end

	return result
end

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

-- Public API: Convert codecompanion tool to markdown for preview
function M.tool_to_markdown(tool_info)
	if not tool_info then
		return ""
	end

	local ok, result = pcall(function()
		local tools = require("code-companion-picker.utils.tools")
		return tools.tool_to_markdown(tool_info)
	end)

	if not ok then
		return ""
	end

	return result
end

function M.apply_markdown_highlighting(bufnr, lines, highlights)
	if not bufnr or not lines then
		return
	end

	pcall(function()
		local highlighting = require("code-companion-picker.utils.highlighting")
		highlighting.apply_markdown_highlighting(bufnr, lines, highlights)
	end)
end

M.select_slash_command = {
	description = "Select CodeCompanion prompt",
	callback = function()
		M.show_prompts()
	end,
}

M.select_tool_slash_command = {
	description = "Select CodeCompanion tool",
	callback = function()
		M.show_tools()
	end,
}

function M.show_skills()
	local pickers = require("code-companion-picker.ui.pickers")
	local handlers = require("code-companion-picker.ui.skill_handlers")
	local skills_util = require("code-companion-picker.utils.skills")

	local skills_info = skills_util.list()

	if #skills_info == 0 then
		vim.notify("code-companion-picker: No skills available", vim.log.levels.WARN)
		return
	end

	pickers.show_skill_picker(skills_info, handlers.handle_skill_selection)
end

M.select_skill_slash_command = {
	description = "Select a skill to insert into chat",
	callback = function()
		M.show_skills()
	end,
}

return M
