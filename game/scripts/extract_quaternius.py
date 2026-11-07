#!/usr/bin/env python3
"""Extract Quaternius glTF/GLB assets, or legacy FBX/OBJ packs for Godot import."""
import argparse
import json
import posixpath
import shutil
import zipfile
from pathlib import Path
from urllib.parse import unquote

parser = argparse.ArgumentParser()
parser.add_argument("--archive", required=True)
parser.add_argument("--destination", required=True)
parser.add_argument("--subdir", default="")
parser.add_argument("--include-legacy-formats", action="store_true")
parser.add_argument("--prefer-obj", action="store_true")
args = parser.parse_args()

archive = Path(args.archive)
destination = Path(args.destination)
if args.subdir:
    destination = destination / args.subdir
destination.mkdir(parents=True, exist_ok=True)

def safe_member(name: str) -> str:
    normalized = posixpath.normpath(name).lstrip("/")
    if normalized.startswith("../") or normalized == "..":
        raise ValueError(f"Unsafe archive path: {name}")
    return normalized

with zipfile.ZipFile(archive) as zf:
    names = zf.namelist()
    model_exts = {".gltf", ".glb"}
    if args.include_legacy_formats:
        model_exts.update({".fbx", ".obj"})
    models = [n for n in names if Path(n).suffix.lower() in model_exts and not n.endswith("/")]
    if args.prefer_obj:
        obj_stems = {Path(n).stem.lower() for n in names if Path(n).suffix.lower() == ".obj"}
        models = [n for n in models if not (Path(n).suffix.lower() == ".fbx" and Path(n).stem.lower() in obj_stems)]
    if not models:
        raise SystemExit("No supported 3D models found in Quaternius archive")

    required = set(models)
    for member in models:
        if member.lower().endswith(".gltf"):
            try:
                data = json.loads(zf.read(member).decode("utf-8"))
            except Exception as exc:
                raise SystemExit(f"Could not parse {member}: {exc}")
            base = posixpath.dirname(member)
            for section in ("buffers", "images"):
                for item in data.get(section, []):
                    uri = item.get("uri", "")
                    if not uri or uri.startswith("data:"):
                        continue
                    dependency = safe_member(posixpath.join(base, unquote(uri)))
                    if dependency in names:
                        required.add(dependency)

    if args.include_legacy_formats:
        # FBX/OBJ packs often keep their materials and textures beside the mesh.
        # Preserve the original folder layout so relative material paths continue working.
        for member in names:
            suffix = Path(member).suffix.lower()
            if suffix in {".mtl", ".png", ".jpg", ".jpeg", ".tga", ".webp", ".bmp", ".exr"}:
                required.add(member)

    for member in sorted(required):
        target = destination / Path(member)
        target.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(member) as source, target.open("wb") as output:
            shutil.copyfileobj(source, output)

    licenses = [n for n in names if "license" in Path(n).name.lower() or "readme" in Path(n).name.lower()]
    for member in licenses:
        target = destination / "licenses" / Path(member).name
        target.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(member) as source, target.open("wb") as output:
            shutil.copyfileobj(source, output)

print(f"Imported {len(models)} Quaternius models and {len(required) - len(models)} dependencies from {archive.name}.")
