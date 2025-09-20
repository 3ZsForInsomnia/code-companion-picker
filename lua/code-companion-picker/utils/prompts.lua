local M = {}

-- Get codecompanion prompts and convert to our format
function M.get_codecompanion_prompts_info()
  local prompts_info = {}
  
  local ok, codecompanion_config = pcall(require, "codecompanion.config")
  if not ok then
    return prompts_info
  end
  
  local prompt_library = codecompanion_config and codecompanion_config.prompt_library
  if not prompt_library or type(prompt_library) ~= "table" then
    return prompts_info
  end
  
  local markdown_converter = require("code-companion-picker.utils.markdown_converter")
  
  for name, prompt_data in pairs(prompt_library) do
    if type(prompt_data) ~= "table" then
      goto continue
    end
    
    local info = {
      name = name,
      filename = name, -- Use name as filename for consistency
      frontmatter = {
        description = prompt_data.description,
        model = markdown_converter.extract_model_from_prompt(prompt_data),
        tools = markdown_converter.extract_tools_from_prompt(prompt_data),
      },
      content = M.convert_prompts_to_content(prompt_data.prompts or {}),
      raw_content = markdown_converter.codecompanion_to_markdown(prompt_data, name),
      filepath = nil, -- No file path for codecompanion prompts
      prompt_data = prompt_data, -- Store original data for later use
      source = "codecompanion",
    }
    table.insert(prompts_info, info)
    
    ::continue::
  end
  
  return prompts_info
end

-- Convert codecompanion prompts array to a single content string
function M.convert_prompts_to_content(prompts)
  local content_parts = {}
  local markdown_converter = require("code-companion-picker.utils.markdown_converter")
  
  for i, prompt in ipairs(prompts) do
    if prompt.role == "user" then
      table.insert(content_parts, markdown_converter.safe_get_prompt_content(prompt))
    end
  end
  
  return table.concat(content_parts, "\n\n")
end

-- Convert filename to human-readable display name
-- e.g. "golang.chatmode.md" -> "Golang Chatmode"
function M.englishify_filename(filename)
  if not filename then
    return "Unknown"
  end
  
  -- Remove .md extension
  local name = filename:gsub("%.md$", "")
  
  -- Replace dots, dashes, underscores with spaces
  name = name:gsub("[._-]", " ")
  
  -- Title case each word
  name = name:gsub("(%w)(%w*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
  
  return name
end

-- Create display text for prompts (shared between different pickers)
function M.create_display_text(prompt_info)
  local display_name
  
  -- Check if it's an imported vs-code prompt
  local name = prompt_info.name or "Unknown"
  if name:match("^vsc_") then
    -- This is an imported vs-code prompt, englishify it
    local clean_name = name:gsub("^vsc_", "")
    display_name = M.englishify_filename(clean_name)
  else
    -- This is a native codecompanion prompt, use as-is
    display_name = name
  end
  
  local description = prompt_info.frontmatter and prompt_info.frontmatter.description
  
  if description then
    return display_name .. " - " .. description
  else
    return display_name
  end
end

return M