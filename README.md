# Minimal Neovim Setup

## What this gives you
- Standalone Neovim install (pinned, user-local, no reliance on system Neovim)
- Tokyo Night color theme (`tokyonight-night`)
- Clipboard-centric editing (`unnamedplus` + normal-mode `p`/`P` from clipboard)
- Mouse-enabled pane focus
- VS Code-like `Ctrl-P` fuzzy file search via Telescope
- Left file explorer via NvimTree
- Clickable tabline controls (`+` to open tab, `x` to close tab)

## Install
```bash
./setup.sh
```

## Run
```bash
nv
```

## Key bindings
- `<leader>` is set to `Space`
- `Ctrl-P`: fuzzy file search / open file (VS Code `Ctrl-P` equivalent)
- `<leader>e` (`Space e`): toggle file explorer sidebar (open/close)
- `Ctrl-B`: toggle file explorer sidebar (VS Code style)
- `Ctrl-h/j/k/l`: move between panes
- `<leader>sv`: vertical split
- `<leader>sh`: horizontal split
- `<leader>sx`: close current pane
- `<leader>ta` (`Space t a`): open new tab
- `<leader>tx` (`Space t x`): close current tab
- `<leader>tn` / `<leader>tp`: next / previous tab

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

## Optional knobs
- Override version: `NVIM_VERSION=v0.10.4 ./setup.sh`
- Override profile name: `APP_NAME=nvim-lean ./setup.sh`

## Linux package note
- On Debian/Ubuntu: install `ripgrep` and `fd-find`.
- `fd-find` provides the `fdfind` binary; this config supports both `fd` and `fdfind`.
