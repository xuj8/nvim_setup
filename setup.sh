#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
APP_NAME="${APP_NAME:-nvim-lean}"
NVIM_VERSION="${NVIM_VERSION:-v0.11.4}"
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"
INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.local/opt/nvim-lean}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_SRC="$SCRIPT_DIR/nvim"
CONFIG_DST="$CONFIG_ROOT/$APP_NAME"

log() {
  printf '[setup] %s\n' "$*"
}

warn() {
  printf '[setup][warn] %s\n' "$*" >&2
}

die() {
  printf '[setup][error] %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Missing required command: $1"
  fi
}

warn_if_missing() {
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "$2"
  fi
}

has_fd_binary() {
  if command -v fd >/dev/null 2>&1; then
    return 0
  fi

  if command -v fdfind >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

has_python_venv_support() {
  if ! command -v python3 >/dev/null 2>&1; then
    return 1
  fi

  python3 -m venv -h >/dev/null 2>&1 && python3 -m ensurepip --version >/dev/null 2>&1
}

build_lsp_package_list() {
  local -a packages=()

  if ! command -v clangd >/dev/null 2>&1; then
    if command -v unzip >/dev/null 2>&1; then
      packages+=("clangd")
    fi
  fi

  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    packages+=("pyright")
  elif has_python_venv_support; then
    packages+=("python-lsp-server")
  fi

  printf '%s\n' "${packages[@]}"
}

download_archive() {
  local archive_path="$1"
  local os arch
  local -a assets=()

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64)
          assets+=("nvim-linux-x86_64.tar.gz" "nvim-linux64.tar.gz")
          ;;
        aarch64|arm64)
          assets+=("nvim-linux-arm64.tar.gz" "nvim-linux-aarch64.tar.gz")
          ;;
        *)
          die "Unsupported Linux architecture: $arch"
          ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        x86_64)
          assets+=("nvim-macos-x86_64.tar.gz" "nvim-macos.tar.gz")
          ;;
        arm64)
          assets+=("nvim-macos-arm64.tar.gz" "nvim-macos.tar.gz")
          ;;
        *)
          die "Unsupported macOS architecture: $arch"
          ;;
      esac
      ;;
    *)
      die "Unsupported OS: $os"
      ;;
  esac

  for asset in "${assets[@]}"; do
    local url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${asset}"
    log "Trying download: ${url}"
    if curl --fail --location --silent --show-error "$url" -o "$archive_path"; then
      log "Downloaded ${asset}"
      return 0
    fi
  done

  return 1
}

install_nvim() {
  local tmp_dir archive extract_dir nvim_bin bundle_root version_dir current_link staging_dir backup_dir
  tmp_dir="$(mktemp -d)"

  archive="$tmp_dir/nvim.tar.gz"
  extract_dir="$tmp_dir/extract"
  version_dir="$INSTALL_ROOT/$NVIM_VERSION"
  current_link="$INSTALL_ROOT/current"
  staging_dir="$INSTALL_ROOT/.${NVIM_VERSION}.tmp.$$"

  mkdir -p "$INSTALL_ROOT"

  if [ "$FORCE_REINSTALL" != "1" ] && [ -x "$version_dir/bin/nvim" ]; then
    ln -sfn "$version_dir" "$current_link"
    log "Neovim ${NVIM_VERSION} already installed; refreshed $current_link"
    rm -rf "$tmp_dir"
    return
  fi

  download_archive "$archive" || die "Failed to download Neovim release ${NVIM_VERSION}"

  mkdir -p "$extract_dir"
  tar -xzf "$archive" -C "$extract_dir"

  nvim_bin="$(find "$extract_dir" -type f -path '*/bin/nvim' | head -n 1 || true)"
  [ -n "$nvim_bin" ] || die "Could not find nvim binary inside archive"

  bundle_root="$(dirname "$(dirname "$nvim_bin")")"

  rm -rf "$staging_dir"
  mv "$bundle_root" "$staging_dir"
  backup_dir="$INSTALL_ROOT/.${NVIM_VERSION}.bak.$$"
  rm -rf "$backup_dir"
  if [ -e "$version_dir" ]; then
    mv "$version_dir" "$backup_dir"
  fi

  if ! mv "$staging_dir" "$version_dir"; then
    if [ -e "$backup_dir" ]; then
      mv "$backup_dir" "$version_dir" || true
    fi
    die "Failed to install Neovim release ${NVIM_VERSION}"
  fi
  rm -rf "$backup_dir"
  ln -sfn "$version_dir" "$current_link"

  log "Installed Neovim to $current_link"
  rm -rf "$tmp_dir"
}

