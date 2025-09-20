local M = {}

local model_mappings = {
  ["Claude Sonnet 4"] = "claude-4-sonnet",
  ["Claude Sonnet 3.5"] = "claude-3-5-sonnet-20241022",
  ["Claude Sonnet"] = "claude-3-5-sonnet-20241022",
  ["Claude Haiku 3.5"] = "claude-3-5-haiku-20241022",
  ["Claude Haiku"] = "claude-3-5-haiku-20241022",
  ["Claude Opus 3"] = "claude-3-opus-20240229",
  ["Claude Opus"] = "claude-3-opus-20240229",

  ["GPT-4"] = "gpt-4",
  ["GPT-4 Turbo"] = "gpt-4-turbo-preview",
  ["GPT-4o"] = "gpt-4o",
  ["GPT-4o Mini"] = "gpt-4o-mini",
  ["GPT-3.5 Turbo"] = "gpt-3.5-turbo",
  ["GPT-5"] = "gpt-5",
  ["GPT-5 Mini"] = "gpt-5-mini",
  ["GPT-5 Nano"] = "gpt-5-nano",
  ["GPT-5 Chat"] = "gpt-5-chat",
  ["GPT-5 Chat Latest"] = "gpt-5-chat-latest",

  ["Gemini 2.5 Pro"] = "gemini-2.5-pro",
  ["Gemini 2.5 Flash"] = "gemini-2.5-flash",
  ["Gemini Pro"] = "gemini-2.5-pro",
  ["Gemini Flash"] = "gemini-2.5-flash",

  ["Llama 70B"] = "llama-70b",
  ["Llama 8B"] = "llama-8b",
}

function M.get_technical_name(display_name)
  if not display_name or type(display_name) ~= "string" then
    return ""
  end

  local technical = model_mappings[display_name]
  if technical then
    return technical
  end

  for display, tech in pairs(model_mappings) do
    if display:lower() == display_name:lower() then
      return tech
    end
  end

  return ""
end

return M