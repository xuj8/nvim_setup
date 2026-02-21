#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
APP_NAME="${APP_NAME:-nvim-lean}"
NVIM_VERSION="${NVIM_VERSION:-v0.10.4}"
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
  local tmp_dir archive extract_dir nvim_bin bundle_root version_dir current_link
  tmp_dir="$(mktemp -d)"

  archive="$tmp_dir/nvim.tar.gz"
  extract_dir="$tmp_dir/extract"
  version_dir="$INSTALL_ROOT/$NVIM_VERSION"
  current_link="$INSTALL_ROOT/current"

  download_archive "$archive" || die "Failed to download Neovim release ${NVIM_VERSION}"

  mkdir -p "$extract_dir"
  tar -xzf "$archive" -C "$extract_dir"

  nvim_bin="$(find "$extract_dir" -type f -path '*/bin/nvim' | head -n 1 || true)"
  [ -n "$nvim_bin" ] || die "Could not find nvim binary inside archive"

  bundle_root="$(dirname "$(dirname "$nvim_bin")")"

  mkdir -p "$INSTALL_ROOT"
  rm -rf "$version_dir"
  mv "$bundle_root" "$version_dir"
  ln -sfn "$version_dir" "$current_link"

  log "Installed Neovim to $current_link"
  rm -rf "$tmp_dir"
}

install_config() {
  [ -d "$CONFIG_SRC" ] || die "Config source not found: $CONFIG_SRC"

  mkdir -p "$(dirname "$CONFIG_DST")"
  rm -rf "$CONFIG_DST"
  cp -R "$CONFIG_SRC" "$CONFIG_DST"

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

main() {
  need_cmd curl
  need_cmd tar
  need_cmd git

  warn_if_missing xclip "xclip not found; clipboard integration on Linux may fail."
  warn_if_missing rg "rg not found; Telescope fallback find command may fail."
  if ! has_fd_binary; then
    warn "fd/fdfind not found; file search will use 'rg --files' fallback."
  fi

  install_nvim
  install_config
  install_launcher
  sync_plugins

  cat <<SUMMARY

[setup] Done.
[setup] Use Neovim via: nv
[setup] Config app name: $APP_NAME
[setup] Config path: $CONFIG_DST
[setup] Binary path: $INSTALL_ROOT/current/bin/nvim
SUMMARY
}

main "$@"
