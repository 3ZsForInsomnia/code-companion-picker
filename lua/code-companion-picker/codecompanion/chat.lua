local v = vim

local M = {}

local chat_utils = require("code-companion-picker.codecompanion.chat_utils")

-- For now, append agent tool group to user prompts
-- function M.append_tool_instruction_if_needed(content)
-- 	return content .. "\nPlease use the @{agent} tool"
-- end

function M.add_user_message(content)
	if not content or content == "" then
		v.notify("code-companion-picker: Cannot add empty message to chat", v.log.levels.WARN)
		return false
	end

	local chat = chat_utils.get_current_chat()
	if chat and chat.add_buf_message then
		chat:add_buf_message({
			content = content .. "\n",
		})
		return true
	end

	if chat_utils.ensure_chat_open() then
		v.defer_fn(function()
			local new_chat = chat_utils.get_current_chat()
			if new_chat and new_chat.add_buf_message then
				new_chat:add_buf_message({
					content = content,
				})
			else
				v.notify(
					"code-companion-picker: Failed to add message - CodeCompanion chat is not responding",
					v.log.levels.ERROR
				)
			end
		end, 100)
	end

	return true
end

function M.add_system_message(content)
	if not content or content == "" then
		v.notify("code-companion-picker: Cannot add empty system message to chat", v.log.levels.WARN)
		return false
	end

	local chat = chat_utils.get_current_chat()
	if not chat then
		if not chat_utils.ensure_chat_open() then
			return false
		end
		-- Wait for chat to open
		v.defer_fn(function()
			M.add_system_message(content)
		end, 100)
		return true
	end

	-- For system prompts, we need to set the system prompt on the chat
	if chat.set_system_prompt then
		chat:set_system_prompt(content)
		v.notify("code-companion-picker: System prompt updated", v.log.levels.INFO)
		return true
	else
		v.notify(
			"code-companion-picker: Cannot set system prompt - CodeCompanion API may have changed",
			v.log.levels.WARN
		)
		return false
	end
end

-- Insert text at the current cursor position in the chat buffer
function M.insert_at_cursor(text)
	if not text or text == "" then
		v.notify("code-companion-picker: Cannot insert empty text", v.log.levels.WARN)
		return false
	end

	local chat = chat_utils.get_current_chat()
	if not chat then
		v.notify("code-companion-picker: No active chat found", v.log.levels.ERROR)
		return false
	end

	-- Get the chat buffer
	local chat_bufnr = chat.bufnr
	if not chat_bufnr or not v.api.nvim_buf_is_valid(chat_bufnr) then
		v.notify("code-companion-picker: Invalid chat buffer", v.log.levels.ERROR)
		return false
	end

	-- Find the chat window
	local chat_winid = nil
	for _, winid in ipairs(v.api.nvim_list_wins()) do
		if v.api.nvim_win_get_buf(winid) == chat_bufnr then
			chat_winid = winid
			break
		end
	end

	if not chat_winid then
		v.notify("code-companion-picker: Chat window not found", v.log.levels.ERROR)
		return false
	end

	-- Focus the chat window and insert the text at cursor
	v.api.nvim_set_current_win(chat_winid)

	-- Insert the text at the current cursor position
	local cursor = v.api.nvim_win_get_cursor(chat_winid)
	local row, col = cursor[1], cursor[2]

	-- Get the current line
	local line = v.api.nvim_buf_get_lines(chat_bufnr, row - 1, row, false)[1] or ""

	-- Insert the text at the cursor position, handling multi-line content
	local before = line:sub(1, col)
	local after = line:sub(col + 1)
	local text_lines = v.split(text, "\n", { plain = true })

	text_lines[1] = before .. text_lines[1]
	text_lines[#text_lines] = text_lines[#text_lines] .. after

	v.api.nvim_buf_set_lines(chat_bufnr, row - 1, row, false, text_lines)

	local last_line_row = row - 1 + #text_lines
	local last_line_col = #text_lines[#text_lines] - #after
	v.api.nvim_win_set_cursor(chat_winid, { last_line_row, last_line_col })

	return true
end

return M
