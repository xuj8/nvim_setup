# Minimal Neovim Setup

## What this gives you
- Standalone Neovim install (pinned, user-local, no reliance on system Neovim)
- Tokyo Night color theme (`tokyonight-night`)
- Clipboard-centric editing (`unnamedplus` + normal-mode `p`/`P` from clipboard)
- Mouse-enabled pane focus
- VS Code-like `Ctrl-P` fuzzy file search via Telescope
- Left file explorer via NvimTree
- `.ipynb` editing support via `jupytext.nvim` + `jupytext`
- In-editor notebook execution via `molten-nvim`
- Clickable tabline controls (`+` to open tab, `x` to close tab)
- LSP setup for C++ (`clangd`) and Python (`pyright` default, `pylsp` fallback)

## Install
```bash
# from this repo root
./setup.sh
```

## Run
```bash
nv
```

## Idempotency
- Re-running `./setup.sh` is safe.
- If `NVIM_VERSION` is already installed, the script reuses it and just refreshes the `current` symlink.
- Config and launcher are refreshed each run so `git pull` + `./setup.sh` picks up changes.
- Plugins and Mason LSP packages are refreshed each run.
- Use `FORCE_REINSTALL=1 ./setup.sh` to force re-download/reinstall of Neovim.

## Key bindings
- `<leader>` is set to `Space`
- `Ctrl-P`: fuzzy file search / open file (VS Code `Ctrl-P` equivalent)
- `<leader>e` (`Space e`): toggle file explorer sidebar (open/close)
- `Ctrl-B`: toggle file explorer sidebar (VS Code style)
- `Ctrl-h/j/k/l`: move between panes
- `<leader>sv`: vertical split
- `<leader>sh`: horizontal split
- `<leader>sx`: close current pane
- `<leader>tt`: open terminal in horizontal split
- `<leader>tv`: open terminal in vertical split
- Terminal mode: `<Esc><Esc>` exits terminal insert mode
- `<leader>ta` (`Space t a`): open new tab
- `<leader>tx` (`Space t x`): close current tab
- `<leader>tn` / `<leader>tp`: next / previous tab
- `<leader>ya`: copy current file absolute path
- `<leader>yr`: copy current file path relative to project root (`cwd`)
- `<leader>yn`: copy current file name
- `<leader>mi`: Molten init kernel
- `<leader>ml`: Molten evaluate current line
- Visual `<leader>mv`: Molten evaluate selected code
- `<leader>mo`: Molten open output window
- `<leader>mh`: Molten hide output window
- `<leader>mx`: Molten interrupt kernel
- `<leader>mr`: Molten restart kernel
- `gd`: LSP go to definition
- `gR`: LSP references
- `K`: LSP hover
- `<leader>rn`: LSP rename
- `<leader>ca`: LSP code action
- `[d` / `]d`: previous / next diagnostic
- `gr{motion}`: replace motion text with register contents (`vim-ReplaceWithRegister`)
- `grr`: replace current line with register contents
- Visual mode `gr`: replace selection with register contents

## VS Code equivalents
- File search/open (`Ctrl-P` in VS Code): press `Ctrl-P`, type part of a filename, press `Enter` to open.
- Sidebar open/close (`Ctrl-B` in VS Code): press `Space e` to toggle the NvimTree sidebar.

## Tabs (mouse + keyboard)
- Click a tab name to switch tabs.
- Click `+` on the right side of the tabline to open a new tab.
- Click `x` on a tab to close it.
- Open a new tab with `Space t a`.

## Clipboard behavior
- `yy`, `dd`, and other unnamed-register yanks/deletes go to system clipboard.
- Normal mode `p`/`P` paste from system clipboard.
- `Ctrl-Shift-V` paste remains terminal-driven and should work as long as your terminal clipboard is configured.

## File explorer path copy options
- In NvimTree (`Space e`), right-click a node to open copy actions:
  absolute path, relative path, file name.
- Keyboard options in NvimTree:
  - `gy`: copy absolute path
  - `Y`: copy relative path
  - `y`: copy file name

## Notebook support
- `.ipynb` support uses `GCBallesteros/jupytext.nvim`.
- Notebook execution uses `benlubas/molten-nvim`.
- Molten output is configured to appear as inline virtual text by default.
- This setup prefers Neovim Python host from active `VIRTUAL_ENV`, then falls back to `./.venv_3_13/bin/python` (from Neovim launch directory), and prepends that venv `bin` path to `PATH`.

## External dependencies
- Installed by `./setup.sh`:
  - pinned Neovim binary (`NVIM_VERSION`, default `v0.11.4`)
  - plugins via `lazy.nvim`
  - Mason LSP servers when possible (`pyright` if `node`/`npm` exist, `clangd` if needed and `unzip` exists)
- Must already exist on the system for `./setup.sh`:
  - required: `curl`, `tar`, `git`
  - strongly recommended: `rg`
  - optional but recommended: `fd` or `fdfind`
  - Linux clipboard support: `xclip`
- Notebook/runtime pieces not installed by `./setup.sh`:
  - `jupytext` CLI must be on `PATH` for `.ipynb` conversion
  - Python packages in Neovim host environment: `pynvim`, `jupyter_client` (`nbformat` if using import/export)
  - Example manual install:
    ```bash
    python3 -m pip install --user jupytext pynvim jupyter_client nbformat
    ```
- Optional (not enabled by default):
  - image rendering providers for molten (`image.nvim` or `wezterm.nvim` + their external deps)

## Optional knobs
- Override version: `NVIM_VERSION=v0.11.4 ./setup.sh`
- Override profile name: `APP_NAME=nvim-lean ./setup.sh`
- Force reinstall of pinned Neovim: `FORCE_REINSTALL=1 ./setup.sh`

## LSP notes
- C++: uses `clangd`.
- Python:
  - If `node` + `npm` exist, installs/uses `pyright`.
  - Otherwise, falls back to `python-lsp-server` (`pylsp`) when `python3` has `venv` + `ensurepip`.
  - If `basedpyright-langserver` is already installed, it will be preferred.
- Setup installs LSP servers through Mason during `./setup.sh`.
- For best C++ results, generate a `compile_commands.json` in your project root.

## Linux package note
- On Debian/Ubuntu: install `ripgrep` and `fd-find`.
- `fd-find` provides the `fdfind` binary; this config supports both `fd` and `fdfind`.
