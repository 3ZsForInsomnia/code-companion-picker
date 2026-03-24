local M = {}

local function parse_skill_entry(name_line, description_line)
	local name, location = name_line:match("^%s+(%S+)%s+%((%w+)%)")
	if not name then
		return nil
	end

	local description = description_line and description_line:match("^%s+(.+)") or ""

	return {
		name = name,
		description = description,
		location = location,
	}
end

function M.list()
	local output = vim.fn.system("openskills list 2>&1")
	if vim.v.shell_error ~= 0 then
		vim.notify("code-companion-picker: Failed to run openskills list", vim.log.levels.ERROR)
		return {}
	end

	local lines = vim.split(output, "\n")
	local skills = {}
	local i = 1

	while i <= #lines do
		local line = lines[i]
		local is_name_line = line:match("^%s+%S+%s+%(%w+%)$")

		if is_name_line then
			local description_line = lines[i + 1]
			local skill = parse_skill_entry(line, description_line)
			if skill then
				table.insert(skills, skill)
				i = i + 2
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end

	return skills
end

local function strip_openskills_preamble(output)
	local lines = vim.split(output, "\n")
	local i = 1

	-- Skip status lines ("Reading: ...", "Base directory: ...", blank lines)
	while i <= #lines and (lines[i]:match("^Reading:") or lines[i]:match("^Base directory:") or lines[i] == "") do
		i = i + 1
	end

	-- Skip YAML frontmatter block
	if i <= #lines and lines[i] == "---" then
		i = i + 1
		while i <= #lines and lines[i] ~= "---" do
			i = i + 1
		end
		if i <= #lines then
			i = i + 1 -- skip closing ---
		end
	end

	-- Skip any blank lines after frontmatter
	while i <= #lines and lines[i] == "" do
		i = i + 1
	end

	return table.concat(lines, "\n", i)
end

function M.read(skill_name)
	local output = vim.fn.system("openskills read " .. vim.fn.shellescape(skill_name) .. " 2>&1")
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return strip_openskills_preamble(output)
end

function M.create_display_text(skill)
	if not skill then
		return "Unknown Skill"
	end

	local parts = { skill.name }
	if skill.description and skill.description ~= "" then
		table.insert(parts, " - " .. skill.description)
	end

	return table.concat(parts)
end

function M.skill_to_markdown(skill)
	if not skill then
		return "# Skill Information\n\nNo skill data available."
	end

	local content = M.read(skill.name)
	if content then
		return content
	end

	local lines = {
		"# " .. skill.name,
		"",
		skill.description or "No description available.",
		"",
		"*Could not load SKILL.md content*",
	}
	return table.concat(lines, "\n")
end

return M
