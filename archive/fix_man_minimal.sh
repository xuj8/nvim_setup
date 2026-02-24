#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

EXCLUDES_FILE="/etc/dpkg/dpkg.cfg.d/excludes"
BACKUP_FILE="/etc/dpkg/dpkg.cfg.d/excludes.bak"

if [ -f "$EXCLUDES_FILE" ]; then
  if [ ! -f "$BACKUP_FILE" ]; then
    cp "$EXCLUDES_FILE" "$BACKUP_FILE"
    echo "[fix] Backed up $EXCLUDES_FILE -> $BACKUP_FILE"
  fi

  if grep -q '^path-exclude=/usr/share/man/\*$' "$EXCLUDES_FILE"; then
    sed -i 's|^path-exclude=/usr/share/man/\*$|# path-exclude=/usr/share/man/*|' "$EXCLUDES_FILE"
    echo "[fix] Enabled /usr/share/man installation in dpkg excludes"
  else
    echo "[fix] /usr/share/man is already not excluded"
  fi
else
  echo "[fix] $EXCLUDES_FILE not found; skipping excludes edit"
fi

if dpkg-divert --list /usr/bin/man | grep -q '/usr/bin/man'; then
  rm -f /usr/bin/man
  dpkg-divert --quiet --local --rename --remove /usr/bin/man || true
  echo "[fix] Removed minimized /usr/bin/man diversion"
else
  echo "[fix] No /usr/bin/man diversion found"
fi

apt-get update
apt-get install --reinstall -y man-db manpages manpages-dev tree
mandb -q

echo
echo "[fix] Complete. Verification:"
echo "  man man"
echo "  man tree"
