local models = require("code-companion-picker.codecompanion.models")
local chat_module = require("code-companion-picker.codecompanion.chat")

local M = {}

function M.handle_prompt_selection(prompt_info)
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
			M.handle_prompt_selection(prompt_info)
		end, 200)
		return
	end

	-- Apply model if specified
	if prompt_info.frontmatter and prompt_info.frontmatter.model then
		models.apply_model_to_chat(prompt_info.frontmatter.model, chat_instance)
	end

	-- Handle the prompt based on its structure
	if prompt_info.prompt_data and prompt_info.prompt_data.prompts then
		M.handle_codecompanion_prompt(prompt_info, chat_instance)
	else
		-- Fallback to user content
		if prompt_info.content and prompt_info.content ~= "" then
			-- local content = chat_module.append_tool_instruction_if_needed(prompt_info.content)
			chat_module.add_user_message(prompt_info.content)
		end
	end
end

function M.handle_codecompanion_prompt(prompt_info, chat_instance)
	local prompts = prompt_info.prompt_data.prompts or {}

	-- Check if this prompt has a system message
	local has_system = false
	local system_content = ""
	local user_content = ""

	-- Create context for this execution
	local markdown_converter = require("code-companion-picker.utils.markdown_converter")
	local context = markdown_converter.create_context()

	for _, prompt in ipairs(prompts) do
		if prompt.role == "system" then
			has_system = true
			local content = M.get_prompt_content_with_context(prompt, context)
			if system_content ~= "" then
				system_content = system_content .. "\n\n" .. content
			else
				system_content = content
			end
		elseif prompt.role == "user" then
			local content = M.get_prompt_content_with_context(prompt, context)
			if user_content ~= "" then
				user_content = user_content .. "\n\n" .. content
			else
				user_content = content
			end
		end
	end

	-- Handle system prompt first if present
	if has_system and system_content ~= "" then
		chat_module.add_system_message(system_content)
	end

	-- Handle user content
	if user_content ~= "" then
		-- local content = chat_module.append_tool_instruction_if_needed(user_content)
		chat_module.add_user_message(user_content)
	end
end

-- Get prompt content with a specific context (for actual usage)
function M.get_prompt_content_with_context(prompt, context)
	if not prompt then
		return ""
	end

	local content = prompt.content

	if content == nil then
		return ""
	end

	if type(content) == "function" then
		local ok, result = pcall(content, context)
		if ok and type(result) == "string" then
			return result
		elseif ok then
			return tostring(result or "")
		else
			vim.notify(
				"code-companion-picker: Failed to execute prompt content function: " .. tostring(result),
				vim.log.levels.WARN
			)
			return ""
		end
	end

	if type(content) == "string" then
		return content
	end

	return tostring(content)
end

return M
