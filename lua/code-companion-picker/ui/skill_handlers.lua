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

local function chat_has_context(chat, id)
	return vim.iter(chat.messages):any(function(msg)
		return msg.context ~= nil and msg.context.id == id
	end)
end

function M.handle_skill_selection(skill)
	get_or_open_chat(function(chat)
		local id = "<skill>" .. skill.name .. "</skill>"
		if chat_has_context(chat, id) then
			vim.notify("code-companion-picker: Skill already in chat: " .. skill.name, vim.log.levels.INFO)
			return
		end

		local skills_util = require("code-companion-picker.utils.skills")
		local content = skills_util.read_framed(skill.name)

		if not content then
			vim.notify("code-companion-picker: Failed to read skill: " .. skill.name, vim.log.levels.ERROR)
			return
		end

		chat:add_context({ content = content }, { source = "skill", id = id })
	end)
end

return M
