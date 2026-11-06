# Everdawn — Fantasy Farming

A cozy third-person 3D fantasy farming game built in Godot 4, targeting desktop and mobile browsers.

## World design
- A storybook green valley with a farmhouse, pond, winding dirt lanes, timber fence, well and lanterns.
- Quaternius Stylized Nature MegaKit tree and bush models are loaded as GLB scenes and instanced throughout the forest edge.
- Original hand-built farmer avatar, farmhouse details, farm beds and props.
- Six framed garden beds with plant → grow → harvest loop.
- Keyboard and touch movement, plus a large touch action button.

## Quaternius assets
The environment uses Quaternius Stylized Nature MegaKit CC0 models:
- Common tree variants and common bush.
- The public mirror used for the current GLB runtime imports is documented in `assets/QUATERNIUS_ASSETS.md`.
- Quaternius assets are CC0; the original creator's license terms permit personal, educational and commercial use.

The public Standard pack includes 68 of the 116 models; the complete Source version adds the full set and prebuilt engine projects. This project currently integrates the accessible tree/bush GLBs; it does not claim to contain the full 116-model Source pack.

## Run locally
Open `game/` in Godot 4.3+ and press F6/F5. Main scene: `scenes/main.tscn`.

## Browser build
Vercel builds the Godot Web export using `scripts/build_web.sh` and serves `build/web`. A live network connection is required the first time the Quaternius GLBs load. If the external model host is unavailable, the playable farm remains available but the imported forest will not appear.

## Controls
- Desktop: WASD / arrow keys; E to plant, grow or harvest.
- Mobile: on-screen directional pad and TEND button.
