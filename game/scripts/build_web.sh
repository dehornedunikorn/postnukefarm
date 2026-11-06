#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.3"
GODOT_TAG="4.3-stable"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
mkdir -p build/web

curl -fsSL "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o "$TMP_DIR/godot.zip"
unzip -q "$TMP_DIR/godot.zip" -d "$TMP_DIR/godot"
GODOT_BIN="$(find "$TMP_DIR/godot" -maxdepth 1 -type f -name 'Godot*' | head -n 1)"
chmod +x "$GODOT_BIN"

curl -fsSL "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o "$TMP_DIR/templates.tpz"
unzip -q "$TMP_DIR/templates.tpz" -d "$TMP_DIR/templates"
cp -R "$TMP_DIR/templates/templates/." "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable/"

"$GODOT_BIN" --headless --path . --editor --import
"$GODOT_BIN" --headless --path . --export-release "Web" build/web/index.html
test -s build/web/index.html
