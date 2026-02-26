local map = vim.keymap.set

local function copy_to_clipboard(label, value)
  if value == nil or value == "" then
    vim.notify("No " .. label .. " available to copy", vim.log.levels.WARN)
    return
  end

  vim.fn.setreg('"', value)
  local ok = pcall(vim.fn.setreg, "+", value)
  if ok then
    vim.notify("Copied " .. label .. ": " .. value)
  else
    vim.notify("Copied " .. label .. " (clipboard provider unavailable)", vim.log.levels.WARN)
  end
end

local function current_file_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Current buffer is not a file", vim.log.levels.WARN)
    return nil
  end
  return path
end

local function open_terminal_split(command, resize)
  vim.cmd(command)
  if resize then
    vim.cmd("resize " .. resize)
  end
  vim.cmd("terminal")
  vim.cmd("startinsert")
end

local function has_user_command(name)
  return vim.fn.exists(":" .. name) == 2
end

local function notebook_like_filetype()
  return vim.bo.filetype == "markdown" or vim.bo.filetype == "quarto"
end

local molten_init_quick_pick

local function one_key_pick(items, prompt)
  if type(items) ~= "table" or #items == 0 then
    return nil
  end
  if #items == 1 then
    return items[1]
  end
  if #items > 9 then
    return nil
  end

  local lines = { prompt .. " (press 1-" .. #items .. ", q to cancel):" }
  for index, item in ipairs(items) do
    table.insert(lines, string.format("%d. %s", index, item))
  end
  vim.api.nvim_echo({ { table.concat(lines, "\n") } }, false, {})
  local ok, key = pcall(vim.fn.getcharstr)
  vim.cmd("echo")

  if not ok or key == nil or key == "" then
    return nil
  end
  if key == "q" or key == "Q" or key == "\027" then
    return nil
  end

  local index = tonumber(key)
  if not index or index < 1 or index > #items then
    vim.notify("Invalid selection: " .. key, vim.log.levels.WARN)
    return nil
  end

  return items[index]
end

local function contains(items, value)
  if type(items) ~= "table" then
    return false
  end
  for _, item in ipairs(items) do
    if item == value then
      return true
    end
  end
  return false
end

local function buffer_running_kernels()
  local ok, kernels = pcall(vim.fn.MoltenRunningKernels, true)
  if ok and type(kernels) == "table" then
    return kernels
  end
  return {}
end

local function fence_lang(line)
  local header = line:match("^%s*```+%s*(.-)%s*$")
  if header == nil or header == "" then
    return nil
  end

  local lang = nil
  if header:sub(1, 1) == "{" then
    local inner = header:match("^%{([^}]+)%}")
    if inner ~= nil then
      lang = inner:match("^([%w_+%.%-]+)")
    end
  else
    lang = header:match("^([%w_+%.%-]+)")
  end

  if lang == nil or lang == "" then
    return nil
  end
  return string.lower(lang)
end

local function is_fence_close(line)
  return line:match("^%s*```+%s*$") ~= nil
end

local function collect_code_chunks(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local chunks = {}
  local i = 1
  while i <= #lines do
    local lang = fence_lang(lines[i])
    if lang ~= nil then
      local j = i + 1
      while j <= #lines and not is_fence_close(lines[j]) do
        j = j + 1
      end
      if j <= #lines and (j - i) > 1 then
        table.insert(chunks, {
          lang = lang,
          open = i,
          start = i + 1,
          ["end"] = j - 1,
          close = j,
        })
      end
      i = j + 1
    else
      i = i + 1
    end
  end
  return chunks
end

local function current_chunk(bufnr)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  for _, chunk in ipairs(collect_code_chunks(bufnr)) do
    if row >= chunk.open and row <= chunk.close then
      return chunk
    end
  end
  return nil
end

local function molten_evaluate_range(start_line, end_line, kernel)
  local ok
  if kernel ~= nil and kernel ~= "" then
    ok = pcall(vim.fn.MoltenEvaluateRange, kernel, start_line, end_line)
  else
    ok = pcall(vim.fn.MoltenEvaluateRange, start_line, end_line)
  end
  if ok then
    return true
  end
  if has_user_command("MoltenEvaluateLine") and start_line == end_line then
    if kernel ~= nil and kernel ~= "" then
      vim.cmd("MoltenEvaluateLine " .. vim.fn.fnameescape(kernel))
    else
      vim.cmd("MoltenEvaluateLine")
    end
    return true
  end
  return false
end

local function resolve_run_kernel()
  local kernels = buffer_running_kernels()
  local cached = vim.b.molten_preferred_kernel
  if type(cached) == "string" and cached ~= "" and contains(kernels, cached) then
    return cached
  end

  if #kernels == 0 then
    local initialized = molten_init_quick_pick()
    if type(initialized) == "string" and initialized ~= "" then
      vim.b.molten_preferred_kernel = initialized
      return initialized
    end
    kernels = buffer_running_kernels()
  end
  if #kernels == 0 then
    return nil
  end
  if #kernels == 1 then
    vim.b.molten_preferred_kernel = kernels[1]
    return kernels[1]
  end
  local selected = one_key_pick(kernels, "Select running kernel")
  if selected ~= nil then
    vim.b.molten_preferred_kernel = selected
  end
  return selected
end

local function run_current_cell()
  local kernel = resolve_run_kernel()
  if kernel == nil then
    return
  end
  if notebook_like_filetype() then
    local chunk = current_chunk(0)
    if chunk ~= nil then
      if molten_evaluate_range(chunk.start, chunk["end"], kernel) then
        return
      end
    end
  end
  if molten_evaluate_range(vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1], kernel) then
    return
  end
  vim.notify("No cell runner available", vim.log.levels.WARN)
end

local function run_cell_and_above()
  local kernel = resolve_run_kernel()
  if kernel == nil then
    return
  end
  if notebook_like_filetype() then
    local chunks = collect_code_chunks(0)
    local chunk = current_chunk(0)
    if chunk ~= nil then
      for _, c in ipairs(chunks) do
        if c.close <= chunk.close then
          molten_evaluate_range(c.start, c["end"], kernel)
        end
      end
      return
    end
  end
  molten_evaluate_range(vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1], kernel)
