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

download() {
    local url="$1"
    local output="$2"
    echo "Downloading $(basename "$output")..."
    curl --fail --location --silent --show-error \
        --connect-timeout 20 --max-time 180 --retry 3 --retry-delay 2 \
        "$url" -o "$output"
    test -s "$output"
}

mkdir -p "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
mkdir -p build/web assets/quaternius

# Quaternius Stylized Nature MegaKit Standard: 68 glTF/GLB models.
download "https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip" "$TMP_DIR/quaternius.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius.zip" --destination assets/quaternius --include "tree,pine,birch,bush,shrub,clover,flower,grass,plant,rock,pathrock"

# Quaternius LowPoly Crops Pack: crop families and growth stages.
download "https://opengameart.org/sites/default/files/nature_crops_pack_by_quaternius.zip" "$TMP_DIR/quaternius-crops.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-crops.zip" --destination assets/quaternius --subdir crops --include-legacy-formats --prefer-obj --include "apple,carrot,corn,lettuce,pumpkin,wheat,tomato,rice,mushroom,watermelon,beet,bamboo,bushberries"

# Quaternius LowPoly RPG Characters: six rigged fantasy avatars.
download "https://opengameart.org/sites/default/files/rpg_characters_-_nov_2020.zip" "$TMP_DIR/quaternius-characters.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-characters.zip" --destination assets/quaternius --subdir characters --include-legacy-formats --prefer-obj --include "warrior,ranger,wizard,monk,cleric,rogue"

# Quaternius LowPoly Medieval Village Pack: complete buildings and village props.
download "https://opengameart.org/sites/default/files/medieval_village_pack_-_dec_2020.zip" "$TMP_DIR/quaternius-village.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-village.zip" --destination assets/quaternius --subdir village --include-legacy-formats --prefer-obj --list-models --include "house_1,house_2,house_3,house_4,inn,blacksmith,mill,sawmill,stable,fence,well,gazebo,marketstand_1,marketstand_2,cart,barrel,crate,hay,bell_tower,bonfire_lit"

# Quaternius LowPoly Animated Farm Animals: static OBJ geometry for browser stability.
download "https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip" "$TMP_DIR/quaternius-animals.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-animals.zip" --destination assets/quaternius --subdir animals --include-legacy-formats --prefer-obj --include "cow,sheep,pig,horse,llama,dog"

download "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" "$TMP_DIR/godot.zip"
unzip -q "$TMP_DIR/godot.zip" -d "$TMP_DIR/godot"
GODOT_BIN="$(find "$TMP_DIR/godot" -maxdepth 1 -type f -name 'Godot*' | head -n 1)"
chmod +x "$GODOT_BIN"

download "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" "$TMP_DIR/templates.tpz"
unzip -q "$TMP_DIR/templates.tpz" -d "$TMP_DIR/templates"
cp -R "$TMP_DIR/templates/templates/." "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable/"

echo "Importing all Quaternius assets in Godot..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --import 2>&1 | tee "$TMP_DIR/import.log"
if grep -Eq "^(ERROR:|SCRIPT ERROR:|Parse Error:)" "$TMP_DIR/import.log"; then
    echo "Godot asset import reported errors; refusing to export."
    exit 1
fi

echo "Running headless main-scene smoke test..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 3 2>&1 | tee "$TMP_DIR/smoke.log"
python3 - "$TMP_DIR/smoke.log" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
for index, line in enumerate(lines):
    if line.startswith("SCRIPT ERROR:") or line.startswith("Parse Error:"):
        print("Fatal Godot script/parse error:", line)
        sys.exit(1)
    if line.startswith("ERROR:"):
        following = lines[index + 1] if index + 1 < len(lines) else ""
        # Godot's headless Dummy renderer has no GPU mesh storage; these
        # null-RID diagnostics are expected in CI and do not affect WebGL.
        if "mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)" in following:
            continue
        print("Unexpected Godot runtime error:", line)
        sys.exit(1)
PY

echo "Exporting Godot Web build..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Web" "$PROJECT_DIR/build/web/index.html"
test -s "$PROJECT_DIR/build/web/index.html"
echo "Everdawn Web export completed successfully."
