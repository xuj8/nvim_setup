vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.fillchars:append({ vert = "│" })
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

local function append_candidate(candidates, seen, python)
  if type(python) ~= "string" or python == "" then
    return
  end
  if seen[python] then
    return
  end
  if vim.fn.executable(python) ~= 1 then
    return
  end
  seen[python] = true
  table.insert(candidates, python)
end

local function add_parent_venvs(candidates, seen, start_dir)
  if type(start_dir) ~= "string" or start_dir == "" then
    return
  end

  local dir = vim.fn.fnamemodify(start_dir, ":p")
  while type(dir) == "string" and dir ~= "" do
    append_candidate(candidates, seen, dir .. "/.venv_3_13/bin/python")
    append_candidate(candidates, seen, dir .. "/.venv/bin/python")

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function add_home_child_venvs(candidates, seen)
  local home = vim.env.HOME
  if type(home) ~= "string" or home == "" then
    return
  end

  local matches_313 = vim.fn.glob(home .. "/*/.venv_3_13/bin/python", false, true)
  for _, python in ipairs(matches_313) do
    append_candidate(candidates, seen, python)
  end

  local matches = vim.fn.glob(home .. "/*/.venv/bin/python", false, true)
  for _, python in ipairs(matches) do
    append_candidate(candidates, seen, python)
  end
end

local function configure_python_host()
  local candidates = {}
  local seen = {}
  append_candidate(candidates, seen, vim.env.NVIM_PYTHON3_HOST_PROG)
  if vim.env.VIRTUAL_ENV ~= nil and vim.env.VIRTUAL_ENV ~= "" then
    append_candidate(candidates, seen, vim.env.VIRTUAL_ENV .. "/bin/python")
  end

  add_parent_venvs(candidates, seen, vim.loop.cwd())
  add_home_child_venvs(candidates, seen)

  for _, python in ipairs(candidates) do
    vim.g.python3_host_prog = python
    prepend_path(vim.fn.fnamemodify(python, ":h"))
    return
  end

  -- Never fall back to system python for provider-backed plugins.
  vim.g.loaded_python3_provider = 0
  vim.schedule(function()
    vim.notify(
      "No virtualenv python found for Neovim provider. Set $VIRTUAL_ENV or $NVIM_PYTHON3_HOST_PROG.",
      vim.log.levels.WARN
    )
  end)
end

configure_python_host()
