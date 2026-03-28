# 🚀 code-companion-picker.nvim

**Finally, a way to actually *browse* your [CodeCompanion](https://codecompanion.olimorris.dev/) prompts!**

Stop memorizing prompt names or hunting through files. This plugin gives you a beautiful, fast picker with rich markdown previews that shows you exactly what each prompt does before you use it. Think Telescope for files, but for your AI prompts.

**Perfect for:**
- 🤖 **AI power users** with large prompt libraries  
- 📝 **Prompt collectors** who want to actually *use* what they save
- ⚡ **Efficiency lovers** who prefer visual browsing over memorization
- 🎯 **Context switchers** who need different prompts for different tasks

## ✨ What You Get

- 🔍 **Lightning-fast fuzzy search** through your entire prompt library
- 📖 **Rich markdown previews** with syntax highlighting  
- 🎨 **Fully customizable preview rendering** - show exactly what you want to see
- ⚡ **Modern picker backends** - Snacks (recommended) or Telescope
- 🧠 **Smart prompt handling** - system prompts update context, user prompts add to chat
- 🔧 **Dynamic content support** - prompts that use your current selection and context
- 📋 **Multiple access methods** - commands, slash commands, or direct API calls

## Screenshots

*Coming soon - screenshots of the beautiful prompt previews and selection UI*

## Installation

### Requirements

- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) - Required
- One picker backend:
  - [snacks.nvim](https://github.com/folke/snacks.nvim) - Modern, fast ⭐ **Recommended**
  - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - ⚠️ **Deprecated**, will be removed in a future release

### With Snacks (Recommended)

```lua
{
  '3ZsForInsomnia/code-companion-picker',
  dependencies = { 'folke/snacks.nvim' },
  opts = {
    picker = "snacks",
  },
  keys = {
    { "<leader>cp", "<cmd>CodeCompanionPrompts<cr>", desc = "Browse CodeCompanion Prompts" },
  },
}
```

### With Telescope (⚠️ Deprecated)

> **Note:** Telescope support is deprecated and will be removed in a future release. Please use Snacks instead.

```lua
{
  '3ZsForInsomnia/code-companion-picker.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  opts = {
    picker = "telescope",
  },
  keys = {
    { "<leader>cp", "<cmd>CodeCompanionPrompts<cr>", desc = "Browse CodeCompanion Prompts" },
  },
}
```

### In-Chat Access

Add this to your CodeCompanion config for in-chat slash command access:

```lua
{
  strategies = {
    chat = {
      slash_commands = {
        prompts = require("code-companion-picker").select_slash_command,
      },
    },
  },
}
```

Then use `/prompts` in any CodeCompanion chat buffer to browse and insert prompts on the fly!

### How Prompts Work

When you select a prompt:
- **System prompts** → Updates your chat's system context
- **User prompts** → Adds content to chat as your message without submitting, so you can edit before sending
- **Mixed prompts** → Applies system context first, then adds user content
- **Model specified** → Automatically switches to the prompt's preferred model

## 🎨 Customizing Previews

Want to customize how prompt previews look? The plugin uses a **composable rendering system** where you can override individual sections or disable them entirely.

Quick example:

```lua
{
  renderers = {
    description = function(text, _)
      return text and ("📋 " .. text) or nil
    end,
    current_system = false, -- disable showing current system prompt
    model = function(model, _)
      return model and ("🤖 " .. model) or nil
    end,
  }
}
```

**📖 [See the full customization guide →](CUSTOMIZATION.md)**

The guide covers all 9 sections, advanced examples, and real-world configurations.

## ⚙️ Configuration

```lua
{
  '3ZsForInsomnia/code-companion-picker.nvim',
  opts = {
    picker = "snacks", -- "snacks" or "telescope"
    highlights = {
      -- Customize syntax highlighting colors
      yaml_key = { fg = "#79dac8", bold = true },
      yaml_description = { fg = "#ff9e64" },
      yaml_model = { fg = "#9d7cd8" },
      system_header = { fg = "#f7768e", bold = true },
      user_header = { fg = "#9ece6a", bold = true },
      -- ... see source for all options
    },
    renderers = {
      -- Customize how each section is rendered in the preview
      description = function(text, _)
        return text and ("📋 **Description:** " .. text) or nil
      end,
      model = function(model, _)
        return model and ("🤖 **Model:** " .. model) or nil
      end,
      tools = function(tools_array, _)
        return (#tools_array > 0) and ("🔧 **Tools:** " .. table.concat(tools_array, ", ")) or nil
      end,
      current_system = false, -- Disable showing current system prompt
      -- Override other sections: opts, mode, context, system_prompt, user_prompt
    },
  }
}
```

## 🔗 Related Plugin

**Got VS Code prompts?** Check out **[vs-code-companion](https://github.com/3ZsForInsomnia/vs-code-companion)** - easily import your VS Code style prompts into CodeCompanion format. Perfect for migrating existing prompt libraries or sharing prompts between VS Code and Neovim!

## 🛠️ Extending the Plugin

### Public API

The plugin exposes several functions for custom integrations:

```lua
local picker = require("code-companion-picker")

-- Get all prompts from CodeCompanion's prompt library
local prompts = picker.get_codecompanion_prompts()

-- Create display text for a prompt
local display = picker.create_prompt_display_text(prompt_info)

-- Convert prompt to markdown with custom renderers
local markdown = picker.codecompanion_to_markdown(prompt_data, prompt_name, custom_renderers)

-- Apply syntax highlighting to buffer
picker.apply_markdown_highlighting(bufnr, lines, highlights)
```

### Custom Picker Integration

To add support for a new picker backend:

```lua
local picker = require("code-companion-picker")
local handlers = require("code-companion-picker.ui.handlers")

-- Get prompts
local prompts = picker.get_codecompanion_prompts()

-- Create your picker UI with the prompts
-- When user selects a prompt, call:
handlers.handle_prompt_selection(selected_prompt_info)
```

The `handle_prompt_selection` function handles all the complexity of applying prompts correctly based on their type and content.

---

**Happy prompting!** 🚀

## TODO

- [ ] Extract `get_or_open_chat` pattern from `skill_handlers.lua` into `chat_utils` and reuse in `handlers.lua` and `tool_handlers.lua`
- [ ] Remove redundant snacks availability checks — `ui/pickers.lua` guards duplicate what `snacks_utils.lua` already checks
- [ ] Remove telescope support entirely
