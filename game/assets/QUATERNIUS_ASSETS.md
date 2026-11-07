# Quaternius CC0 asset integration

All packs below are published by Quaternius and marked CC0 on their source pages.

## 1. Stylized Nature MegaKit — Standard
- Source: https://quaternius.com/packs/stylizednaturemegakit.html
- Public archive: https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip
- 68 models in the free Standard edition.
- Extracted as glTF/GLB with referenced buffers and image textures.
- Used for trees, bushes, ground flora, rocks and stepping-stone paths.

## 2. LowPoly Crops Pack
- Source: https://opengameart.org/content/lowpoly-crops-pack
- Archive: https://opengameart.org/sites/default/files/nature_crops_pack_by_quaternius.zip
- Crop models include multiple plant families and growth stages.
- OBJ meshes and their material/texture files are preserved.
- Used for the crop visuals in garden beds.

## 3. LowPoly Medieval Buildings
- Source: https://opengameart.org/content/lowpoly-medieval-buildings
- Archive: https://opengameart.org/sites/default/files/Modular%20Medieval%20Pack%20by%20%40Quaternius_0.zip
- Modular medieval building kit, OBJ.
- Provides a fallback village architecture set.

## 4. LowPoly Medieval Village Pack
- Source: https://opengameart.org/content/lowpoly-medieval-village-pack
- Archive: https://opengameart.org/sites/default/files/medieval_village_pack_-_dec_2020.zip
- Complete Quaternius medieval buildings and village props in FBX, OBJ and Blend formats.
- OBJ versions are used for reliable browser import.
- Used for the farmhouse, well, secondary village structures and decorative props.

## 5. LowPoly RPG Characters
- Source: https://quaternius.com/packs/rpgcharacters.html
- Archive: https://opengameart.org/sites/default/files/rpg_characters_-_nov_2020.zip
- Six fantasy character models.
- OBJ versions are used as the player avatar for stable browser import; lightweight bobbing animates the avatar while walking.

## 6. LowPoly Animated Farm Animal Pack
- Source: https://opengameart.org/content/lowpoly-animated-farm-animal-pack
- Archive: https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip
- Cow, sheep, pig, horse, llama and dog models.
- Static OBJ versions are imported for stable browser rendering; a lightweight wandering behavior animates the animals in the valley.

## Build/import pipeline
`scripts/build_web.sh` downloads all six public CC0 archives. `scripts/extract_quaternius.py` preserves the original folder layout,
model files, MTL files and referenced textures. Godot 4.3 imports these
resources during CI. The game loads local imported scenes; it does not fetch
models from third-party hosts at runtime.

The build also runs the main scene headlessly before Web export as a startup
smoke test. The Modular Medieval Buildings kit supplies additional pieces alongside the complete village assets.

## Licence note
The source pages identify the packs as CC0 / Creative Commons Zero. Keep this
file with the project as provenance documentation.
