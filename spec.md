# Standalone Neovim Spec (Linux-first)

## Goal
Ship a reproducible Neovim profile that does not depend on system Neovim, can be installed with one script, and includes day-to-day coding + notebook workflows.

## Environment assumptions
- Primary target: Linux.
- Secondary target: macOS (best effort).
- System `nvim` may be old; setup must provide its own binary.
- `rg` is expected; `fd` may be absent (`fdfind` on Debian/Ubuntu).
- Python tooling may vary by host; config should degrade gracefully.

## Core requirements
1. Runtime and profile isolation:
- Install pinned Neovim from GitHub releases (default `v0.11.4`) into user-local path.
- Use isolated `NVIM_APPNAME=nvim-lean`.
- Provide `nv` launcher that always starts the isolated profile.

2. Editing and navigation:
- System clipboard integration (`unnamedplus`).
- Normal mode `p`/`P` paste from clipboard.
- Pane navigation (`Ctrl-h/j/k/l`) and split operations.
- Terminal splits with keymaps.
- Mouse support for pane focus.

3. File discovery and project navigation:
- VS Code-style fuzzy file finder on `Ctrl-P` (Telescope).
- Left file explorer (`NvimTree`) with toggle and mouse interaction.
- File path copy actions in tree:
  - absolute path
  - cwd-relative path
  - file name

4. LSP baseline:
- C++ via `clangd`.
- Python via executable server detection:
  - prefer `basedpyright` when available
  - else `pyright`
  - else `pylsp`
- Neovim 0.11 API compatibility (`vim.lsp.config`/`vim.lsp.enable`) with fallback.

5. Notebook workflow:
- `.ipynb` open/edit support through `jupytext.nvim` + `jupytext` CLI.
- In-editor code execution via `molten-nvim`.
- Default output mode includes virtual text (`molten_virt_text_output=true`).
- Python host should prefer `/home/jack/mono/.venv/bin/python` when present.

## Plugin surface
- `lazy.nvim`
- `tokyonight.nvim`
- `telescope.nvim`, `plenary.nvim`
- `nvim-tree.lua`, `nvim-web-devicons`
- `tabby.nvim`
- `mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`
- `jupytext.nvim`
- `molten-nvim`
- `vim-ReplaceWithRegister`, `vim-ingo-library`

## Acceptance criteria
- `./setup.sh` installs/refreshes `nv` and the isolated config.
- `nv --version` reports Neovim 0.11+ from the user-local install.
- `:set clipboard?` reports `unnamedplus`.
- `Ctrl-P` opens file picker; `<leader>e` toggles file tree.
- NvimTree supports right-click copy menu and `gy`/`Y`/`y` copy mappings.
- `<leader>tt` and `<leader>tv` open terminal splits.
- LSP keymaps (`gd`, `gR`, `K`, `<leader>rn`, `<leader>ca`) are attached on LSP buffers.
- `.ipynb` files open as jupytext text representation when CLI is present.
- Molten commands/maps run:
  - `<leader>mi` init kernel
  - `<leader>ml` eval line
  - visual `<leader>mv` eval selection
  - `<leader>mo`/`<leader>mh` output open/hide
