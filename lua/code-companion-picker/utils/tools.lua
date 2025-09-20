local M = {}

-- Get codecompanion tools and convert to our format
function M.get_codecompanion_tools_info()
  local tools_info = {}
  
  local ok, codecompanion_config = pcall(require, "codecompanion.config")
  if not ok then
    return tools_info
  end
  
  local chat_config = codecompanion_config and codecompanion_config.config and 
                     codecompanion_config.config.strategies and 
                     codecompanion_config.config.strategies.chat
  local tools = chat_config and chat_config.tools
  
  if not tools or type(tools) ~= "table" then
    return tools_info
  end
  
  for name, tool_data in pairs(tools) do
    if type(tool_data) ~= "table" then
      goto continue
    end
    
    -- Only show visible tools
    if tool_data.visible == false then
      goto continue
    end
    
    local info = {
      name = name,
      display_name = M.create_display_name(name),
      description = tool_data.description or "No description available",
      tool_data = tool_data,
      source = "codecompanion",
    }
    table.insert(tools_info, info)
    
    ::continue::
  end
  
  return tools_info
end

function M.create_display_name(tool_name)
  if not tool_name then
    return "Unknown Tool"
  end
  
  -- Handle double underscore separation (group__specific_tool_name)
  local group_part, specific_part = tool_name:match("^(.-)__(.+)$")
  
  if group_part and specific_part then
    -- Clean up the group part
    local clean_group = M.clean_name_part(group_part)
    -- Clean up the specific part
    local clean_specific = M.clean_name_part(specific_part)
    
    return "[" .. clean_group .. "] " .. clean_specific
  else
    -- No double underscore, just clean the whole name
    return M.clean_name_part(tool_name)
  end
end

function M.clean_name_part(name_part)
  if not name_part then
    return ""
  end
  
  -- Replace underscores with spaces
  local cleaned = name_part:gsub("_", " ")
  
  -- Split camelCase words by inserting spaces before uppercase letters
  cleaned = cleaned:gsub("(%l)(%u)", "%1 %2")
  
  -- Title case each word
  cleaned = cleaned:gsub("(%w)(%w*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
  
  -- Special case: always uppercase MCP
  cleaned = cleaned:gsub("Mcp", "MCP")
  
  return cleaned
end

function M.create_display_text(tool_info)
  if not tool_info then
    return "Unknown Tool"
  end
  
  local display_name = tool_info.display_name or M.create_display_name(tool_info.name)
  
  -- Just return the display name - description will be handled by the picker formatting
  return display_name
end

-- Convert tool data to markdown for preview
function M.tool_to_markdown(tool_info)
  if not tool_info or not tool_info.tool_data then
    return "# Tool Information\n\nNo tool data available."
  end
  
  local tool_data = tool_info.tool_data
  local lines = {}
  
  -- Title
  table.insert(lines, "# " .. (tool_info.display_name or tool_info.name or "Unknown Tool"))
  table.insert(lines, "")
  
  -- Description
  if tool_info.description and tool_info.description ~= "" then
    table.insert(lines, "## Description")
    table.insert(lines, "")
    table.insert(lines, tool_info.description)
    table.insert(lines, "")
  end
  
  -- Schema information
  local schema = tool_data.callback and tool_data.callback.schema
  if schema and schema["function"] then
    local func_schema = schema["function"]
    
    -- Function name
    if func_schema.name then
      table.insert(lines, "## Function Name")
      table.insert(lines, "")
      table.insert(lines, "`" .. func_schema.name .. "`")
      table.insert(lines, "")
    end
    
    -- Function description (if different from main description)
    if func_schema.description and func_schema.description ~= tool_info.description then
      table.insert(lines, "## Function Description")
      table.insert(lines, "")
      table.insert(lines, func_schema.description)
      table.insert(lines, "")
    end
    
    -- Parameters
    local params = func_schema.parameters
    if params and params.properties then
      table.insert(lines, "## Parameters")
      table.insert(lines, "")
      
      local required_params = params.required or {}
      local required_set = {}
      for _, req in ipairs(required_params) do
        required_set[req] = true
      end
      
      for param_name, param_info in pairs(params.properties) do
        local is_required = required_set[param_name]
        local required_mark = is_required and " (required)" or " (optional)"
        
        table.insert(lines, "### " .. param_name .. required_mark)
        table.insert(lines, "")
        
        if param_info.type then
          table.insert(lines, "**Type:** `" .. param_info.type .. "`")
        end
        
        if param_info.description then
          table.insert(lines, "")
          table.insert(lines, param_info.description)
        end
        
        if param_info.enum then
          table.insert(lines, "")
          table.insert(lines, "**Allowed values:** " .. table.concat(param_info.enum, ", "))
        end
        
        table.insert(lines, "")
      end
    end
  end
  
  -- Tool ID (if available)
  if tool_data.id then
    table.insert(lines, "## Tool ID")
    table.insert(lines, "")
    table.insert(lines, "`" .. tool_data.id .. "`")
    table.insert(lines, "")
  end
  
  return table.concat(lines, "\n")
end

return M