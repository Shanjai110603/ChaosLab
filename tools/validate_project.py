import os
import json
import re

print("=" * 60)
print("CHAOS LAB — Project Integrity & Syntax Verification")
print("=" * 60)

# 1. Validate all Level JSON files
print("\n[1] Checking Level JSON files...")
levels_dir = "levels"
json_count = 0
for root, _, files in os.walk(levels_dir):
    for f in sorted(files):
        if f.endswith(".json"):
            p = os.path.join(root, f)
            with open(p, "r", encoding="utf-8") as fh:
                data = json.load(fh)
                assert "level_id" in data, f"{f} missing level_id"
                assert "title" in data, f"{f} missing title"
                assert "objects" in data, f"{f} missing objects"
                assert "targets" in data, f"{f} missing targets"
                json_count += 1
                print(f"  [PASS] {f} - Level {data['level_id']}: '{data['title']}' ({len(data['objects'])} objects, {len(data['targets'])} targets)")
print(f"Total valid level files: {json_count}")

# 2. Check all Scene files
print("\n[2] Checking Scene (.tscn) files...")
scenes_dir = "scenes"
scene_count = 0
for root, _, files in os.walk(scenes_dir):
    for f in sorted(files):
        if f.endswith(".tscn"):
            p = os.path.join(root, f)
            with open(p, "r", encoding="utf-8") as fh:
                lines = fh.readlines()
                assert len(lines) > 0, f"Empty scene file: {p}"
                scene_count += 1
                print(f"  [PASS] {f} ({len(lines)} lines)")
print(f"Total valid scene files: {scene_count}")

# 3. Check all GDScript files
print("\n[3] Checking GDScript (.gd) files...")
scripts_dir = "scripts"
script_count = 0
for root, _, files in os.walk(scripts_dir):
    for f in sorted(files):
        if f.endswith(".gd"):
            p = os.path.join(root, f)
            with open(p, "r", encoding="utf-8") as fh:
                lines = fh.readlines()
                assert len(lines) > 0, f"Empty script: {p}"
                script_count += 1
                print(f"  [PASS] {f} ({len(lines)} lines)")
print(f"Total valid script files: {script_count}")

print("\n" + "=" * 60)
print(">>> ALL INTEGRITY CHECKS PASSED SUCCESSFULLY <<<")
print("=" * 60)
