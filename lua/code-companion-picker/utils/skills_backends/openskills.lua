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

local function strip_preamble(output)
	local lines = vim.split(output, "\n")
	local i = 1
	local base_dir = nil

	-- Skip status lines, capture base directory
	while i <= #lines and (lines[i]:match("^Reading:") or lines[i]:match("^Base directory:") or lines[i] == "") do
		local dir = lines[i]:match("^Base directory:%s+(.+)")
		if dir then
			base_dir = dir
		end
		i = i + 1
	end

	-- Skip YAML frontmatter block
	if i <= #lines and lines[i] == "---" then
		i = i + 1
		while i <= #lines and lines[i] ~= "---" do
			i = i + 1
		end
		if i <= #lines then
			i = i + 1
		end
	end

	-- Skip any blank lines after frontmatter
	while i <= #lines and lines[i] == "" do
		i = i + 1
	end

	local body = table.concat(lines, "\n", i)

	if base_dir then
		return "Base directory: " .. base_dir .. "\n\n" .. body
	end
	return body
end

function M.read(skill_name)
	local output = vim.fn.system("openskills read " .. vim.fn.shellescape(skill_name) .. " 2>&1")
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return strip_preamble(output)
end

return M
