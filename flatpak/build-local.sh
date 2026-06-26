#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.github.wgh136.venera"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
BUILD_DIR="$ROOT_DIR/build/flatpak-builder"

if [[ ! -x "$BUNDLE_DIR/venera" ]]; then
  DEB_PATH="$(ls "$ROOT_DIR"/releases/venera_*_amd64.deb 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -z "$DEB_PATH" ]]; then
    echo "No Flutter Linux bundle found at $BUNDLE_DIR and no releases/venera_*_amd64.deb is available." >&2
    echo "Run 'flutter build linux --release' first, or place a local Debian package under releases/." >&2
    exit 1
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  ar p "$DEB_PATH" data.tar.zst | tar --zstd -x -C "$TMP_DIR"
  mkdir -p "$BUNDLE_DIR"
  cp -a "$TMP_DIR/usr/local/lib/venera/." "$BUNDLE_DIR/"
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub org.gnome.Platform//48 org.gnome.Sdk//48
(cd "$ROOT_DIR/flatpak" && flatpak-builder --user --install --force-clean "$BUILD_DIR" "$APP_ID.yml")

echo "Installed $APP_ID. Run it with: flatpak run $APP_ID"
