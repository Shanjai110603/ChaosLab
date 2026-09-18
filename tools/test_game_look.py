import os
import subprocess
import time
from PIL import ImageGrab

godot_path = r"C:\Users\shanj\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
project_path = r"c:\Users\shanj\OneDrive\Desktop\Chaos Lab"
artifact_dir = r"C:\Users\shanj\.gemini\antigravity-ide\brain\d986cb45-413c-49c1-86e7-8c2a52b970ec"
screenshot_path = os.path.join(artifact_dir, "game_look_test.png")

print("Launching Godot...")
proc = subprocess.Popen([godot_path, "--path", project_path, "--resolution", "1280x720"])
time.sleep(3.5)

print("Capturing screenshot...")
try:
    img = ImageGrab.grab()
    img.save(screenshot_path)
    print("Screenshot saved to:", screenshot_path)
except Exception as e:
    print("Error taking screenshot:", e)
