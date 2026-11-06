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

## Planned art integration
The world currently uses procedural placeholder meshes so the project runs immediately. Import the CC0 Quaternius Stylized Nature MegaKit and replace the tree placeholders with its GLB scenes. Keep the downloaded pack's original license file in `assets/licenses/`.

Asset source: https://quaternius.com/packs/stylizednature.html

## Browser + mobile
The target is a Godot Web export served as a static site by Vercel. The project uses the GL Compatibility renderer because Godot Web exports require a compatible rendering path. Mobile browsers use the on-screen controls; desktop browsers use WASD/arrows and E.
