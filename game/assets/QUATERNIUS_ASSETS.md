# Quaternius asset integration

Pack: Quaternius Stylized Nature MegaKit — Standard
Creator: Quaternius
License: CC0 1.0 Universal
Official pack page: https://quaternius.com/packs/stylizednaturemegakit.html
Free Standard archive: https://opengameart.org/sites/default/files/stylized_nature_megakitstandard.zip
The Standard archive contains 68 models from the full 116-model pack.

## Import pipeline

The Vercel/Godot build downloads the official Standard ZIP and runs
`scripts/extract_quaternius.py`. The extractor keeps glTF/GLB models and
only their referenced texture and buffer files, excluding duplicate FBX/OBJ
and Blender source formats. Assets are imported into
`res://assets/quaternius/` before Godot exports the game.

The game loads the Quaternius tree and bush models as PackedScenes and
instances them around the farm. The archive is not stored as a binary ZIP in
GitHub; it is retrieved from the public CC0 source during CI.

## Additional notes

- The nature pack provides foliage, plants, rocks and other nature pieces; it
  does not contain a farmer character or farmhouse.
- The farmer, farmhouse trim, garden frames, well and fence in this slice are
  original hand-built geometry rather than third-party stock assets.
- The original Quaternius license is CC0, allowing personal, educational and
  commercial use without attribution requirements.
