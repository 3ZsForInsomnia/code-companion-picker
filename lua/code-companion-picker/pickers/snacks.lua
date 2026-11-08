local snacks_utils = require("code-companion-picker.pickers.snacks_utils")

local M = {}

local function build_prompt_items(prompts_info)
	local prompts_util = require("code-companion-picker.utils.prompts")
	local markdown_converter = require("code-companion-picker.utils.markdown_converter")

	local items = {}
	for i, prompt_info in ipairs(prompts_info) do
		table.insert(items, {
			text = prompts_util.create_display_text(prompt_info),
			prompt_info = prompt_info,
			idx = i,
			preview = {
				text = markdown_converter.codecompanion_to_markdown(prompt_info.prompt_data, prompt_info.name, {}),
				ft = "markdown",
			},
		})
	end
	return items
end

local function format_prompt(item)
	if not item.prompt_info then
		return { { item.text or "Unknown", "Normal" } }
	end

	local prompt_info = item.prompt_info
	local name = prompt_info.name or "Unknown"

	if name:match("^vsc_") then
		local prompts_util = require("code-companion-picker.utils.prompts")
		name = prompts_util.englishify_filename(name:gsub("^vsc_", ""))
	end

	local description = prompt_info.frontmatter and prompt_info.frontmatter.description
	return snacks_utils.format_bracketed_entry(name, description)
end

function M.show_picker(prompts_info, selection_handler)
	return snacks_utils.show_picker({
		items = build_prompt_items(prompts_info),
		title = "CodeCompanion Prompts",
		format = function(item) return format_prompt(item) end,
		preview = "preview",
		confirm_handler = function(item)
			if item.prompt_info then
				selection_handler(item.prompt_info)
			end
		end,
	})
end

local function build_tool_items(tools_info)
	local tools_util = require("code-companion-picker.utils.tools")

	local items = {}
	for i, tool_info in ipairs(tools_info) do
		table.insert(items, {
			text = tools_util.create_display_text(tool_info),
			tool_info = tool_info,
			idx = i,
			preview = {
				text = tools_util.tool_to_markdown(tool_info),
				ft = "markdown",
			},
		})
	end
	return items
end

local function format_tool(item)
	if not item.tool_info then
		return { { item.text or "Unknown", "Normal" } }
	end

	local tool_info = item.tool_info
	local display_name = tool_info.display_name or tool_info.name or "Unknown"
	local description = tool_info.description

	local group_part, tool_part = display_name:match("^%[(.-)%] (.+)$")

	if group_part and tool_part then
		local middle = {
			{ text = " (", hl = "Comment" },
			{ text = group_part, hl = "Identifier" },
			{ text = ")", hl = "Comment" },
		}
		local has_description = description and description ~= "" and description ~= "No description available"
		return snacks_utils.format_bracketed_entry(tool_part, has_description and description or nil, middle)
	end

	local has_description = description and description ~= "" and description ~= "No description available"
	return snacks_utils.format_bracketed_entry(display_name, has_description and description or nil)
end

function M.show_tool_picker(tools_info, selection_handler)
	return snacks_utils.show_picker({
		items = build_tool_items(tools_info),
		title = "CodeCompanion Tools",
		format = function(item) return format_tool(item) end,
		preview = "preview",
		confirm_handler = function(item)
			if item.tool_info then
				selection_handler(item.tool_info)
			end
		end,
	})
end

local function build_skill_items(skills_info)
	local skills_util = require("code-companion-picker.utils.skills")

	local items = {}
	for i, skill in ipairs(skills_info) do
		table.insert(items, {
			text = skills_util.create_display_text(skill),
			skill = skill,
			idx = i,
		})
	end
	return items
end

local function format_skill(item)
	if not item.skill then
		return { { item.text or "Unknown", "Normal" } }
	end

	local skill = item.skill
	local middle = skill.location and {
		{ text = " (", hl = "Comment" },
		{ text = skill.location, hl = "Identifier" },
		{ text = ")", hl = "Comment" },
	} or nil

	return snacks_utils.format_bracketed_entry(skill.name, skill.description, middle)
end

local function create_skill_preview()
	local skills_util = require("code-companion-picker.utils.skills")
	local cache = {}

	return function(ctx)
		local item = ctx.item
		if not item or not item.skill then
			return
		end

		local name = item.skill.name
		if not cache[name] then
			local skill = skills_util.read(name)
			cache[name] = skill and skill.body or "*Could not load skill content*"
		end

		vim.bo[ctx.buf].modifiable = true
		vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, vim.split(cache[name], "\n"))
		vim.bo[ctx.buf].modifiable = false
		vim.bo[ctx.buf].filetype = "markdown"
	end
end

function M.show_skill_picker(skills_info, selection_handler)
	return snacks_utils.show_picker({
		items = build_skill_items(skills_info),
		title = "CodeCompanion Skills",
		format = function(item) return format_skill(item) end,
		preview = create_skill_preview(),
		confirm_handler = function(item)
			if item.skill then
				selection_handler(item.skill)
			end
		end,
	})
end

return M
