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
- In-editor graph/image rendering for notebook output via `image.nvim`
- Tabline spinner while Molten cells are running (`Molten -\\|/`)
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
- `<leader>sf`: project-wide text search (VS Code `Ctrl-Shift-F` equivalent) using saved include/exclude globs
- `<leader>sF`: project-wide text search with include/exclude glob prompts
- `<leader>sR`: clear saved include/exclude globs for project search
- `<leader>sw`: search word under cursor in project
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
- `gD`: LSP go to declaration
- `gI`: LSP go to implementation (useful for C++ header -> `.cpp` body jumps)
- `gR`: LSP references
- `<leader>sd`: LSP definitions picker (Telescope)
- `<leader>cs`: C/C++ switch source/header (`clangd`)
- `K`: LSP hover
- `<leader>rn`: LSP rename
- `<leader>ca`: LSP code action
- `[d` / `]d`: previous / next diagnostic
- `gr{motion}`: replace motion text with register contents (`vim-ReplaceWithRegister`)
- `grr`: replace current line with register contents
- Visual mode `gr`: replace selection with register contents

## VS Code equivalents
- File search/open (`Ctrl-P` in VS Code): press `Ctrl-P`, type part of a filename, press `Enter` to open.
- Global text search (`Ctrl-Shift-F` in VS Code): press `Space s f`, type search text, press `Enter` (uses saved include/exclude filters).
- Set/update include/exclude filters: press `Space s F`, enter include globs (optional), then exclude globs (optional), then type search text and press `Enter`.
  Use comma-separated globs (example include: `src/**,*.py`; exclude: `**/node_modules/**,*.min.js`).
- Include/exclude values are remembered for subsequent `Space s f` / `Space s F` searches in the same Neovim session.
- `Space s f` search results display absolute paths and wrap long rows so full paths are visible.
- Sidebar open/close (`Ctrl-B` in VS Code): press `Space e` to toggle the NvimTree sidebar.
- In Telescope prompt (`Ctrl-P`), paste from system clipboard with:
  - Linux terminals: `Ctrl-Shift-V` (if the terminal forwards it) or `Shift-Insert`
  - macOS terminal clients: `Cmd-V` (if supported by the client)
- In Telescope results, press `Ctrl-Y` to show and copy the full selected path.
- In Telescope prompt, delete the previous word with:
  - `Ctrl-W` (reliable fallback)
  - `Ctrl-Backspace` / `Option-Backspace` variants when forwarded by the terminal

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
  absolute path, relative path, file name, create directory, rename, delete file, delete directory.
- Copy actions are silent (no extra confirmation prompt after selecting from the menu).
- Delete actions use an extra two-step confirmation before removal.
- NvimTree opens by default when `nv` starts.
- If NvimTree is the only remaining window, `:q` exits Neovim (no second `:q` needed).
- Keyboard options in NvimTree:
  - `gy`: copy absolute path
  - `Y`: copy relative path
  - `y`: copy file name
  - `gD`: create directory under the selected node
- If you connect from a terminal without Nerd Font support and see `?`/box icons:
  - launch with `NVIM_NO_NERD_FONT=1 nv` for plain-text tree glyphs.
  - or install/select a Nerd Font on the client terminal (recommended for full icons).

## Notebook support
- `.ipynb` support uses `GCBallesteros/jupytext.nvim`.
- Notebook execution uses `benlubas/molten-nvim`.
- Molten output is configured to appear as inline virtual text by default.
- Molten image output is enabled via `image.nvim` (`g:molten_image_provider = "image.nvim"`).
- While code is executing, the tabline shows a `Molten` spinner on the right side.
- Image backend defaults to `kitty`; override with `NVIM_IMAGE_BACKEND=kitty|ueberzug|sixel`.
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
  - For notebook images/plots in Neovim:
    - `ImageMagick` CLI installed and available on `PATH` (used by `image.nvim` with `processor = "magick_cli"`)
    - Install examples:
      - Ubuntu: `sudo apt-get update && sudo apt-get install -y imagemagick`
      - no-sudo fallback: `curl -fL https://imagemagick.org/archive/binaries/magick -o ~/.local/bin/magick && chmod +x ~/.local/bin/magick`
    - a terminal/backend compatible with your `NVIM_IMAGE_BACKEND` (`kitty`, `ueberzug`, or `sixel`)
  - Example manual install:
    ```bash
    python3 -m pip install --user jupytext pynvim jupyter_client nbformat
    ```
- Optional:
  - Nerd Font in your terminal profile (required for icon glyphs in NvimTree/statusline/CLI tools)

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
