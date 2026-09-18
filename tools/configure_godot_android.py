import os
import re

path = os.path.expandvars(r'%APPDATA%\Godot\editor_settings-4.7.tres')
if not os.path.exists(path):
    print("Editor settings file not found at:", path)
    exit(1)

with open(path, "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.strip().startswith("export/android/java_sdk_path"):
        new_lines.append('export/android/java_sdk_path = "C:/Program Files/Android/openjdk/jdk-21.0.8"\n')
    elif line.strip().startswith("export/android/android_sdk_path"):
        new_lines.append('export/android/android_sdk_path = "C:/Users/shanj/AppData/Local/Android/Sdk"\n')
    elif line.strip().startswith("export/android/debug_keystore"):
        new_lines.append('export/android/debug_keystore = "C:/Users/shanj/AppData/Roaming/Godot/keystores/debug.keystore"\n')
    else:
        new_lines.append(line)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("Godot Android editor settings successfully updated!")
