# Quaternius CC0 asset integration

All packs below are published by Quaternius and marked CC0 on their source pages.

## 1. Stylized Nature MegaKit — Standard
- Source: https://quaternius.com/packs/stylizednaturemegakit.html
- Public archive: https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip
- 68 models in the free Standard edition; the build selects the relevant trees, bushes, flowers, grass and rocks.
- Extracted as glTF/GLB with referenced buffers and image textures.
- Used for trees, bushes, ground flora, rocks and stepping-stone paths.

## 2. LowPoly Crops Pack
- Source: https://opengameart.org/content/lowpoly-crops-pack
- Archive: https://opengameart.org/sites/default/files/nature_crops_pack_by_quaternius.zip
- Twelve selected crop families are used, with one compact OBJ model per family scaled through the growth cycle.
- Only referenced material/texture dependencies are preserved.
- Used for the crop visuals in garden beds.

## 3. LowPoly Medieval Village Pack
- Source: https://opengameart.org/content/lowpoly-medieval-village-pack
- Archive: https://opengameart.org/sites/default/files/medieval_village_pack_-_dec_2020.zip
- Quaternius medieval houses, inn, blacksmith, stable, well, fence, market stalls and props.
- The build extracts only the structures and props used in the farm; OBJ versions are used for reliable browser import.
- Used for the farmhouse, well, secondary village structures and decorative props.

## 4. LowPoly RPG Characters
- Source: https://quaternius.com/packs/rpgcharacters.html
- Archive: https://opengameart.org/sites/default/files/rpg_characters_-_nov_2020.zip
- Six fantasy character models are available.
- The Ranger OBJ is used as the player avatar; lightweight bobbing animates the avatar while walking.

## 5. LowPoly Animated Farm Animal Pack
- Source: https://opengameart.org/content/lowpoly-animated-farm-animal-pack
- Archive: https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip
- Low-poly livestock models from the pack.
- Selected static OBJ versions are imported for stable browser rendering; lightweight wandering behavior animates the animals in the valley.

## Build/import pipeline
`scripts/build_web.sh` downloads all five public CC0 archives. `scripts/extract_quaternius.py` preserves the original folder layout,
model files, MTL files and referenced textures. Godot 4.3 imports these
resources during CI. The game loads local imported scenes; it does not fetch
models from third-party hosts at runtime.

The build also runs the main scene headlessly before Web export as a startup
smoke test. Only model families used in the game are extracted from each archive to keep the Web build compact.

## Licence note
The source pages identify the packs as CC0 / Creative Commons Zero. Keep this
file with the project as provenance documentation.
