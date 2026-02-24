vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.mouse = "a"
vim.opt.showtabline = 2

-- Make unnamed register use the system clipboard.
vim.opt.clipboard = "unnamedplus"

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250

local mono_venv_python = "/home/jack/mono/.venv/bin/python"
local mono_venv_bin = "/home/jack/mono/.venv/bin"

if vim.fn.executable(mono_venv_python) == 1 then
  vim.g.python3_host_prog = mono_venv_python
  if not string.find(vim.env.PATH or "", mono_venv_bin, 1, true) then
    vim.env.PATH = mono_venv_bin .. ":" .. (vim.env.PATH or "")
  end
end
