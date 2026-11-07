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

# Quaternius Farm Buildings Pack (CC0). Download its public OBJ/MTL files
# directly by file ID; the public Drive folder itself is quota-limited.
download_drive_file() {
    local file_id="$1"
    local output="$2"
    mkdir -p "$(dirname "$output")"
    local browser_ua="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36"
    local urls=(
        "https://drive.usercontent.google.com/download?id=${file_id}&export=download&authuser=0&confirm=t"
        "https://drive.google.com/uc?export=download&id=${file_id}"
        "https://drive.google.com/uc?id=${file_id}"
    )
    echo "Downloading Quaternius farm model $(basename "$output")..."
    for url in "${urls[@]}"; do
        if curl --fail --location --silent --show-error --user-agent "$browser_ua" \
            --connect-timeout 10 --max-time 20 \
            "$url" -o "$output"; then
            if test -s "$output" && ! head -c 256 "$output" | grep -qiE '<!doctype|<html|Google Drive'; then
                return 0
            fi
        fi
    done
    rm -f "$output"
    return 1
}

FARM_FILES=(
    "1c18wNK6jsQNnLlOtbHsQE2ZU025jOJZC:Barn.obj"
    "1Hq_4mGFXOSN8LSn7Bc8Uqclsd1iC1mcw:Barn.mtl"
    "1-pDoMboAo2NOSwfVi05o45g_WpI8p3Eq:BigBarn.obj"
    "1GTM3qVnqpfoLdAUlLwh5t3Nl5nWzuedw:BigBarn.mtl"
    "1ws9VQJWiBfO7Fn7OqacLuPUhMc_mD2zj:ChickenCoop.obj"
    "120sN8cICfopdALdgOPok9y6kBli5ZbO_:ChickenCoop.mtl"
    "1c67vRQU0fq_BFkQvbPLnrSs9jMOhxLMq:Fence.obj"
    "1BflcIA_GP8VhbrNjCLbte2oYpCEJUMpn:Fence.mtl"
    "1WdM8UaQWUqEUFAdaNIfojuD5-OrgLpuo:Fence2.obj"
    "1D4xSTXeRrBeZmsMsefdbxX7XqYJBG5w_:Fence2.mtl"
    "1jH7mW0J8yLQFJ2meQ665UgM6qCZO7txg:OpenBarn.obj"
    "1oF4PBxaiHvruUfdxcZZmlLauxPyn6LFx:OpenBarn.mtl"
    "1ymV-FNVd3YOUVEg40wrE2rHhdsl4x_z6:Silo.obj"
    "19ySIiVmR1FiYKeyvfyWAkXKF80shvmHd:Silo.mtl"
    "1UCyp7flVDLk7Gw44XynAuTv4maaD159W:Silo_House.obj"
    "1sRvY5n47pjHzBhhv21cuKfdWI6kF8fR3:Silo_House.mtl"
    "1JziZu1iGnyIcn8MyZy6oYML06_4EGsn:SmallBarn.obj"
    "18yIBY_zGV8b_VmZnkceN_s3ppY-LGpHa:SmallBarn.mtl"
    "1pAck0BU91yY6J7wb8J08oDnOqwHic0Ro:TowerWindmill.obj"
    "11589R78Oq5zX0eZ-H1-CEZNBYKF2zOcn:TowerWindmill.mtl"
    "17UrBt3T5Sq9FUfhsojfWmm_FylEHDXfo:WaterTower.obj"
    "1mpDj4Lf26X4kEMrz6srJd8Zm7TMglF-l:WaterTower.mtl"
    "19Ku-AHLDBuzkZgbPlThNkaqOrTzmSse7:Well.obj"
    "1mv3XGu6aMLfM3-zmYnXj-qVmuulwp_D3:Well.mtl"
    "1nGFuPQaYpTPNJh0F9rAGxvJ49DowUVz5:Windmill.obj"
    "1BCDCFCGqix4NM9QhESbjzOnX-vf9YQX9:Windmill.mtl"
)
FARM_MODEL_COUNT=0
for item in "${FARM_FILES[@]}"; do
    file_id="${item%%:*}"
    filename="${item#*:}"
    if download_drive_file "$file_id" "assets/quaternius/farm_buildings/OBJ/$filename"; then
        if [[ "$filename" == *.obj ]]; then
            FARM_MODEL_COUNT=$((FARM_MODEL_COUNT + 1))
        fi
    else
        echo "Farm Buildings direct download blocked at $filename; stop retrying the quota-limited folder."
        break
    fi
done
echo "Downloaded $FARM_MODEL_COUNT Quaternius Farm Buildings OBJ models."

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
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --import 2>&1 | tee "$TMP_DIR/import.log"
if grep -Eq "^(ERROR:|SCRIPT ERROR:|Parse Error:)" "$TMP_DIR/import.log"; then
    echo "Godot asset import reported errors; refusing to export."
    exit 1
fi

echo "Running headless main-scene smoke test..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 3 2>&1 | tee "$TMP_DIR/smoke.log"
if grep -Eq "^(ERROR:|SCRIPT ERROR:|Parse Error:)" "$TMP_DIR/smoke.log"; then
    echo "Godot startup smoke test reported errors; refusing to export."
    exit 1
fi

echo "Exporting Godot Web build..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Web" "$PROJECT_DIR/build/web/index.html"
test -s "$PROJECT_DIR/build/web/index.html"
echo "Everdawn Web export completed successfully."
