# Everdawn — Fantasy Farming Sim

A Godot 4 3D farming prototype designed for desktop and mobile browsers.

## Current prototype
- 3D valley, forest edge, cottage, pond, paths and lanterns
- Third-person character movement
- Six interactive garden beds: plant → grow → harvest
- Keyboard controls and on-screen mobile controls
- Lightweight GL Compatibility renderer

## Run locally
Open this folder in Godot 4.3+ and press F6/F5. Main scene: `scenes/main.tscn`.

## Browser build
Vercel builds the Godot Web export using `scripts/build_web.sh` and serves `build/web`. Desktop browsers use WASD/arrows and E; mobile browsers use the on-screen directional pad and Use button.

## Art integration
The world currently uses procedural meshes as a working greybox. Next step is importing the CC0 Quaternius Stylized Nature MegaKit and replacing the placeholder tree silhouettes with its GLB scenes. Keep the original license file in `assets/licenses/`.

Asset source: https://quaternius.com/packs/stylizednature.html
