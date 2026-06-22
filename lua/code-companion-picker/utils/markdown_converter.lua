-- luacheck: globals vim
local M = {}

function M.get_prompt_content(prompt)
	if not prompt then
		return ""
	end

	local content = prompt.content

	-- Handle case where content is nil
	if content == nil then
		return ""
	end

	-- Handle case where content is a function
	if type(content) == "function" then
		-- CodeCompanion content functions expect a context parameter
		local context = M.create_context()
		local ok, result = pcall(content, context)
		if ok and type(result) == "string" then
			return result
		elseif ok then
			return tostring(result or "")
		else
			-- Function call failed
			return "Error: Failed to execute content function: " .. tostring(result)
		end
	end

	-- Handle case where content is a string
	if type(content) == "string" then
		return content
	end

	-- Handle other types
	return tostring(content)
end

function M.create_context()
	local bufnr = vim.api.nvim_get_current_buf()
	local winnr = vim.api.nvim_get_current_win()
	local is_codecompanion_buf = vim.bo[bufnr].filetype == "codecompanion"

	-- Get current selection if any
	local selection = ""
	local start_pos = { 1, 1 }
	local end_pos = { 1, 1 }

	-- If we're in a CodeCompanion buffer, we might want to get context from the main editor
	local target_bufnr = bufnr
	if is_codecompanion_buf then
		-- Try to find the previous non-codecompanion buffer
		local buffers = vim.api.nvim_list_bufs()
		for _, buf in ipairs(buffers) do
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype ~= "codecompanion" and vim.bo[buf].buflisted then
				target_bufnr = buf
				break
			end
		end
	end

	-- Get filetype and filename from target buffer
	local filetype = vim.bo[target_bufnr].filetype
	local filename = vim.api.nvim_buf_get_name(target_bufnr)

	-- Try to get visual selection
	local mode = vim.fn.mode()
	if not is_codecompanion_buf and (mode == "v" or mode == "V" or mode == "\22") then -- \22 is Ctrl-V
		local start_line = vim.fn.line("'<")
		local end_line = vim.fn.line("'>")
		local start_col = vim.fn.col("'<")
		local end_col = vim.fn.col("'>")

		start_pos = { start_line or 1, start_col or 1 }
		end_pos = { end_line or 1, end_col or 1 }

		if start_line and end_line then
			local lines = vim.api.nvim_buf_get_lines(target_bufnr, start_line - 1, end_line, false)
			if #lines > 0 then
				-- Handle different selection modes
				if mode == "V" then
					-- Line-wise selection
					selection = table.concat(lines, "\n")
				else
					-- Character-wise selection
					if #lines == 1 then
						selection = lines[1]:sub(start_col, end_col)
					else
						lines[1] = lines[1]:sub(start_col)
						lines[#lines] = lines[#lines]:sub(1, end_col)
						selection = table.concat(lines, "\n")
					end
				end
			end
		end
	else
		-- No visual selection, use cursor position
		local cursor_line = is_codecompanion_buf and 1 or vim.fn.line(".")
		local cursor_col = is_codecompanion_buf and 1 or vim.fn.col(".")
		start_pos = { cursor_line, cursor_col }
		end_pos = { cursor_line, cursor_col }
	end

	-- If no visual selection, try to get the current line or word
	if selection == "" then
		local cursor_line = is_codecompanion_buf and 1 or vim.fn.line(".")
		local lines = vim.api.nvim_buf_get_lines(target_bufnr, cursor_line - 1, cursor_line, false)
		if #lines > 0 then
			selection = lines[1]
		end
	end

	-- Create context object that matches CodeCompanion's expected structure
	local context = {
		bufnr = target_bufnr,
		winnr = winnr,
		filename = filename,
		filetype = filetype,
		selection = selection,
		-- Position information that CodeCompanion expects
		start_pos = { tonumber(start_pos[1]) or 1, tonumber(start_pos[2]) or 1 },
		end_pos = { tonumber(end_pos[1]) or 1, tonumber(end_pos[2]) or 1 },
		-- Range for compatibility
		range = {
			start = { tonumber(start_pos[1]) or 1, (tonumber(start_pos[2]) or 1) - 1 }, -- Convert to 0-based for range
			["end"] = { tonumber(end_pos[1]) or 1, (tonumber(end_pos[2]) or 1) - 1 },
		},
		-- Args that CodeCompanion templates expect
		args = {
			selection = selection,
			filetype = filetype,
			filename = vim.fn.fnamemodify(filename, ":t"), -- just the filename without path
			-- Add more args that CodeCompanion might expect
			line_count = vim.api.nvim_buf_line_count(target_bufnr),
			cursor_line = is_codecompanion_buf and 1 or vim.fn.line("."),
			cursor_col = is_codecompanion_buf and 1 or vim.fn.col("."),
		},
	}

	return context
end

-- Wrapper function that adds error handling
local function safe_get_prompt_content(prompt)
	local ok, result = pcall(M.get_prompt_content, prompt)
	if ok then
		return result
	else
		return "Error extracting content: " .. tostring(result)
	end
end

-- Use the safe wrapper in the markdown converter
function M.safe_get_prompt_content(prompt)
	return safe_get_prompt_content(prompt)
end

--- Get current system prompt from CodeCompanion config
function M.get_current_system_prompt(max_length)
	max_length = max_length or 200
	local ok, codecompanion_config = pcall(require, "codecompanion.config")
	if not ok or not codecompanion_config then
		return nil
	end
	
	local system_prompt = codecompanion_config.config.interactions.chat.opts.system_prompt
	if not system_prompt or type(system_prompt) == "function" then
		return nil
	end
	if system_prompt == "" then
		return nil
	end
	
	if #system_prompt <= max_length then
		return system_prompt
	else
		return system_prompt:sub(1, max_length) .. "..."
	end
end

--- Get full current system prompt from CodeCompanion config
function M.get_full_current_system_prompt()
	local ok, codecompanion_config = pcall(require, "codecompanion.config")
	if not ok or not codecompanion_config then
		return nil
	end
	
	local system_prompt = codecompanion_config.config.interactions.chat.opts.system_prompt
	if type(system_prompt) == "function" then
		return nil
	end
	return system_prompt
end

--- Extract section data from prompt
local function extract_section_data(prompt_data)
	local sections = {}
	
	-- Description
	sections.description = prompt_data.description
	
	-- Model
	sections.model = M.extract_model_from_prompt(prompt_data)
	
	-- Tools
	sections.tools = M.extract_tools_from_prompt(prompt_data)
	
	-- Options
	sections.opts = prompt_data.opts
	
	-- Mode - determine if we have system vs user prompts
	local has_system = false
	local has_user = false
	if prompt_data.prompts then
		for _, prompt in ipairs(prompt_data.prompts) do
			if prompt.role == "system" then
				has_system = true
			elseif prompt.role == "user" then
				has_user = true
			end
		end
	end
	sections.mode = (has_system and has_user and "Mixed") or 
	                (has_system and "System") or 
	                (has_user and "User") or nil
	
	-- Context - for now, we'll leave this nil but it's available for future use
	sections.context = nil
	
	-- Current system prompt
	sections.current_system = M.get_current_system_prompt()
	
	-- System and user prompt content (conditional)
	if prompt_data.prompts then
		local system_parts = {}
		local user_parts = {}
		
		for _, prompt in ipairs(prompt_data.prompts) do
			local content = M.safe_get_prompt_content(prompt)
			if prompt.role == "system" then
				table.insert(system_parts, content)
			elseif prompt.role == "user" then
				table.insert(user_parts, content)
			end
		end
		
		sections.system_prompt = (#system_parts > 0) and table.concat(system_parts, "\n\n") or nil
		sections.user_prompt = (#user_parts > 0) and table.concat(user_parts, "\n\n") or nil
	end
	
	return sections
end

--- Render a single section using configured renderer
local function render_section(section_name, section_data, prompt_data, renderers)
	local renderer = renderers[section_name]
	if not renderer then
		return nil
	end
	
	-- If renderer is false, disable this section
	if renderer == false then
		return nil
	end
	
	-- If renderer is a function, call it
	if type(renderer) == "function" then
		return renderer(section_data, prompt_data)
	end
	
	return nil
end

 function M.codecompanion_to_markdown(prompt_data, _, custom_renderers)
	if not prompt_data or type(prompt_data) ~= "table" then
		return ""
	end
	
	-- Get renderers from config, merged with any custom ones
	local config = require("code-companion-picker.config").get()
	local renderers = vim.tbl_deep_extend("force", config.renderers, custom_renderers or {})
	
	-- Extract all section data
	local sections = extract_section_data(prompt_data)
	
	-- Define fixed section order
	local section_order = {
		"description",
		"model", 
		"tools",
		"opts",
		"mode",
		"context",
		"current_system",
		"system_prompt",
		"user_prompt"
	}
	
	local lines = {}
	
	-- Render each section in order
	for _, section_name in ipairs(section_order) do
		local section_data = sections[section_name]
		local rendered = render_section(section_name, section_data, prompt_data, renderers)
		
		if rendered and rendered ~= "" then
			table.insert(lines, rendered)
			table.insert(lines, "") -- Add spacing between sections
		end
	end
	
	-- Remove trailing empty line if present
	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines)
	end
	
	return table.concat(lines, "\n")
end

-- Extract model information from codecompanion prompt
function M.extract_model_from_prompt(prompt_data)
	if prompt_data.opts and prompt_data.opts.adapter then
		if type(prompt_data.opts.adapter) == "string" then
			return prompt_data.opts.adapter
		elseif type(prompt_data.opts.adapter) == "table" and prompt_data.opts.adapter.model then
			return prompt_data.opts.adapter.model
		end
	end
	if prompt_data.opts and prompt_data.opts.model then
		return prompt_data.opts.model
	end
	return nil
end

function M.extract_tools_from_prompt(prompt_data)
	local tools = {}
	if not prompt_data.prompts then
		return tools
	end

	for _, prompt in ipairs(prompt_data.prompts) do
		if prompt.content then
			local content_text = M.get_prompt_content(prompt)
			-- Look for tool references like @{tool-name}
			for tool in content_text:gmatch("@{([^}]+)}") do
				if not vim.tbl_contains(tools, tool) then
					table.insert(tools, tool)
				end
			end
		end
	end

	return tools
end

-- Utility function to create a renderer that shows full current system prompt
function M.create_full_system_renderer()
	return function(_, _)
		local full_system = M.get_full_current_system_prompt()
		return full_system and ("## Current System Prompt\n\n" .. full_system) or nil
	end
end

return M