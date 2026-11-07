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
parser.add_argument("--list-models", action="store_true")
parser.add_argument("--include", default="", help="Comma-separated filename fragments to keep")
parser.add_argument("--exclude", default="", help="Comma-separated filename fragments to exclude")
parser.add_argument("--one-per-prefix", action="store_true")
parser.add_argument("--max-per-pattern", default="", help="Comma-separated pattern:count pairs")
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
    if args.include:
        patterns = [part.strip().lower() for part in args.include.split(",") if part.strip()]
        models = [n for n in models if any(pattern in Path(n).stem.lower() for pattern in patterns)]
    if args.exclude:
        patterns = [part.strip().lower() for part in args.exclude.split(",") if part.strip()]
        models = [n for n in models if not any(pattern in Path(n).stem.lower() for pattern in patterns)]
    if args.prefer_obj:
        obj_stems = {Path(n).stem.lower() for n in names if Path(n).suffix.lower() == ".obj"}
        models = [n for n in models if not (Path(n).suffix.lower() == ".fbx" and Path(n).stem.lower() in obj_stems)]
    if args.one_per_prefix:
        seen_prefixes = set()
        selected = []
        for member in sorted(models):
            prefix = Path(member).stem.lower().split("_")[0]
            if prefix not in seen_prefixes:
                seen_prefixes.add(prefix)
                selected.append(member)
        models = selected
    if args.max_per_pattern:
        limits = []
        for item in args.max_per_pattern.split(","):
            if ":" in item:
                pattern, count = item.split(":", 1)
                limits.append((pattern.strip().lower(), int(count)))
        counts = {pattern: 0 for pattern, _ in limits}
        selected = []
        for member in sorted(models):
            stem = Path(member).stem.lower()
            for pattern, limit in limits:
                if pattern in stem:
                    if counts[pattern] < limit:
                        selected.append(member)
                    counts[pattern] += 1
                    break
        models = selected
    if not models:
        raise SystemExit("No supported 3D models found in Quaternius archive")

    required = set(models)
    for member in models:
        base = posixpath.dirname(member)
        if member.lower().endswith(".gltf"):
            try:
                data = json.loads(zf.read(member).decode("utf-8"))
            except Exception as exc:
                raise SystemExit(f"Could not parse {member}: {exc}")
            for section in ("buffers", "images"):
                for item in data.get(section, []):
                    uri = item.get("uri", "")
                    if not uri or uri.startswith("data:"):
                        continue
                    dependency = safe_member(posixpath.join(base, unquote(uri)))
                    if dependency in names:
                        required.add(dependency)
        elif member.lower().endswith(".obj"):
            try:
                obj_text = zf.read(member).decode("utf-8", errors="ignore")
            except Exception:
                obj_text = ""
            for line in obj_text.splitlines():
                parts = line.strip().split()
                if len(parts) >= 2 and parts[0].lower() == "mtllib":
                    mtl_path = safe_member(posixpath.join(base, " ".join(parts[1:])))
                    if mtl_path in names:
                        required.add(mtl_path)
                        try:
                            mtl_text = zf.read(mtl_path).decode("utf-8", errors="ignore")
                        except Exception:
                            mtl_text = ""
                        texture_keys = {"map_kd", "map_ka", "map_ks", "map_bump", "bump", "disp", "decal", "norm", "map_d", "map_ns"}
                        for mtl_line in mtl_text.splitlines():
                            mtl_parts = mtl_line.strip().split()
                            if len(mtl_parts) >= 2 and mtl_parts[0].lower() in texture_keys:
                                texture_path = safe_member(posixpath.join(posixpath.dirname(mtl_path), mtl_parts[-1]))
                                if texture_path in names:
                                    required.add(texture_path)

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
if args.list_models:
    for member in sorted(models):
        print("QUATERNIUS_MODEL:" + Path(member).stem)
