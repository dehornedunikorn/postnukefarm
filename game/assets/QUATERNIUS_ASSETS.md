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

## 4. Farm Buildings Pack
- Source: https://quaternius.com/packs/farmbuildings.html
- Public creator folder: https://drive.google.com/drive/folders/1gdZ39vcLML_ULU5sHirkKQ-gEkk458Ak?usp=sharing
- 13 farm structures and props: barns, silo house, silo, windmill, water tower, chicken coop, well and fences.
- Downloaded from the public Google Drive folder with gdown; FBX/Blend files are discarded and OBJ models are imported.
- Used for the farmhouse, barn, coop, well, fence, windmill, water tower and silo.

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
`scripts/build_web.sh` downloads the five public archives and the Farm Buildings
folder. `scripts/extract_quaternius.py` preserves the original folder layout,
model files, MTL files and referenced textures. Godot 4.3 imports these
resources during CI. The game loads local imported scenes; it does not fetch
models from third-party hosts at runtime.

The build also runs the main scene headlessly before Web export as a startup
smoke test. If the public Farm Buildings folder is unavailable, the modular
medieval kit remains available as a fallback.

## Licence note
The source pages identify the packs as CC0 / Creative Commons Zero. Keep this
file with the project as provenance documentation.
