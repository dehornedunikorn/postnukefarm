# Everdawn — Fantasy Farming

A cozy third-person 3D fantasy farming game built in Godot 4, targeting desktop and mobile browsers.

## World design
- Storybook green valley with a farmhouse area, pond, winding paths, timber boundaries, a well and warm lantern lighting.
- Quaternius Stylized Nature MegaKit CC0 models populate the forest edge with trees, bushes, ground flora and rocks.
- Quaternius LowPoly Crops Pack CC0 models replace the procedural crop placeholders and supply distinct growth-stage visuals.
- Quaternius LowPoly Medieval Buildings CC0 pack is bundled for the village/building environment.
- Six garden beds support planting, timed growth, watering and harvesting.
- Keyboard and touch movement, plus an on-screen touch action button.

## Quaternius asset packs
The Vercel build downloads and imports three free CC0 packs:
1. **Stylized Nature MegaKit — Standard:** 68 models in glTF/GLB format, with referenced buffers and textures.
2. **LowPoly Crops Pack:** FBX/OBJ crop models, including multiple plant types and growth stages.
3. **LowPoly Medieval Buildings:** modular medieval building models in FBX/OBJ format.

The extractor preserves relative file paths and material textures. Godot imports the models locally during CI; the running game does not fetch models from third-party hosts. The build also deduplicates identical FBX/OBJ variants before instancing assets.

## Licensing
The source pack pages identify these Quaternius assets as CC0. See:
- https://quaternius.com/packs/stylizednaturemegakit.html
- https://opengameart.org/content/lowpoly-crops-pack
- https://opengameart.org/content/lowpoly-medieval-buildings

## Run locally
Open `game/` in Godot 4.3+ and press F6/F5. Main scene: `scenes/main.tscn`.

## Browser build
Vercel builds the Godot Web export using `scripts/build_web.sh`. The build downloads the three CC0 archives, imports them, runs a headless main-scene smoke test, then exports the browser game to `build/web`.

## Controls
- Desktop: WASD / arrow keys; E to plant, water and harvest.
- Mobile: on-screen directional pad and TEND button.
