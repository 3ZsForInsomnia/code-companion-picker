-- DEPRECATED: Telescope support is no longer maintained.
-- Please switch to snacks.nvim. This file will be removed in a future release.

local M = {}

function M.show_picker(prompts_info, selection_handler)
  local has_telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("code-companion-picker: telescope.nvim not found", vim.log.levels.ERROR)
    return false
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  if #prompts_info == 0 then
    local display = require("code-companion-picker.ui.display")
    display.show_no_prompts_error()
    return false
  end

  pickers
    .new({}, {
      prompt_title = "CodeCompanion Prompts",
      finder = finders.new_table({
        results = prompts_info,
        entry_maker = function(prompt_info)
          local prompts_util = require("code-companion-picker.utils.prompts")
          local display = prompts_util.create_display_text(prompt_info)

          return {
            value = prompt_info,
            display = display,
            ordinal = (prompt_info.name or "unknown") .. " " .. (prompt_info.frontmatter.description or ""),
            path = "codecompanion:" .. (prompt_info.name or "unknown"),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = M.create_enhanced_previewer(),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            selection_handler(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
    
  return true
end

function M.create_enhanced_previewer()
  local previewers = require("telescope.previewers")
  local highlighting = require("code-companion-picker.utils.highlighting")
  local markdown_converter = require("code-companion-picker.utils.markdown_converter")
  local config = require("code-companion-picker.config").get()
  
  return previewers.new_buffer_previewer({
    title = "Prompt Preview",
    define_preview = function(self, entry, status)
      local prompt_info = entry.value
      
      -- Convert codecompanion prompt to markdown
      local content = markdown_converter.codecompanion_to_markdown(prompt_info.prompt_data, prompt_info.name, {})
      local lines = vim.split(content, "\n")
      
      -- Set buffer content and filetype
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
      
      -- Apply custom highlighting
      highlighting.apply_markdown_highlighting(self.state.bufnr, lines, config.highlights)
    end,
  })
end

function M.show_tool_picker(tools_info, selection_handler)
  local has_telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("code-companion-picker: telescope.nvim not found", vim.log.levels.ERROR)
    return false
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  if #tools_info == 0 then
    vim.notify("code-companion-picker: No tools available", vim.log.levels.WARN)
    return false
  end

  pickers
    .new({}, {
      prompt_title = "CodeCompanion Tools",
      finder = finders.new_table({
        results = tools_info,
        entry_maker = function(tool_info)
          local tools_util = require("code-companion-picker.utils.tools")
          local display = tools_util.create_display_text(tool_info)
          local description = tool_info.description
          
          -- Create display with description if available
          local full_display = display
          if description and description ~= "" and description ~= "No description available" then
            full_display = display .. " - " .. description
          end

          return {
            value = tool_info,
            display = full_display,
            ordinal = (tool_info.name or "unknown") .. " " .. (tool_info.description or ""),
            path = "codecompanion:tool:" .. (tool_info.name or "unknown"),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = M.create_tool_previewer(),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            selection_handler(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
    
  return true
end

function M.create_tool_previewer()
  local previewers = require("telescope.previewers")
  local highlighting = require("code-companion-picker.utils.highlighting")
  local config = require("code-companion-picker.config").get()
  
  return previewers.new_buffer_previewer({
    title = "Tool Preview",
    define_preview = function(self, entry, status)
      local tool_info = entry.value
      
      -- Convert tool to markdown
      local tools_util = require("code-companion-picker.utils.tools")
      local content = tools_util.tool_to_markdown(tool_info)
      local lines = vim.split(content, "\n")
      
      -- Set buffer content and filetype
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
      
      -- Apply custom highlighting
      highlighting.apply_markdown_highlighting(self.state.bufnr, lines, config.highlights)
    end,
  })
end
return M