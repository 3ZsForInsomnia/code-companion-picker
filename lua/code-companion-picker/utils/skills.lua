local openskills = require("code-companion-picker.utils.skills_backends.openskills")
local skillport = require("code-companion-picker.utils.skills_backends.skillport")

local backends = {
	openskills = openskills,
	skillport = skillport,
}

local M = {}

local function get_backend()
	local config = require("code-companion-picker.config").get()
	local name = (config.skills and config.skills.backend) or "skillport"
	return backends[name]
end

function M.list()
	return get_backend().list()
end

function M.read(skill_name)
	return get_backend().read(skill_name)
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
