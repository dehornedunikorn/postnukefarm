#!/usr/bin/env bash
set -euo pipefail

# Vercel invokes this script from the repository root. Always export the
# actual Godot project in /game, not the legacy Python prototype at repo root.
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GODOT_VERSION="4.3"
GODOT_TAG="4.3-stable"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
mkdir -p build/web assets/quaternius

# Pull the free CC0 Quaternius Standard pack during CI. Keep only glTF/GLB
# meshes and the textures/buffers they reference, not duplicate FBX/OBJ/Blend files.
curl -fsSL "https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip" -o "$TMP_DIR/quaternius.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius.zip" --destination assets/quaternius

# Quaternius LowPoly Crops Pack (CC0): 100+ crop models and growth stages.
curl -fsSL "https://opengameart.org/sites/default/files/nature_crops_pack_by_quaternius.zip" -o "$TMP_DIR/quaternius-crops.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-crops.zip" --destination assets/quaternius --subdir crops --include-legacy-formats

# Quaternius LowPoly Medieval Buildings (CC0): modular village structures.
curl -fsSL "https://opengameart.org/sites/default/files/Modular%20Medieval%20Pack%20by%20%40Quaternius_0.zip" -o "$TMP_DIR/quaternius-buildings.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-buildings.zip" --destination assets/quaternius --subdir buildings --include-legacy-formats --prefer-obj

# Quaternius LowPoly RPG Characters (CC0): six rigged fantasy avatars.
curl -fsSL "https://opengameart.org/sites/default/files/rpg_characters_-_nov_2020.zip" -o "$TMP_DIR/quaternius-characters.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-characters.zip" --destination assets/quaternius --subdir characters --include-legacy-formats

# Quaternius LowPoly Animated Farm Animal Pack (CC0); OBJ geometry avoids FBX rig import issues.
curl -fsSL "https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip" -o "$TMP_DIR/quaternius-animals.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-animals.zip" --destination assets/quaternius --subdir animals --include-legacy-formats --prefer-obj

curl -fsSL "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o "$TMP_DIR/godot.zip"
unzip -q "$TMP_DIR/godot.zip" -d "$TMP_DIR/godot"
GODOT_BIN="$(find "$TMP_DIR/godot" -maxdepth 1 -type f -name 'Godot*' | head -n 1)"
chmod +x "$GODOT_BIN"

curl -fsSL "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o "$TMP_DIR/templates.tpz"
unzip -q "$TMP_DIR/templates.tpz" -d "$TMP_DIR/templates"
cp -R "$TMP_DIR/templates/templates/." "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable/"

"$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --import
# Smoke-test the main scene before exporting so GDScript/runtime startup errors
# fail the deployment instead of shipping a broken canvas.
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 3
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Web" "$PROJECT_DIR/build/web/index.html"
test -s "$PROJECT_DIR/build/web/index.html"
