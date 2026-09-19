#!/usr/bin/env python3
"""
CHAOS LAB — Pre-Build License Validation Gate
============================================
Scans all files under assets/ and verifies each has a corresponding entry
in licenses/ASSET_MANIFEST.csv.

Usage:
    python tools/validate_licenses.py

Exit codes:
    0  — All assets licensed, build can proceed.
    1  — Unlicensed assets found, build BLOCKED.

Run this before every production export:
    python tools/validate_licenses.py && python tools/build_all_targets.py
"""

import csv
import os
import sys
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────────────

ASSET_DIR = "assets"
MANIFEST_PATH = "licenses/ASSET_MANIFEST.csv"

# File extensions that MUST be in the manifest (binaries, art, audio, fonts)
TRACKED_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".webp", ".svg",
    ".ogg", ".wav", ".mp3",
    ".ttf", ".otf", ".woff", ".woff2",
    ".glb", ".gltf", ".obj",
    ".tres", ".res",         # Godot resources that may embed external assets
}

# Extensions to skip entirely (generated or code files)
SKIP_EXTENSIONS = {
    ".import", ".uid", ".gd", ".gdshader", ".gdshaderinc",
    ".cfg", ".json", ".txt", ".md", ".csv", ".py", ".sh",
    ".godot", ".tscn",
}

# Directories to skip entirely
SKIP_DIRS = {".godot", ".git", "build", "tests", "tools", "docs"}

# Required CSV columns
REQUIRED_COLUMNS = {"path", "license"}

# ─── Helpers ──────────────────────────────────────────────────────────────────

def load_manifest(manifest_path: str) -> dict[str, dict]:
    """Load the asset manifest CSV into a dict keyed by normalized path."""
    if not os.path.exists(manifest_path):
        print(f"[WARNING] Manifest not found: {manifest_path}")
        print("          Creating empty manifest — all assets will be flagged.")
        return {}

    manifest = {}
    with open(manifest_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            print(f"[ERROR] Manifest CSV has no headers: {manifest_path}")
            sys.exit(1)

        missing_cols = REQUIRED_COLUMNS - set(reader.fieldnames)
        if missing_cols:
            print(f"[ERROR] Manifest missing required columns: {missing_cols}")
            print(f"        Found columns: {list(reader.fieldnames)}")
            sys.exit(1)

        for row in reader:
            path_key = row["path"].replace("\\", "/").strip()
            manifest[path_key] = row

    return manifest


def scan_assets(asset_dir: str) -> list[str]:
    """Walk asset_dir and return all tracked file paths (normalized)."""
    tracked = []
    for root, dirs, files in os.walk(asset_dir):
        # Prune skip directories in-place
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for fname in files:
            ext = Path(fname).suffix.lower()
            if ext in SKIP_EXTENSIONS:
                continue
            if ext not in TRACKED_EXTENSIONS and ext:
                continue  # Unknown extension — skip silently

            rel_path = os.path.join(root, fname).replace("\\", "/")
            tracked.append(rel_path)

    return sorted(tracked)


def validate(manifest: dict[str, dict], asset_files: list[str]) -> list[str]:
    """Return list of asset paths not found in the manifest."""
    violations = []
    for path in asset_files:
        if path not in manifest:
            violations.append(path)
    return violations


def check_dangerous_licenses(manifest: dict[str, dict]) -> list[str]:
    """Return list of manifest entries with dangerous/unknown licenses."""
    SAFE_LICENSES = {
        "cc0", "cc0-1.0", "cc0 1.0", "public domain",
        "mit", "ofl", "ofl-1.1",
        "apache-2.0", "apache 2.0",
        "cc-by-4.0", "cc-by 4.0",
    }
    DANGEROUS = []

    for path, row in manifest.items():
        license_val = row.get("license", "").strip().lower()
        if not license_val or license_val == "unknown":
            DANGEROUS.append(f"  UNKNOWN LICENSE: {path}")
        elif "agpl" in license_val or "gpl" in license_val and "lgpl" not in license_val:
            DANGEROUS.append(f"  COPYLEFT (GPL/AGPL): {path}  [license: {license_val}]")

    return DANGEROUS


# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    print("=" * 60)
    print("CHAOS LAB — License Validation Gate")
    print("=" * 60)

    # Resolve paths relative to project root (one level up from tools/)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    os.chdir(project_root)

    manifest = load_manifest(MANIFEST_PATH)
    print(f"  Manifest entries loaded: {len(manifest)}")

    asset_files = scan_assets(ASSET_DIR)
    print(f"  Tracked asset files found: {len(asset_files)}")

    # Check for unlicensed files
    violations = validate(manifest, asset_files)

    # Check for dangerous licenses in manifest
    dangerous = check_dangerous_licenses(manifest)

    if not violations and not dangerous:
        print()
        print("  [PASS] All assets are licensed and safe to ship.")
        print("=" * 60)
        return 0

    print()
    if violations:
        print(f"  [FAIL] {len(violations)} UNLICENSED ASSET(S) FOUND:")
        for v in violations:
            print(f"    - {v}")
        print()
        print("  ACTION REQUIRED:")
        print("    1. Add each file to licenses/ASSET_MANIFEST.csv")
        print("    2. Confirm CC0 or MIT license")
        print("    3. Re-run this script")
        print()

    if dangerous:
        print(f"  [WARN] {len(dangerous)} DANGEROUS LICENSE(S):")
        for d in dangerous:
            print(f"    {d}")
        print()
        print("  ACTION REQUIRED: Remove or replace assets with AGPL/unknown licenses.")

    print("=" * 60)
    print("  BUILD BLOCKED. Resolve all issues above before exporting.")
    print("=" * 60)
    return 1


if __name__ == "__main__":
    sys.exit(main())
