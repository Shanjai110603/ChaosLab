import os
import subprocess
import sys

GODOT_BIN = r"C:\Users\shanj\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
PROJECT_DIR = r"c:\Users\shanj\OneDrive\Desktop\Chaos Lab"
BUILD_DIR = os.path.join(PROJECT_DIR, "build")

os.makedirs(os.path.join(BUILD_DIR, "windows"), exist_ok=True)
os.makedirs(os.path.join(BUILD_DIR, "web"), exist_ok=True)
os.makedirs(os.path.join(BUILD_DIR, "android"), exist_ok=True)

targets = [
    ("Windows Desktop", os.path.join(BUILD_DIR, "windows", "ChaosLab.exe"), "--export-release"),
    ("Web", os.path.join(BUILD_DIR, "web", "index.html"), "--export-release"),
    ("Android", os.path.join(BUILD_DIR, "android", "ChaosLab.apk"), "--export-debug"),
]

for preset_name, output_path, export_flag in targets:
    print(f"\n==========================================")
    print(f"Building: {preset_name} -> {output_path}")
    print(f"==========================================")
    cmd = [
        GODOT_BIN,
        "--headless",
        "--path", PROJECT_DIR,
        export_flag, preset_name, output_path
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0:
        size = os.path.getsize(output_path) if os.path.exists(output_path) else 0
        print(f"SUCCESS: {preset_name} created ({size / (1024*1024):.2f} MB)")
    else:
        print(f"FAILED: {preset_name}")
        print(res.stdout)
        print(res.stderr)

print("\nAll builds completed! Inspecting build directory:")
for root, dirs, files in os.walk(BUILD_DIR):
    for f in files:
        full = os.path.join(root, f)
        print(f"  {os.path.relpath(full, PROJECT_DIR)} ({os.path.getsize(full)/(1024*1024):.2f} MB)")
