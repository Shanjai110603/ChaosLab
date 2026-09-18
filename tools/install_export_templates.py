import os
import sys
import zipfile
import urllib.request
import subprocess

TPZ_URL = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
TARGET_DIR = os.path.expandvars(r"%APPDATA%\Godot\export_templates\4.7.2.stable")
TEMP_TPZ = os.path.expandvars(r"%TEMP%\Godot_v4.7.2-stable_export_templates.tpz")

print(f"Target directory: {TARGET_DIR}")
os.makedirs(TARGET_DIR, exist_ok=True)

if not os.path.exists(TEMP_TPZ) or os.path.getsize(TEMP_TPZ) < 100_000_000:
    print(f"Downloading Godot 4.7.2 export templates via curl from {TPZ_URL}...")
    cmd = ["curl.exe", "-L", "-C", "-", "-o", TEMP_TPZ, "--progress-bar", TPZ_URL]
    res = subprocess.run(cmd)
    if res.returncode != 0:
        print("curl failed, falling back to urllib...")
        urllib.request.urlretrieve(TPZ_URL, TEMP_TPZ)
    print("Download completed successfully!")
else:
    print(f"Using existing cached TPZ at: {TEMP_TPZ} ({os.path.getsize(TEMP_TPZ)/(1024*1024):.1f} MB)")

print("Extracting templates...")
with zipfile.ZipFile(TEMP_TPZ, 'r') as zf:
    for member in zf.namelist():
        # The zip contains files under 'templates/'
        if member.startswith("templates/"):
            filename = member[len("templates/"):]
            if not filename or filename.endswith("/"):
                continue
            dest_path = os.path.join(TARGET_DIR, filename)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with zf.open(member) as src, open(dest_path, "wb") as dst:
                dst.write(src.read())
            print(f"Extracted: {filename}")

print("Export templates successfully installed to:", TARGET_DIR)
