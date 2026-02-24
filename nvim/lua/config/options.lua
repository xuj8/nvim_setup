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

local function prepend_path(dir)
  if dir == nil or dir == "" then
    return
  end

  if not string.find(vim.env.PATH or "", dir, 1, true) then
    vim.env.PATH = dir .. ":" .. (vim.env.PATH or "")
  end
end

local function configure_python_host()
  local candidates = {}
  if vim.env.VIRTUAL_ENV ~= nil and vim.env.VIRTUAL_ENV ~= "" then
    table.insert(candidates, vim.env.VIRTUAL_ENV .. "/bin/python")
  end

  local cwd = vim.loop.cwd()
  if cwd ~= nil and cwd ~= "" then
    table.insert(candidates, cwd .. "/.venv/bin/python")
  end

  for _, python in ipairs(candidates) do
    if vim.fn.executable(python) == 1 then
      vim.g.python3_host_prog = python
      prepend_path(vim.fn.fnamemodify(python, ":h"))
      return
    end
  end
end

configure_python_host()
