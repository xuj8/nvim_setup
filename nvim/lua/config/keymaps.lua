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
map("n", "<leader>mi", "<cmd>MoltenInit<CR>", { desc = "Molten: init kernel" })
map("n", "<leader>ml", "<cmd>MoltenEvaluateLine<CR>", { desc = "Molten: evaluate line" })
map("x", "<leader>mv", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "Molten: evaluate selection" })
map("n", "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<CR>", { desc = "Molten: open output" })
map("n", "<leader>mh", "<cmd>MoltenHideOutput<CR>", { desc = "Molten: hide output" })
map("n", "<leader>mx", "<cmd>MoltenInterrupt<CR>", { desc = "Molten: interrupt kernel" })
map("n", "<leader>mr", "<cmd>MoltenRestart<CR>", { desc = "Molten: restart kernel" })

-- Hard requirement: normal-mode p/P should paste from system clipboard.
map("n", "p", '"+p', { noremap = true, silent = true, desc = "Paste after from clipboard" })
map("n", "P", '"+P', { noremap = true, silent = true, desc = "Paste before from clipboard" })
