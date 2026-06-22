-- luacheck: globals vim
local M = {}

local function validate_config(user_config)
	if user_config.picker then
		local valid_pickers = { "snacks", "telescope" }
		if not vim.tbl_contains(valid_pickers, user_config.picker) then
			error("code-companion-picker: config.picker must be one of: " .. table.concat(valid_pickers, ", "))
		end
	end

	if user_config.highlights then
		if type(user_config.highlights) ~= "table" then
			error("code-companion-picker: config.highlights must be a table")
		end
	end

	if user_config.renderers then
		if type(user_config.renderers) ~= "table" then
			error("code-companion-picker: config.renderers must be a table")
		end
	end

	if user_config.skills then
		if type(user_config.skills) ~= "table" then
			error("code-companion-picker: config.skills must be a table")
		end
		if user_config.skills.backend then
			local valid_backends = { "skillport", "openskills" }
			if not vim.tbl_contains(valid_backends, user_config.skills.backend) then
				error(
					"code-companion-picker: config.skills.backend must be one of: "
						.. table.concat(valid_backends, ", ")
				)
			end
		end
	end
end

local default_config = {
	picker = "snacks", -- "snacks" or "telescope"
	skills = {
		backend = "skillport", -- "skillport" or "openskills"
	},
	highlights = {
		yaml_key = { fg = "#79dac8", bold = true }, -- cyan for yaml keys
		yaml_value = { fg = "#e39777" }, -- orange for yaml values
		yaml_description = { fg = "#ff9e64" }, -- orange for description values
		yaml_model = { fg = "#9d7cd8" }, -- purple for model values
		yaml_tools = { fg = "#73daca" }, -- teal for tools values
		system_header = { fg = "#f7768e", bold = true }, -- red for system headers
		user_header = { fg = "#9ece6a", bold = true }, -- green for user headers
		system_content = { fg = "#bb9af7" }, -- purple for system content
		user_content = { fg = "#7dcfff" }, -- blue for user content
	},
	renderers = {
		description = function(text, _)
			return text and ("**Description:** " .. text) or nil
		end,
		model = function(model, _)
			return model and ("**Model:** " .. model) or nil
		end,
		tools = function(tools_array, _)
			return (#tools_array > 0) and ("**Tools:** " .. table.concat(tools_array, ", ")) or nil
		end,
		opts = function(opts, _)
			if not opts then
				return nil
			end
			local parts = {}
			if opts.index then
				table.insert(parts, "index: " .. tostring(opts.index))
			end
			if opts.auto_submit then
				table.insert(parts, "auto_submit: " .. tostring(opts.auto_submit))
			end
			return (#parts > 0) and ("**Options:** " .. table.concat(parts, ", ")) or nil
		end,
		mode = function(mode_info, _)
			return mode_info and ("**Mode:** " .. mode_info) or nil
		end,
		context = function(context_info, _)
			return context_info and ("**Context:** " .. context_info) or nil
		end,
		current_system = function(system_text, _)
			return system_text and ("**Current System Prompt:** " .. system_text) or nil
		end,
		system_prompt = function(content, _)
			return content and ("## System Message\n\n" .. content) or nil
		end,
		user_prompt = function(content, _)
			return content and ("## User Message\n\n" .. content) or nil
		end,
	},
}

local config = default_config

function M.setup(user_config)
	user_config = user_config or {}
	validate_config(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config)
end

function M.get()
	return config
end

return M
