local M = {}

local folders_by_name = {}

local function run_list()
	local output = vim.fn.system("skillz list -j 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		return nil, output
	end

	local ok, decoded = pcall(vim.json.decode, output)
	if not ok then
		return nil, output
	end
	return decoded, nil
end

local function to_skill(entry)
	return {
		name = entry.name,
		description = entry.description or "",
		location = entry.namespace ~= "" and entry.namespace or nil,
	}
end

local function strip_frontmatter(lines)
	local i = 1
	if lines[i] == "---" then
		i = i + 1
		while i <= #lines and lines[i] ~= "---" do
			i = i + 1
		end
		i = i + 1
	end
	while i <= #lines and lines[i] == "" do
		i = i + 1
	end
	return table.concat(lines, "\n", i)
end

function M.list()
	local entries, err = run_list()
	if not entries then
		vim.notify("code-companion-picker: Failed to run skillz list\n" .. (err or ""), vim.log.levels.ERROR)
		return {}
	end

	local skills = {}
	folders_by_name = {}
	for _, entry in ipairs(entries) do
		local has_folder = entry.path ~= vim.NIL and entry.path ~= nil
		if has_folder then
			folders_by_name[entry.name] = entry.path
			table.insert(skills, to_skill(entry))
		end
	end
	return skills
end

function M.read(skill_name)
	if not folders_by_name[skill_name] then
		M.list()
	end

	local folder = folders_by_name[skill_name]
	local skill_file = folder and (folder .. "/SKILL.md")
	if not skill_file or vim.fn.filereadable(skill_file) == 0 then
		return nil
	end

	return {
		body = strip_frontmatter(vim.fn.readfile(skill_file)),
		folder = folder,
	}
end

return M
