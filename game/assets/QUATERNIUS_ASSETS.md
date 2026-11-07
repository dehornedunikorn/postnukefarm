# Quaternius CC0 asset integration

All packs below are published by Quaternius and marked CC0 on their source pages.

## 1. Stylized Nature MegaKit — Standard
- Source: https://quaternius.com/packs/stylizednaturemegakit.html
- Public archive mirror: https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip
- 68 models in the free Standard edition.
- Extracted as glTF/GLB with referenced buffers and image textures.
- Used for trees, bushes, ground flora and rocks.

## 2. LowPoly Crops Pack
- Source: https://opengameart.org/content/lowpoly-crops-pack
- Archive: https://opengameart.org/sites/default/files/nature_crops_pack_by_quaternius.zip
- Crop models include multiple plant families and growth stages.
- FBX/OBJ meshes and their material/texture files are preserved.
- Used for the crop visuals in garden beds.

## 3. LowPoly Medieval Buildings
- Source: https://opengameart.org/content/lowpoly-medieval-buildings
- Archive: https://opengameart.org/sites/default/files/Modular%20Medieval%20Pack%20by%20%40Quaternius_0.zip
- Modular medieval building kit, FBX/OBJ.
- Bundled for the village/farm building environment.

## Build/import pipeline
`scripts/build_web.sh` downloads the archives and runs
`scripts/extract_quaternius.py`. The extractor preserves the original folder
layout, model files, MTL files and referenced textures. Godot 4.3 imports
these resources during CI. The game then loads the local imported scenes;
there are no runtime third-party asset downloads.

The build also runs the main scene headlessly before Web export as a startup
smoke test.

## Licence note
The source pages identify the packs as CC0 / Creative Commons Zero. CC0 permits
reuse, modification and redistribution, including commercial use. Keep this
file with the project as provenance documentation.
