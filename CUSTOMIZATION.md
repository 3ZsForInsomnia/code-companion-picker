# 🎨 Customizing Preview Rendering

The heart of code-companion-picker is its **composable rendering system** that lets you customize exactly how prompt previews look. You can override individual sections, disable parts you don't want, or completely transform how information is displayed.

## How It Works

Instead of a monolithic preview generator, the plugin breaks prompt previews into **9 distinct sections** that are rendered in a fixed order. Each section has its own renderer function that you can customize or disable.

### The 9 Sections (in order)

1. **description** - The prompt's description text
2. **model** - Model/adapter information (e.g., "gpt-4", "claude-3-sonnet")
3. **tools** - Tool references found in prompt content (e.g., "@{file-browser}")
4. **opts** - CodeCompanion options like index, auto_submit, etc.
5. **mode** - Whether this is a System, User, or Mixed prompt
6. **context** - Files, URLs, etc. (reserved for future features)
7. **current_system** - Your current CodeCompanion system prompt (truncated)
8. **system_prompt** - System message content from this prompt *(conditional)*
9. **user_prompt** - User message content from this prompt *(conditional)*

**Conditional sections:** The last two sections only appear if the prompt actually contains that type of message.

## Renderer Function Signature

Every renderer follows the same pattern:

```lua
section_renderer = function(section_data, full_prompt_data) 
  return "markdown_string"  -- or nil to skip this section
end
```

- **section_data**: The specific data for this section (string, table, etc.)
- **full_prompt_data**: The complete prompt object (for advanced use cases)
- **return**: A markdown string to display, or `nil` to skip the section entirely

## Configuration

Add renderer customizations to your plugin config:

```lua
{
  '3ZsForInsomnia/code-companion-picker.nvim',
  opts = {
    picker = "snacks",
    renderers = {
      -- Your customizations here
    },
  },
}
```

## Examples

### Simple Customization

```lua
renderers = {
  -- Add emojis to make sections stand out
  description = function(text, _)
    return text and ("📋 **Description:** " .. text) or nil
  end,
  
  model = function(model, _)
    return model and ("🤖 **Model:** " .. model) or nil
  end,
  
  -- Disable a section completely
  current_system = false,
}
```

### Advanced Transformations

```lua
renderers = {
  -- Transform tools into clickable links
  tools = function(tools_array, _)
    if #tools_array == 0 then return nil end
    
    local tool_links = {}
    for _, tool in ipairs(tools_array) do
      table.insert(tool_links, "[" .. tool .. "](#)")
    end
    return "🔧 **Tools:** " .. table.concat(tool_links, " • ")
  end,
  
  -- Add context from the full prompt data
  mode = function(mode_info, prompt_data)
    local prompt_count = prompt_data.prompts and #prompt_data.prompts or 0
    return "📝 **Mode:** " .. (mode_info or "Unknown") .. 
           " (" .. prompt_count .. " messages)"
  end,
  
  -- Custom formatting for options
  opts = function(opts, _)
    if not opts then return nil end
    
    local parts = {}
    if opts.index then 
      table.insert(parts, "📍 Position: " .. opts.index) 
    end
    if opts.auto_submit then 
      table.insert(parts, "⚡ Auto-submit enabled") 
    end
    
    return (#parts > 0) and table.concat(parts, " | ") or nil
  end,
}
```

### Show Full System Prompt

By default, the `current_system` section shows a truncated version of your CodeCompanion system prompt (200 chars). Use this utility to show the full version:

```lua
renderers = {
  current_system = require("code-companion-picker.utils.markdown_converter").create_full_system_renderer(),
}
```

### Real-World Example: Clean & Focused

This config creates clean, focused previews perfect for quick scanning:

```lua
renderers = {
  -- Minimal description
  description = function(text, _)
    return text and ("**" .. text .. "**") or nil
  end,
  
  -- Highlighted model
  model = function(model, _)
    return model and ("`" .. model .. "`") or nil
  end,
  
  -- Hide clutter
  opts = false,
  current_system = false,
  mode = false,
  
  -- Streamlined content sections
  system_prompt = function(content, _)
    if not content then return nil end
    local preview = content:sub(1, 150) .. (content:len() > 150 and "..." or "")
    return "🔒 **System:** " .. preview
  end,
  
  user_prompt = function(content, _)
    if not content then return nil end
    local preview = content:sub(1, 200) .. (content:len() > 200 and "..." or "")
    return "💬 **Prompt:** " .. preview
  end,
}
```

## Design Principles

The rendering system follows these principles:

- **Fixed order**: Sections always appear in the same sequence for consistency
- **Conditional display**: Sections only show if they have relevant data
- **Override flexibility**: Customize any section without affecting others
- **No side effects**: Renderers are pure functions that just return strings
- **Fail gracefully**: If a renderer errors, the section is skipped

## Tips & Tricks

### Accessing Prompt Metadata

The `full_prompt_data` parameter gives you access to the complete prompt:

```lua
description = function(text, prompt_data)
  -- Access the full prompt structure
  local has_tools = prompt_data.prompts and 
    vim.tbl_some(prompt_data.prompts, function(p) 
      return p.content and p.content:match("@{[^}]+}") 
    end)
  
  local suffix = has_tools and " 🔧" or ""
  return text and (text .. suffix) or nil
end
```

### Conditional Styling

```lua
mode = function(mode_info, prompt_data)
  if not mode_info then return nil end
  
  local emoji = {
    System = "🔒",
    User = "💬", 
    Mixed = "🔀"
  }
  
  return (emoji[mode_info] or "📝") .. " **" .. mode_info .. "**"
end
```

### Debug What You're Getting

```lua
description = function(text, prompt_data)
  -- Temporarily see what data is available
  print("Section data:", vim.inspect(text))
  print("Full prompt:", vim.inspect(prompt_data))
  return text and ("**Description:** " .. text) or nil
end
```

That's the full power of the composable rendering system! Mix and match these techniques to create previews that work perfectly for your workflow.