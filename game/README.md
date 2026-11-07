# Everdawn — Fantasy Farming

A cozy third-person 3D fantasy farming game built in Godot 4, targeting desktop and mobile browsers.

## World design
- Storybook green valley with a Quaternius farmhouse, barn, chicken coop, windmill, water tower, silo, well and fenced grazing paddock.
- Quaternius Stylized Nature MegaKit models populate the forest edge with trees, bushes, ground flora, rocks and stepping-stone paths.
- Quaternius LowPoly Crops models replace the procedural crop visuals and supply distinct growth stages.
- Quaternius RPG character model supplies the player avatar; Quaternius farm animals populate and wander around the paddock.
- Six garden beds support planting, timed growth, watering and harvesting.
- Keyboard and touch movement, a working title-screen button and visible on-screen mobile controls.
- Pond, farmhouse, tree, rock, fence and world-boundary collision keep the player in the playable area.

## Quaternius asset packs
The Vercel build downloads and imports six free CC0 packs:
1. **Stylized Nature MegaKit — Standard:** 68 glTF/GLB models with referenced buffers and textures.
2. **LowPoly Crops Pack:** crop models with multiple plant families and growth stages.
3. **LowPoly Medieval Buildings:** modular medieval building models.
4. **LowPoly Medieval Village Pack:** complete village buildings and props used for the farmhouse, well, secondary structures and decorative village details.
5. **LowPoly RPG Characters:** fantasy character models; OBJ versions are used for reliable browser import.
6. **LowPoly Animated Farm Animal Pack:** livestock models (cow, sheep, pig, horse, llama and dog); OBJ versions are used for reliable browser import.

The build downloads all five packs from their public CC0 archives. The extractor preserves model dependencies, MTL files and textures, and deduplicates FBX/OBJ variants. Godot imports assets locally during CI; the running game does not fetch models from third-party hosts. The build filters each pack to the model families actually used in the game, keeping the browser download and import size manageable.

## Licensing
The source pages identify these Quaternius packs as CC0. See:
- https://quaternius.com/packs/stylizednaturemegakit.html
- https://opengameart.org/content/lowpoly-crops-pack
- https://opengameart.org/content/lowpoly-medieval-buildings
- https://quaternius.com/packs/farmbuildings.html
- https://opengameart.org/content/lowpoly-rpg-characters
- https://opengameart.org/content/lowpoly-animated-farm-animal-pack

## Run locally
Open `game/` in Godot 4.3+ and press F6/F5. Main scene: `scenes/main.tscn`.

## Browser build
Vercel builds the Godot Web export using `scripts/build_web.sh`. It downloads the six CC0 packs, imports them, runs a headless main-scene smoke test, then exports the browser game to `build/web`.

## Controls
- Desktop: WASD / arrow keys; E to plant, water and harvest.
- Mobile: on-screen directional pad and TEND button.
