local M = {}
function M.get_prompt_content(prompt)
  if not prompt then
    return ""
  end
  
  local content = prompt.content
  
  -- Handle case where content is nil
  if content == nil then
    return ""
  end
  
  -- Handle case where content is a function
  if type(content) == "function" then
    -- CodeCompanion content functions expect a context parameter
    local context = M.create_context()
    local ok, result = pcall(content, context)
    if ok and type(result) == "string" then
      return result
    elseif ok then
      return tostring(result or "")
    else
      -- Function call failed
      return "Error: Failed to execute content function: " .. tostring(result)
    end
  end
  
  -- Handle case where content is a string
  if type(content) == "string" then
    return content
  end
  
  -- Handle other types
  return tostring(content)
end
function M.create_context()
  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local is_codecompanion_buf = vim.bo[bufnr].filetype == "codecompanion"
  
  -- Get current selection if any
  local selection = ""
  local start_pos = { 1, 1 }
  local end_pos = { 1, 1 }
  
  -- If we're in a CodeCompanion buffer, we might want to get context from the main editor
  local target_bufnr = bufnr
  if is_codecompanion_buf then
    -- Try to find the previous non-codecompanion buffer
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype ~= "codecompanion" and vim.bo[buf].buflisted then
        target_bufnr = buf
        break
      end
    end
  end
  
  -- Get filetype and filename from target buffer
  local filetype = vim.bo[target_bufnr].filetype
  local filename = vim.api.nvim_buf_get_name(target_bufnr)
  
  -- Try to get visual selection
  local mode = vim.fn.mode()
  if not is_codecompanion_buf and (mode == "v" or mode == "V" or mode == "\22") then -- \22 is Ctrl-V
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    local start_col = vim.fn.col("'<")
    local end_col = vim.fn.col("'>")
    
    start_pos = { start_line or 1, start_col or 1 }
    end_pos = { end_line or 1, end_col or 1 }
    
    if start_line and end_line then
      local lines = vim.api.nvim_buf_get_lines(target_bufnr, start_line - 1, end_line, false)
      if #lines > 0 then
        -- Handle different selection modes
        if mode == "V" then
          -- Line-wise selection
          selection = table.concat(lines, "\n")
        else
          -- Character-wise selection
          if #lines == 1 then
            selection = lines[1]:sub(start_col, end_col)
          else
            lines[1] = lines[1]:sub(start_col)
            lines[#lines] = lines[#lines]:sub(1, end_col)
            selection = table.concat(lines, "\n")
          end
        end
      end
    end
  else
    -- No visual selection, use cursor position
    local cursor_line = is_codecompanion_buf and 1 or vim.fn.line(".")
    local cursor_col = is_codecompanion_buf and 1 or vim.fn.col(".")
    start_pos = { cursor_line, cursor_col }
    end_pos = { cursor_line, cursor_col }
  end
  
  -- If no visual selection, try to get the current line or word
  if selection == "" then
    local cursor_line = is_codecompanion_buf and 1 or vim.fn.line(".")
    local lines = vim.api.nvim_buf_get_lines(target_bufnr, cursor_line - 1, cursor_line, false)
    if #lines > 0 then
      selection = lines[1]
    end
  end
  
  -- Create context object that matches CodeCompanion's expected structure
  local context = {
    bufnr = target_bufnr,
    winnr = winnr,
    filename = filename,
    filetype = filetype,
    selection = selection,
    -- Position information that CodeCompanion expects
    start_pos = { tonumber(start_pos[1]) or 1, tonumber(start_pos[2]) or 1 },
    end_pos = { tonumber(end_pos[1]) or 1, tonumber(end_pos[2]) or 1 },
    -- Range for compatibility
    range = {
      start = { tonumber(start_pos[1]) or 1, (tonumber(start_pos[2]) or 1) - 1 }, -- Convert to 0-based for range
      ["end"] = { tonumber(end_pos[1]) or 1, (tonumber(end_pos[2]) or 1) - 1 }
    },
    -- Args that CodeCompanion templates expect
    args = {
      selection = selection,
      filetype = filetype,
      filename = vim.fn.fnamemodify(filename, ":t"), -- just the filename without path
      -- Add more args that CodeCompanion might expect
      line_count = tonumber(vim.api.nvim_buf_line_count(target_bufnr)) or 1,
      cursor_line = tonumber(is_codecompanion_buf and 1 or vim.fn.line(".")) or 1,
      cursor_col = tonumber(is_codecompanion_buf and 1 or vim.fn.col(".")) or 1,
    }
  }
  
  return context
end

function M.create_preview_context()
  local context = {
    bufnr = 0,
    winnr = 0,
    filename = "/path/to/current/file.lua",
    filetype = "lua",
    selection = "{{selected_text}}",
    start_pos = { 1, 1 },
    end_pos = { 1, 1 },
    range = {
      start = { 1, 0 },
      ["end"] = { 1, 0 }
    },
    args = {
      selection = "{{selected_text}}",
      filetype = "{{filetype}}",
      filename = "{{filename}}",
      line_count = 100,
      cursor_line = 1,
      cursor_col = 1,
    }
  }
  
  return context
end

function M.get_template_content(prompt)
  -- Try to extract template from the prompt if it has one
  if prompt and prompt.content and type(prompt.content) == "function" then
    -- Return a generic template message
    return "{{dynamic_content}} - This prompt generates content based on your current context"
  end
  
  return "Content not available for preview"
end

-- Get a preview-friendly template for function content
function M.get_preview_template_content(prompt)
  if prompt and prompt.content and type(prompt.content) == "function" then
    return "🔧 **Dynamic Prompt Function**\n\n" ..
           "This prompt generates content based on your current context:\n" ..
           "- Current file type\n" ..
           "- Selected text or current line\n" ..
           "- File name and path\n\n" ..
           "_The actual content will be generated when you select this prompt._\n\n" ..
           "**Template Variables:**\n" ..
           "- `{{selection}}` - Your selected text\n" ..
           "- `{{filetype}}` - Current file type\n" ..
           "- `{{filename}}` - Current file name"
  end
  
  return "Content not available for preview"
end

-- Wrapper function that adds error handling
local function safe_get_prompt_content(prompt)
  local ok, result = pcall(M.get_prompt_content, prompt)
  if ok then
    return result
  else
    return "Error extracting content: " .. tostring(result)
  end
end

-- Use the safe wrapper in the markdown converter
function M.safe_get_prompt_content(prompt)
  return safe_get_prompt_content(prompt)
end

-- Convert codecompanion prompt to markdown with YAML frontmatter
-- This is exposed as a public utility function
function M.codecompanion_to_markdown(prompt_data, prompt_name)
  if not prompt_data or type(prompt_data) ~= "table" then
    return ""
  end
  
  local lines = {}
  
  -- Add frontmatter
  table.insert(lines, "---")
  
  if prompt_data.description then
    table.insert(lines, "description: " .. prompt_data.description)
  end
  
  local model = M.extract_model_from_prompt(prompt_data)
  if model then
    table.insert(lines, "model: " .. model)
  end
  
  local tools = M.extract_tools_from_prompt(prompt_data)
  if #tools > 0 then
    table.insert(lines, "tools: [" .. table.concat(tools, ", ") .. "]")
  end
  
  table.insert(lines, "---")
  table.insert(lines, "")
  
  -- Add prompts content
  if prompt_data.prompts then
    for i, prompt in ipairs(prompt_data.prompts) do
      table.insert(lines, "## Message " .. i .. " (" .. (prompt.role or "unknown") .. ")")
      table.insert(lines, "")
      table.insert(lines, M.safe_get_prompt_content(prompt))
      table.insert(lines, "")
    end
  end
  
  return table.concat(lines, "\n")
end

-- Extract model information from codecompanion prompt
function M.extract_model_from_prompt(prompt_data)
  if prompt_data.opts and prompt_data.opts.adapter then
    if type(prompt_data.opts.adapter) == "string" then
      return prompt_data.opts.adapter
    elseif type(prompt_data.opts.adapter) == "table" and prompt_data.opts.adapter.model then
      return prompt_data.opts.adapter.model
    end
  end
  if prompt_data.opts and prompt_data.opts.model then
    return prompt_data.opts.model
  end
  return nil
end

-- Extract tool references from prompt content
function M.extract_tools_from_prompt(prompt_data)
  local tools = {}
  if not prompt_data.prompts then
    return tools
  end
  
  for _, prompt in ipairs(prompt_data.prompts) do
    if prompt.content then
      local content_text = M.get_prompt_content(prompt)
      -- Look for tool references like @{tool-name}
      for tool in content_text:gmatch("@{([^}]+)}") do
        if not vim.tbl_contains(tools, tool) then
          table.insert(tools, tool)
        end
      end
    end
  end
  
  return tools
end

return M