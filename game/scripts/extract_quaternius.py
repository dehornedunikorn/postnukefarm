#!/usr/bin/env python3
"""Extract only Quaternius glTF models and their referenced files from the CC0 Standard archive."""
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
args = parser.parse_args()

archive = Path(args.archive)
destination = Path(args.destination)
destination.mkdir(parents=True, exist_ok=True)

def safe_member(name: str) -> str:
    normalized = posixpath.normpath(name).lstrip("/")
    if normalized.startswith("../") or normalized == "..":
        raise ValueError(f"Unsafe archive path: {name}")
    return normalized

with zipfile.ZipFile(archive) as zf:
    names = zf.namelist()
    models = [n for n in names if Path(n).suffix.lower() in (".gltf", ".glb")]
    if not models:
        raise SystemExit("No glTF/GLB models found in Quaternius archive")

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

print(f"Imported {len(models)} Quaternius glTF/GLB models and {len(required) - len(models)} dependencies.")
