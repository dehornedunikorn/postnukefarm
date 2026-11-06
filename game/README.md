# Everdawn — Fantasy Farming

A cozy third-person 3D fantasy farming game built in Godot 4, targeting desktop and mobile browsers.

## World design
- A storybook green valley with a farmhouse, pond, winding dirt lanes, timber fence, well and lanterns.
- The free Quaternius Stylized Nature MegaKit Standard archive is fetched in CI; its glTF/GLB models and referenced textures are imported locally, then tree and bush models are instanced throughout the forest edge.
- Original hand-built farmer avatar, farmhouse details, farm beds and props.
- Six framed garden beds with plant → grow → harvest loop.
- Keyboard and touch movement, plus a large touch action button.

## Quaternius assets
The environment uses Quaternius Stylized Nature MegaKit CC0 models:
- Common tree variants and common bush.
- The build script downloads the official CC0 Standard ZIP from OpenGameArt and selectively extracts glTF/GLB models plus their texture/buffer dependencies into `assets/quaternius/`.
- Quaternius assets are CC0; the original creator's license terms permit personal, educational and commercial use.

The public Standard pack includes 68 of the 116 models; the complete Source version adds the full set and prebuilt engine projects. This project currently integrates the accessible tree/bush GLBs; it does not claim to contain the full 116-model Source pack.

## Run locally
Open `game/` in Godot 4.3+ and press F6/F5. Main scene: `scenes/main.tscn`.

## Browser build
Vercel builds the Godot Web export using `scripts/build_web.sh` and serves `build/web`. The build downloads the Quaternius archive and packages its selected glTF assets locally, so the running game does not need to fetch the trees from a third-party host.

## Controls
- Desktop: WASD / arrow keys; E to plant, grow or harvest.
- Mobile: on-screen directional pad and TEND button.
