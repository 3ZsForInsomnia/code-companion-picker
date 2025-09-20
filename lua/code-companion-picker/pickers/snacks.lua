local M = {}

function M.show_picker(prompts_info, selection_handler)
	local snacks = require("snacks")

	if not snacks.picker then
		vim.notify("code-companion-picker: snacks.picker not available", vim.log.levels.ERROR)
		return false
	end

	local prompts_util = require("code-companion-picker.utils.prompts")

	-- Check if we have prompts
	if #prompts_info == 0 then
		vim.notify("code-companion-picker: No prompts available", vim.log.levels.WARN)
		return false
	end

	-- Convert prompts_info to items with proper text field for Snacks picker
	local items = {}
	for i, prompt_info in ipairs(prompts_info) do
		local display_text = prompts_util.create_display_text(prompt_info)

		-- Generate preview content
		local markdown_converter = require("code-companion-picker.utils.markdown_converter")
		local preview_content = markdown_converter.codecompanion_to_markdown(prompt_info.prompt_data, prompt_info.name, {})

		table.insert(items, {
			text = display_text,
			-- Store the original data in the item for use in preview and confirm
			prompt_info = prompt_info,
			idx = i,
			preview = {
				text = preview_content,
				ft = "markdown"
			}
		})
	end

	-- Debug: Check items were created
	if #items == 0 then
		vim.notify("code-companion-picker: No items created from prompts", vim.log.levels.WARN)
		return false
	end

	-- Show picker with custom preview
	local ok, err = pcall(snacks.picker.pick, {
		items = items,
		title = "CodeCompanion Prompts",
		format = M.create_format_function(),
		preview = "preview", -- Use built-in preview with item.preview.text
		confirm = function(picker, item)
			picker:close()
			if item and item.prompt_info then
				selection_handler(item.prompt_info)
			end
		end,
	})

	if not ok then
		vim.notify("code-companion-picker: Error showing picker: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

-- Create a custom format function for colored display
function M.create_format_function()
	return function(item)
		if not item.prompt_info then
			return { { item.text or "Unknown", "Normal" } }
		end

		local prompt_info = item.prompt_info
		local name = prompt_info.name or "Unknown"
		local description = prompt_info.frontmatter and prompt_info.frontmatter.description

		-- Check if it's an imported vs-code prompt
		local display_name
		if name:match("^vsc_") then
			local clean_name = name:gsub("^vsc_", "")
			local prompts_util = require("code-companion-picker.utils.prompts")
			display_name = prompts_util.englishify_filename(clean_name)
		else
			display_name = name
		end

		local highlights = {}

		-- Add the prompt name in brackets with a distinct color
		table.insert(highlights, { "[", "Comment" })
		table.insert(highlights, { display_name, "Function" }) -- Use Function highlight for prompt names
		table.insert(highlights, { "]: ", "Comment" })

		-- Add description with a different color
		if description then
			table.insert(highlights, { description, "String" }) -- Use String highlight for descriptions
		end

		return highlights
	end
end

function M.show_tool_picker(tools_info, selection_handler)
	local snacks = require("snacks")

	if not snacks.picker then
		vim.notify("code-companion-picker: snacks.picker not available", vim.log.levels.ERROR)
		return false
	end

	local tools_util = require("code-companion-picker.utils.tools")

	-- Check if we have tools
	if #tools_info == 0 then
		vim.notify("code-companion-picker: No tools available", vim.log.levels.WARN)
		return false
	end

	-- Convert tools_info to items with proper text field for Snacks picker
	local items = {}
	for i, tool_info in ipairs(tools_info) do
		local display_text = tools_util.create_display_text(tool_info)

		-- Generate preview content
		local preview_content = tools_util.tool_to_markdown(tool_info)

		table.insert(items, {
			text = display_text,
			-- Store the original data in the item for use in preview and confirm
			tool_info = tool_info,
			idx = i,
			preview = {
				text = preview_content,
				ft = "markdown"
			}
		})
	end

	-- Debug: Check items were created
	if #items == 0 then
		vim.notify("code-companion-picker: No items created from tools", vim.log.levels.WARN)
		return false
	end

	-- Show picker with custom preview
	local ok, err = pcall(snacks.picker.pick, {
		items = items,
		title = "CodeCompanion Tools",
		format = M.create_tool_format_function(),
		preview = "preview", -- Use built-in preview with item.preview.text
		confirm = function(picker, item)
			picker:close()
			if item and item.tool_info then
				selection_handler(item.tool_info)
			end
		end,
	})

	if not ok then
		vim.notify("code-companion-picker: Failed to show Snacks picker: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

function M.create_tool_format_function()
	return function(item)
		if not item.tool_info then
			return { { item.text or "Unknown", "Normal" } }
		end

		local tool_info = item.tool_info
		local name = tool_info.name or "Unknown"
		local description = tool_info.description
		local display_name = tool_info.display_name or name

		local highlights = {}

		-- Parse the display name to highlight group and tool name separately
		local group_part, tool_part = display_name:match("^%[(.-)%] (.+)$")
		
		if group_part and tool_part then
			-- Format: [Group] Tool Name
			table.insert(highlights, { "[", "Comment" })
			table.insert(highlights, { group_part, "Identifier" }) -- Use Identifier for group names
			table.insert(highlights, { "] ", "Comment" })
			table.insert(highlights, { tool_part, "Function" }) -- Use Function for tool names
		else
			-- Format: Tool Name (no group)
			table.insert(highlights, { display_name, "Function" })
		end

		-- Add description with a different color
		if description and description ~= "" and description ~= "No description available" then
			table.insert(highlights, { " - ", "Comment" })
			table.insert(highlights, { description, "String" }) -- Use String highlight for descriptions
		else
			table.insert(highlights, { "No description", "Comment" })
		end

		return highlights
	end
end

return M
