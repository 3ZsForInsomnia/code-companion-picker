# code-companion-picker.nvim

A picker for [CodeCompanion](https://codecompanion.olimorris.dev/) prompts with beautiful markdown previews. Search and preview your CodeCompanion prompt library using Snacks Picker, Telescope, or vim.ui.select.

## Features

✅ **Browse CodeCompanion prompt library** with fuzzy search  
✅ **Beautiful markdown previews** with syntax highlighting  
✅ **Multiple picker backends**: Snacks Picker (default), Telescope, vim.ui.select  
✅ **Smart prompt handling**: Correctly applies system vs user prompts  
✅ **Model integration**: Automatically applies model from prompt metadata  
✅ **Command + slash command support** for easy access  
✅ **Public API** for custom picker integrations

## Installation

**Dependencies:**
- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) - Required
- [snacks.nvim](https://github.com/folke/snacks.nvim) - Optional, for Snacks picker (default)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Optional, for Telescope picker

### lazy.nvim

```lua
{
  'olimorris/codecompanion.nvim',
  dependencies = {
    '3ZsForInsomnia/code-companion-picker.nvim',
  },
  opts = {
    -- your codecompanion config
  }
},
{
  '3ZsForInsomnia/code-companion-picker.nvim',
  opts = {
    picker = "snacks", -- "snacks", "telescope", "vim_ui", "auto"
  },
  keys = {
    { "<leader>cp", function() require("code-companion-picker").show_prompts() end, desc = "CodeCompanion Prompts" },
  },
}
```

## Usage

### Commands

```vim
:CodeCompanionPrompts
```

Browse and select from your CodeCompanion prompt library.

### Slash Commands

Add to your CodeCompanion configuration for in-chat access:

```lua
{
  'olimorris/codecompanion.nvim',
  opts = {
    strategies = {
      chat = {
        slash_commands = {
          prompts = require("code-companion-picker").select_slash_command,
        },
      },
    },
  }
}
```

Then use `/prompts` in any CodeCompanion chat buffer.

## Configuration

```lua
{
  '3ZsForInsomnia/code-companion-picker.nvim',
  opts = {
    picker = "snacks", -- "auto", "snacks", "telescope", "vim_ui"
    highlights = {
      -- Customize syntax highlighting colors
      yaml_key = { fg = "#79dac8", bold = true },
      yaml_description = { fg = "#ff9e64" },
      yaml_model = { fg = "#9d7cd8" },
      system_header = { fg = "#f7768e", bold = true },
      user_header = { fg = "#9ece6a", bold = true },
      -- ... see source for all options
    },
  }
}
```

### Picker Options

- `"snacks"` - Use Snacks Picker (default, fastest and most modern)
- `"telescope"` - Use Telescope (classic, good for complex workflows)
- `"vim_ui"` - Use vim.ui.select (fallback, works everywhere)
- `"auto"` - Try Snacks → Telescope → vim.ui.select in order

## Telescope Integration

If you prefer Telescope, you can also use the extension directly:

```lua
require('telescope').load_extension('codecompanion_prompts')
```

Then use:
```vim
:Telescope codecompanion_prompts prompts
```

## Public API

For custom picker integrations or advanced usage:

```lua
local picker = require("code-companion-picker")

-- Get all prompts from CodeCompanion
local prompts = picker.get_codecompanion_prompts()

-- Create display text for a prompt
local display = picker.create_prompt_display_text(prompt_info)

-- Convert prompt to markdown for preview
local markdown = picker.codecompanion_to_markdown(prompt_data, prompt_name)

-- Apply syntax highlighting to buffer
picker.apply_markdown_highlighting(bufnr, lines, highlights)
```

## How It Works

1. **Reads prompts** from CodeCompanion's prompt library
2. **Converts to markdown** with YAML frontmatter for preview
3. **Applies syntax highlighting** for better readability
4. **Handles prompt types**:
   - System prompts → Updates CodeCompanion system prompt
   - User prompts → Adds to chat as user message
   - Model metadata → Automatically changes adapter

## Requirements

- Neovim 0.9+
- CodeCompanion.nvim
- At least one picker: Snacks.nvim (recommended) or Telescope.nvim
