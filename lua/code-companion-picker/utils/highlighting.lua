local M = {}

-- Apply syntax highlighting to a markdown buffer with YAML frontmatter
function M.apply_markdown_highlighting(bufnr, lines, config_highlights)
  local ns_id = vim.api.nvim_create_namespace("code_companion_picker_preview")
  
  -- Define highlight groups using configurable colors
  local highlights = {
    CCPickerYamlKey = config_highlights.yaml_key,
    CCPickerYamlDescription = config_highlights.yaml_description,
    CCPickerYamlModel = config_highlights.yaml_model,
    CCPickerYamlTools = config_highlights.yaml_tools,
    CCPickerYamlValue = config_highlights.yaml_value, -- fallback for other properties
    CCPickerSystemHeader = config_highlights.system_header,
    CCPickerUserHeader = config_highlights.user_header,
    CCPickerSystemContent = config_highlights.system_content,
    CCPickerUserContent = config_highlights.user_content,
  }
  
  -- Create highlight groups
  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
  
  local in_frontmatter = false
  local current_role = nil
  
  for i, line in ipairs(lines) do
    local line_idx = i - 1
    
    -- Handle frontmatter
    if line == "---" then
      in_frontmatter = not in_frontmatter
    elseif in_frontmatter and line:match("^%s*%w+%s*:") then
      -- Highlight yaml key-value pairs with specific colors per property
      local key_start, key_end = line:find("^%s*%w+")
      local key = line:match("^%s*(%w+)")
      
      if key_start then
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CCPickerYamlKey", line_idx, key_start - 1, key_end)
      end
      
      local value_start = line:find(":%s*")
      if value_start then
        -- Use specific colors for different YAML properties
        local highlight_group = "CCPickerYamlValue" -- default
        if key == "description" then
          highlight_group = "CCPickerYamlDescription"
        elseif key == "model" then
          highlight_group = "CCPickerYamlModel"
        elseif key == "tools" then
          highlight_group = "CCPickerYamlTools"
        end
        
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, highlight_group, line_idx, value_start + 1, -1)
      end
    -- Handle message headers
    elseif line:match("^## Message %d+ %(") then
      local role = line:match("%((%w+)%)")
      current_role = role
      
      if role == "system" then
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CCPickerSystemHeader", line_idx, 0, -1)
      elseif role == "user" then
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CCPickerUserHeader", line_idx, 0, -1)
      end
    -- Handle content based on current role
    elseif current_role and line ~= "" and not line:match("^#") then
      if current_role == "system" then
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CCPickerSystemContent", line_idx, 0, -1)
      elseif current_role == "user" then
        vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CCPickerUserContent", line_idx, 0, -1)
      end
    end
  end
end

return M