local M = {}

local uv = vim.uv or vim.loop
local frames = { "-", "\\", "|", "/" }
local state = {
  frame = 1,
  running = false,
  last_running_ms = 0,
  timer = nil,
}

local function now_ms()
  return uv.now()
end

local function buffer_has_running_header(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, 1, false)
  if not ok or lines == nil or lines[1] == nil then
    return false
  end

  return string.find(lines[1], ": ... Running", 1, true) ~= nil
end

local function molten_is_running()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if buffer_has_running_header(bufnr) then
      return true
    end
  end

  return false
end

local function redraw_tabline()
  pcall(vim.cmd, "redrawtabline")
end

local function tick()
  local is_running = molten_is_running()
  if is_running then
    state.running = true
    state.last_running_ms = now_ms()
  elseif state.running and (now_ms() - state.last_running_ms > 400) then
    state.running = false
  end

  if state.running then
    state.frame = (state.frame % #frames) + 1
    redraw_tabline()
  end
end

function M.status_text()
  if not state.running then
    return ""
  end

  return " Molten " .. frames[state.frame] .. " "
end

function M.setup()
  if state.timer ~= nil then
    return
  end

  state.timer = uv.new_timer()
  if state.timer == nil then
    return
  end

  state.timer:start(0, 120, vim.schedule_wrap(tick))

  local group = vim.api.nvim_create_augroup("NvLeanMoltenSpinner", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if state.timer == nil then
        return
      end

      state.timer:stop()
      state.timer:close()
      state.timer = nil
    end,
  })
end

return M
