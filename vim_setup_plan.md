# Neovim Setup Plan

## Objective
Maintain a reproducible Neovim profile that covers daily coding, navigation, and notebook execution workflows while remaining easy to bootstrap on a fresh machine.

## Current state (completed)
1. Runtime/bootstrap
- `setup.sh` installs pinned Neovim (`v0.11.4` default) into `~/.local/opt/nvim-lean/current`.
- `nv` launcher exports `NVIM_APPNAME=nvim-lean`.
- setup is idempotent and refresh-safe.

2. Core UX
- Clipboard-first editing (`unnamedplus`, normal `p`/`P`).
- Pane movement/splitting and terminal pane shortcuts.
- Mouse enabled.
- Telescope (`Ctrl-P`) and NvimTree (`<leader>e`, `Ctrl-B`).
- Tabline with click targets and tab shortcuts.

3. Advanced editing helpers
- NvimTree right-click path-copy menu + keyboard copy actions (`gy`, `Y`, `y`).
- Current-buffer path copy shortcuts (`<leader>ya`, `<leader>yr`, `<leader>yn`).
- Replace-with-register workflow (`gr` family) for faster in-place text replacement.

4. Language tooling
- Mason + lspconfig stack supports Neovim 0.11 API.
- C++ via `clangd`.
- Python server auto-selection (`basedpyright`/`pyright`/`pylsp`) based on installed executables.

5. Notebook support
- `.ipynb` text editing via `jupytext.nvim`.
- Kernel execution via `molten-nvim` with virtual-text output enabled.
- Neovim Python provider prefers active `VIRTUAL_ENV`, then `./.venv/bin/python`.

## Follow-up backlog
1. Optional image output support for molten (`image.nvim` or `wezterm` provider) if inline plots become a priority.
2. Optional richer notebook ergonomics (cell text-objects, run-cell operators) if current mappings feel too low-level.
3. Optional lock/pin strategy for plugin commit reproducibility in external environments.
