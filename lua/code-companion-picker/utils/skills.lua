local openskills = require("code-companion-picker.utils.skills_backends.openskills")
local skillport = require("code-companion-picker.utils.skills_backends.skillport")
local skillz = require("code-companion-picker.utils.skills_backends.skillz")

local backends = {
	openskills = openskills,
	skillport = skillport,
	skillz = skillz,
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

---Read a skill's SKILL.md body (frontmatter stripped) and the folder it lives in
---@param skill_name string
---@return { body: string, folder?: string }|nil
function M.read(skill_name)
	return get_backend().read(skill_name)
end

local function build_framing(skill_name, folder)
	local intro = string.format(
		'The following are instructions from the skill "%s". Follow them for this conversation.',
		skill_name
	)
	if not folder then
		return intro
	end

	local folder_hint = string.format(
		"Files these instructions refer to are relative to the skill's folder: %s. "
			.. "Read them from there when the instructions call for them.",
		folder
	)

	return intro .. "\n" .. folder_hint
end

---Read a skill and wrap its body in framing that tells the model what it is and where its files live
---@param skill_name string
---@return string|nil
function M.read_framed(skill_name)
	local skill = M.read(skill_name)
	local has_body = skill and skill.body ~= ""
	if not has_body then
		return nil
	end

	return build_framing(skill_name, skill.folder) .. "\n\n" .. skill.body
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
		return content.body
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