install_config() {
  local config_parent staging_config backup_config
  [ -d "$CONFIG_SRC" ] || die "Config source not found: $CONFIG_SRC"

  config_parent="$(dirname "$CONFIG_DST")"
  mkdir -p "$config_parent"
  staging_config="$(mktemp -d "$config_parent/.${APP_NAME}.tmp.XXXXXX")"
  cp -R "$CONFIG_SRC"/. "$staging_config"/

  backup_config="$config_parent/.${APP_NAME}.bak.$$"
  rm -rf "$backup_config"
  if [ -e "$CONFIG_DST" ]; then
    mv "$CONFIG_DST" "$backup_config"
  fi

  if ! mv "$staging_config" "$CONFIG_DST"; then
    if [ -e "$backup_config" ]; then
      mv "$backup_config" "$CONFIG_DST" || true
    fi
    die "Failed to install config at $CONFIG_DST"
  fi
  rm -rf "$backup_config"

  log "Installed config at $CONFIG_DST"
}

install_launcher() {
  local launcher="$BIN_DIR/nv"
  local nvim_bin="$INSTALL_ROOT/current/bin/nvim"

  mkdir -p "$BIN_DIR"

  cat > "$launcher" <<LAUNCHER
#!/usr/bin/env bash
set -euo pipefail

NVIM_BIN="$nvim_bin"
if [ ! -x "\$NVIM_BIN" ]; then
  echo "Neovim binary not found at \$NVIM_BIN. Re-run setup.sh." >&2
  exit 1
fi

export NVIM_APPNAME="$APP_NAME"
exec "\$NVIM_BIN" "\$@"
LAUNCHER

  chmod +x "$launcher"
  log "Installed launcher at $launcher"

  case ":$PATH:" in
    *":$BIN_DIR:"*)
      ;;
    *)
      warn "$BIN_DIR is not on PATH. Add it so the 'nv' command is available globally."
      ;;
  esac
}

sync_plugins() {
  local nvim_bin="$INSTALL_ROOT/current/bin/nvim"

  if [ ! -x "$nvim_bin" ]; then
    warn "Skipping plugin sync: nvim binary missing"
    return
  fi

  log "Syncing plugins with Lazy (requires network access)..."
  if ! NVIM_APPNAME="$APP_NAME" "$nvim_bin" --headless "+Lazy! sync" +qa >/dev/null 2>&1; then
    warn "Plugin sync failed. Run manually later: NVIM_APPNAME=$APP_NAME $nvim_bin +Lazy! sync"
  fi
}

sync_lsp_servers() {
  local nvim_bin="$INSTALL_ROOT/current/bin/nvim"
  local -a lsp_packages

  if [ ! -x "$nvim_bin" ]; then
    warn "Skipping LSP install: nvim binary missing"
    return
  fi

  mapfile -t lsp_packages < <(build_lsp_package_list)
  if [ "${#lsp_packages[@]}" -eq 0 ]; then
    warn "Skipping LSP install: no package candidates"
    return
  fi

  log "Installing LSP servers with Mason: ${lsp_packages[*]}"
  if ! NVIM_APPNAME="$APP_NAME" "$nvim_bin" --headless "+MasonInstall ${lsp_packages[*]}" +qa >/dev/null 2>&1; then
    warn "LSP install failed. Run manually later: NVIM_APPNAME=$APP_NAME $nvim_bin +MasonInstall ${lsp_packages[*]}"
  fi
}

main() {
  need_cmd curl
  need_cmd tar
  need_cmd git

  warn_if_missing xclip "xclip not found; clipboard integration on Linux may fail."
  warn_if_missing rg "rg not found; Telescope fallback find command may fail."
  warn_if_missing jupytext "jupytext not found; .ipynb support in Neovim will not work until installed."
  if ! command -v clangd >/dev/null 2>&1 && ! command -v unzip >/dev/null 2>&1; then
    warn "clangd not found and unzip missing; Mason cannot install clangd automatically."
  fi
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    warn "node/npm not found; Python LSP fallback requires python3 with venv+ensurepip support."
  fi
  warn_if_missing python3 "python3 not found; Python LSP setup may be skipped."
  if command -v python3 >/dev/null 2>&1 && ! has_python_venv_support; then
    warn "python3 is missing venv/ensurepip; Mason cannot install Python-based LSP servers."
  fi
  if ! has_fd_binary; then
    warn "fd/fdfind not found; file search will use 'rg --files' fallback."
  fi

  install_nvim
  install_config
  install_launcher
  sync_plugins
  sync_lsp_servers

  cat <<SUMMARY

[setup] Done.
[setup] Use Neovim via: nv
[setup] Config app name: $APP_NAME
[setup] Config path: $CONFIG_DST
[setup] Binary path: $INSTALL_ROOT/current/bin/nvim
SUMMARY
}

main "$@"