end

local function run_all_cells()
  local kernel = resolve_run_kernel()
  if kernel == nil then
    return
  end
  if notebook_like_filetype() then
    local chunks = collect_code_chunks(0)
    if #chunks > 0 then
      for _, chunk in ipairs(chunks) do
        molten_evaluate_range(chunk.start, chunk["end"], kernel)
      end
      return
    end
  end

  if molten_evaluate_range(1, vim.api.nvim_buf_line_count(0), kernel) then
    return
  end

  vim.notify("Run-all failed: no runnable code chunks found", vim.log.levels.WARN)
end

molten_init_quick_pick = function()
  if vim.fn.exists(":MoltenInit") ~= 2 then
    vim.notify("MoltenInit command not available", vim.log.levels.WARN)
    return
  end

  local ok, kernels = pcall(vim.fn.MoltenAvailableKernels)
  if not ok or type(kernels) ~= "table" or #kernels == 0 then
    vim.cmd("MoltenInit")
    return
  end

  if #kernels == 1 then
    vim.cmd("MoltenInit " .. vim.fn.fnameescape(kernels[1]))
    vim.b.molten_preferred_kernel = kernels[1]
    return kernels[1]
  end

  if #kernels > 9 then
    vim.cmd("MoltenInit")
    return nil
  end

  local selected = one_key_pick(kernels, "Select kernel")
  if selected == nil then
    return nil
  end
  vim.cmd("MoltenInit " .. vim.fn.fnameescape(selected))
  vim.b.molten_preferred_kernel = selected
  return selected
end

-- Pane movement
map("n", "<C-h>", "<C-w>h", { desc = "Move to left pane" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower pane" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper pane" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right pane" })

-- Pane management
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontally" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close pane" })
map("n", "<leader>tt", function()
  open_terminal_split("botright split", 12)
end, { desc = "Open terminal (horizontal split)" })
map("n", "<leader>tv", function()
  open_terminal_split("botright vsplit")
end, { desc = "Open terminal (vertical split)" })

map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left pane from terminal" })
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to lower pane from terminal" })
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to upper pane from terminal" })
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right pane from terminal" })

-- Tab management
map("n", "<leader>ta", "<cmd>tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- Copy current file paths
map("n", "<leader>ya", function()
  local path = current_file_path()
  if not path then
    return
  end
  copy_to_clipboard("absolute path", vim.fn.fnamemodify(path, ":p"))
end, { desc = "Copy current file absolute path" })
map("n", "<leader>yr", function()
  local path = current_file_path()
  if not path then
    return
  end
  copy_to_clipboard("relative path", vim.fn.fnamemodify(path, ":."))
end, { desc = "Copy current file relative path" })
map("n", "<leader>yn", function()
  local path = current_file_path()
  if not path then
    return
  end
  copy_to_clipboard("file name", vim.fn.fnamemodify(path, ":t"))
end, { desc = "Copy current file name" })

-- Molten notebook execution
map("n", "<leader>mi", molten_init_quick_pick, { desc = "Notebook: init kernel (single-key picker)" })
map("n", "<leader>mc", run_current_cell, { desc = "Notebook: run current cell" })
map("n", "<leader>ma", run_cell_and_above, { desc = "Notebook: run current cell and above" })
map("n", "<leader>mA", run_all_cells, { desc = "Notebook: run all cells" })
map("n", "<leader>ml", "<cmd>MoltenEvaluateLine<CR>", { desc = "Notebook: run current line" })
map("x", "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "Molten: evaluate selection" })
map("n", "<leader>mn", "<cmd>MoltenNext<CR>", { desc = "Notebook: next cell" })
map("n", "<leader>mp", "<cmd>MoltenPrev<CR>", { desc = "Notebook: previous cell" })
map("n", "<leader>md", "<cmd>MoltenDelete<CR>", { desc = "Notebook: delete active cell" })
map("n", "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<CR>", { desc = "Molten: open output" })
map("n", "<leader>mh", "<cmd>MoltenHideOutput<CR>", { desc = "Molten: hide output" })
map("n", "<leader>mE", "<cmd>MoltenExportOutput!<CR>", { desc = "Notebook: export outputs to ipynb" })
map("n", "<leader>mI", "<cmd>MoltenImportOutput<CR>", { desc = "Notebook: import outputs from ipynb" })
map("n", "<leader>mx", "<cmd>MoltenInterrupt<CR>", { desc = "Molten: interrupt kernel" })
map("n", "<leader>mr", "<cmd>MoltenRestart<CR>", { desc = "Molten: restart kernel" })

-- Hard requirement: normal-mode p/P should paste from system clipboard.
map("n", "p", '"+p', { noremap = true, silent = true, desc = "Paste after from clipboard" })
map("n", "P", '"+P', { noremap = true, silent = true, desc = "Paste before from clipboard" })
