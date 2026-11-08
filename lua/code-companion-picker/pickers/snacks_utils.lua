local M = {}

--- Validate that snacks.picker is available. Returns snacks module or nil.
function M.require_snacks_picker()
	local has_snacks, snacks = pcall(require, "snacks")
	if not has_snacks or not snacks.picker then
		vim.notify("code-companion-picker: snacks.picker not available", vim.log.levels.ERROR)
		return nil
	end
	return snacks
end

--- Build highlighted display line: [name] - description
--- Accepts optional middle segments between name and description.
---@param name string
---@param description string|nil
---@param middle_segments {text: string, hl: string}[]|nil
---@return {[1]: string, [2]: string}[]
function M.format_bracketed_entry(name, description, middle_segments)
	local highlights = {}

	table.insert(highlights, { "[", "Comment" })
	table.insert(highlights, { name, "Function" })
	table.insert(highlights, { "]", "Comment" })

	if middle_segments then
		for _, seg in ipairs(middle_segments) do
			table.insert(highlights, { seg.text, seg.hl })
		end
	end

	if description and description ~= "" then
		table.insert(highlights, { " - ", "Comment" })
		table.insert(highlights, { description, "String" })
	end

	return highlights
end

--- Show a snacks picker with standard boilerplate.
---@param opts { items: table[], title: string, format: function, preview: any, data_key: string, confirm_handler: function }
---@return boolean
function M.show_picker(opts)
	local snacks = M.require_snacks_picker()
	if not snacks then
		return false
	end

	if #opts.items == 0 then
		vim.notify("code-companion-picker: No items available for " .. opts.title, vim.log.levels.WARN)
		return false
	end

	local ok, err = pcall(snacks.picker.pick, {
		items = opts.items,
		title = opts.title,
		format = opts.format,
		preview = opts.preview,
		-- Return focus to the window the picker was opened from. By default snacks
		-- skips non-file buffers like the CodeCompanion chat when restoring focus.
		main = { current = true },
		confirm = function(picker, item)
			picker:close()
			if item then
				opts.confirm_handler(item)
			end
		end,
	})

	if not ok then
		vim.notify("code-companion-picker: Error showing " .. opts.title .. ": " .. tostring(err), vim.log.levels.ERROR)
		return false
	end

	return true
end

return M
