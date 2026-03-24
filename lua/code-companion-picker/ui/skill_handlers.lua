local M = {}

local function get_or_open_chat(callback)
	local chat_utils = require("code-companion-picker.codecompanion.chat_utils")
	local chat_instance = chat_utils.get_current_chat()

	if chat_instance then
		callback(chat_instance)
		return
	end

	if not chat_utils.ensure_chat_open() then
		vim.notify("code-companion-picker: Could not open CodeCompanion chat", vim.log.levels.ERROR)
		return
	end

	vim.defer_fn(function()
		local chat = chat_utils.get_current_chat()
		if chat then
			callback(chat)
		else
			vim.notify("code-companion-picker: Could not get chat instance", vim.log.levels.ERROR)
		end
	end, 200)
end

function M.handle_skill_selection(skill)
	get_or_open_chat(function(chat)
		local skills_util = require("code-companion-picker.utils.skills")
		local content = skills_util.read(skill.name)

		if not content or content == "" then
			vim.notify("code-companion-picker: Failed to read skill: " .. skill.name, vim.log.levels.ERROR)
			return
		end

		local id = "<skill>" .. skill.name .. "</skill>"
		chat:add_context({ content = content }, "skill", id)
	end)
end

return M
