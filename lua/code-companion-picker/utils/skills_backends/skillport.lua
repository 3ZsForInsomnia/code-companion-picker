local M = {}

local function run_json(cmd)
	local output = vim.fn.system(cmd)
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
	-- SkillPort's `id` is the lookup key for `skillport show`; `name` is
	-- usually identical but `id` may include a namespace (e.g. `team/foo`).
	-- The plugin uses `skill.name` as both display text and lookup key, so
	-- we map `id` onto `name` to keep behavior identical across backends.
	return {
		name = entry.id or entry.name,
		description = entry.description or "",
		-- `location` intentionally omitted: SkillPort has no equivalent.
	}
end

function M.list()
	local data, err = run_json("skillport list --json 2>&1")
	if not data then
		vim.notify("code-companion-picker: Failed to run skillport list\n" .. (err or ""), vim.log.levels.ERROR)
		return {}
	end

	local skills = {}
	for _, entry in ipairs(data.skills or {}) do
		table.insert(skills, to_skill(entry))
	end
	return skills
end

function M.read(skill_id)
	local cmd = "skillport show " .. vim.fn.shellescape(skill_id) .. " --json 2>&1"
	local data = run_json(cmd)
	if not data then
		return nil
	end
	return {
		body = data.instructions,
		-- `path` is the skill's directory; empty when SkillPort doesn't report one
		folder = data.path ~= "" and data.path or nil,
	}
end

return M
