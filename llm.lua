-- Sweep Next-Edit training format: uses <|file_sep|> with multi-file context, diffs, and window rewrite
-- Note: llm.nvim approximates via FIM (no native support for recent diffs/sliding window)

local model_path = vim.fn.expand("~/.lmstudio/models/Chris-Kode/sweep-next-edit-1.5b-mlx")
local port = 31337
local server_job = nil

local function start_server()
  if server_job then
    vim.notify("LLM server already running", vim.log.levels.WARN)
    return
  end
  server_job = vim.fn.jobstart({ "mlx_lm.server", "--model", model_path, "--port", tostring(port) }, {
    on_exit = function()
      server_job = nil
    end,
  })
  vim.notify("LLM server started on port " .. port)
end

local function stop_server()
  if not server_job then
    vim.notify("LLM server not running", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstop(server_job)
  server_job = nil
  vim.notify("LLM server stopped")
end

local function toggle_server()
  if server_job then
    stop_server()
  else
    start_server()
  end
end

vim.api.nvim_create_user_command("LlmStart", start_server, {})
vim.api.nvim_create_user_command("LlmStop", stop_server, {})
vim.api.nvim_create_user_command("LlmToggle", toggle_server, {})

-- Auto-start on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = start_server,
  once = true,
})

-- Clean up on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if server_job then
      vim.fn.jobstop(server_job)
    end
  end,
  once = true,
})

return {
  {
    "huggingface/llm.nvim",
    opts = {
      backend = "openai",
      url = "http://localhost:" .. port,
      model = model_path,
      context_window = 8192,
      fim = {
        enabled = true,
        prefix = "<|fim_prefix|>",
        middle = "<|fim_middle|>",
        suffix = "<|fim_suffix|>",
      },
      tokenizer = {
        repository = "Qwen/Qwen2.5-Coder-1.5B",
      },
      tokens_to_clear = { "", "<|file_sep|>", "<|fim_pad|>" },
      request_body = {
        temperature = 0.0,
        stop = { "</s>", "<|fim_pad|>" },
        max_new_tokens = 512,
      },
      enable_suggestions_on_startup = true,
      debounce_ms = 250,
      accept_keymap = "<D-j>",
      dismiss_keymap = "<D-k>",
    },
  },
}
