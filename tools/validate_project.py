import os
import json
import re

print("=" * 60)
print("CHAOS LAB - Project Integrity & Syntax Verification")
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
assert json_count >= 101, f"Expected at least 101 level files, found {json_count}"

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
assert scene_count >= 22, f"Expected at least 22 scene files, found {scene_count}"

# 3. Check all GDScript files
print("\n[3] Checking GDScript (.gd) files...")
scripts_dir = "scripts"
script_count = 0
required_features = {
    "AudioSynthesizer.gd": "AudioStreamGenerator",
    "ScreenVignette.gd": "flash_explosion",
    "ImpactSpark.gd": "ImpactSpark",
    "ConfettiEffect.gd": "ConfettiEffect",
    "CameraShake.gd": "hit_stop",
    "CosmeticManager.gd": "CATALOG",
    "ShopScreen.gd": "SLOT_SUPPLIES",
    "SaveManager.gd": "is_vip",
    "LevelSelectScreen.gd": "MAX_WORLDS",
    "Magnet.gd": "magnetic_force",
    "Portal.gd": "portal_tag",
    "GravityPad.gd": "upward_acceleration",
    "Laser.gd": "max_bounces",
    "DailyChallengeManager.gd": "generate_daily_level_definition",
    "AchievementManager.gd": "claim_reward",
    "DailyChallengeScreen.gd": "_double_bonus_btn",
    "AchievementsScreen.gd": "LABORATORY MILESTONES",
    "AdSimulationOverlay.gd": "AdSimulationOverlay",
    "PlatformService.gd": "show_interstitial",
    "ResultScreen.gd": "_on_double_pressed",
    "GameplayUI.gd": "_on_hint_pressed",
    "NixCompanion.gd": "NixCompanion",
    "MainMenuScreen.gd": "MainMenuScreen",
    "LabHubScreen.gd": "LabHubScreen",
    "ChaosModeScreen.gd": "ChaosModeScreen",
    "SettingsScreen.gd": "SettingsScreen",
    "ChaosGenerator.gd": "ChaosGenerator",
}
found_features = set()

for root, _, files in os.walk(scripts_dir):
    for f in sorted(files):
        if f.endswith(".gd"):
            p = os.path.join(root, f)
            with open(p, "r", encoding="utf-8") as fh:
                content = fh.read()
                lines = content.splitlines()
                assert len(lines) > 0, f"Empty script: {p}"
                
                # Check bracket balance
                for b_open, b_close in [("(", ")"), ("[", "]"), ("{", "}")]:
                    assert content.count(b_open) == content.count(b_close), (
                        f"Mismatched {b_open}{b_close} in {f}: {content.count(b_open)} vs {content.count(b_close)}"
                    )
                
                if f in required_features:
                    assert required_features[f] in content, f"Missing feature keyword {required_features[f]} in {f}"
                    found_features.add(f)
                    
                script_count += 1
                print(f"  [PASS] {f} ({len(lines)} lines)")

assert len(found_features) == len(required_features), f"Missing required feature scripts: {set(required_features.keys()) - found_features}"
print(f"Total valid script files: {script_count}")
print(f"All Phase 4 & 5 core systems verified: {', '.join(sorted(found_features))}")

print("\n" + "=" * 60)
print(">>> ALL INTEGRITY CHECKS PASSED SUCCESSFULLY <<<")
print("=" * 60)
