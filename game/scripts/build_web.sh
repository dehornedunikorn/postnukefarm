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
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius.zip" --destination assets/quaternius

# Quaternius LowPoly Crops Pack: crop families and growth stages.
download "https://opengameart.org/sites/default/files/nature_crops_pack_by_quaternius.zip" "$TMP_DIR/quaternius-crops.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-crops.zip" --destination assets/quaternius --subdir crops --include-legacy-formats --prefer-obj

# Quaternius LowPoly Medieval Buildings: modular village structures.
download "https://opengameart.org/sites/default/files/Modular%20Medieval%20Pack%20by%20%40Quaternius_0.zip" "$TMP_DIR/quaternius-buildings.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-buildings.zip" --destination assets/quaternius --subdir buildings --include-legacy-formats --prefer-obj

# Quaternius LowPoly RPG Characters: six rigged fantasy avatars.
download "https://opengameart.org/sites/default/files/rpg_characters_-_nov_2020.zip" "$TMP_DIR/quaternius-characters.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-characters.zip" --destination assets/quaternius --subdir characters --include-legacy-formats --prefer-obj

# Quaternius LowPoly Farm Buildings (CC0), hosted in the creator's public Drive folder.
# gdown handles the public folder listing and downloads the individual OBJ/MTL assets.
echo "Downloading Quaternius farm buildings..."
if python3 -m pip install --quiet --disable-pip-version-check gdown; then
    if python3 - <<'PY'
import gdown
import sys
url = "https://drive.google.com/drive/folders/1gdZ39vcLML_ULU5sHirkKQ-gEkk458Ak?usp=sharing"
files = gdown.download_folder(url, output="assets/quaternius/farm_buildings", quiet=False, use_cookies=False)
if not files:
    sys.exit(1)
print(f"Downloaded {len(files)} Quaternius farm-building files.")
PY
    then
        find assets/quaternius/farm_buildings -type f -iname '*.fbx' -delete
        find assets/quaternius/farm_buildings -type f -iname '*.blend' -delete
        echo "Prepared Quaternius farm-building OBJ assets."
    else
        echo "Farm Buildings Drive folder could not be fetched; keeping the modular medieval Quaternius kit."
    fi
else
    echo "gdown unavailable; keeping the modular medieval Quaternius kit."
fi

# Quaternius LowPoly Animated Farm Animals: static OBJ geometry for browser stability.
download "https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip" "$TMP_DIR/quaternius-animals.zip"
python3 scripts/extract_quaternius.py --archive "$TMP_DIR/quaternius-animals.zip" --destination assets/quaternius --subdir animals --include-legacy-formats --prefer-obj

download "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" "$TMP_DIR/godot.zip"
unzip -q "$TMP_DIR/godot.zip" -d "$TMP_DIR/godot"
GODOT_BIN="$(find "$TMP_DIR/godot" -maxdepth 1 -type f -name 'Godot*' | head -n 1)"
chmod +x "$GODOT_BIN"

download "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" "$TMP_DIR/templates.tpz"
unzip -q "$TMP_DIR/templates.tpz" -d "$TMP_DIR/templates"
cp -R "$TMP_DIR/templates/templates/." "$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable/"

echo "Importing all Quaternius assets in Godot..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --import

echo "Running headless main-scene smoke test..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 3

echo "Exporting Godot Web build..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Web" "$PROJECT_DIR/build/web/index.html"
test -s "$PROJECT_DIR/build/web/index.html"
echo "Everdawn Web export completed successfully."
