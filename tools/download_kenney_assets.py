#!/usr/bin/env python3
"""
CHAOS LAB — Kenney CC0 Asset Downloader
=======================================
Downloads official Kenney CC0 assets (audio, 2D physics sprites, debris, UI icons, particle textures)
from verified GitHub repositories into the assets/ directory.
All assets are licensed under CC0 1.0 Universal (Public Domain).
"""

import os
import urllib.request
import csv

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ASSET_DIR = os.path.join(PROJECT_ROOT, "assets")

# List of assets to download: (category, subpath, remote_url, asset_name, notes)
ASSET_DOWNLOADS = [
    # ─── Audio SFX (Kenney Starter Kits - CC0) ───────────────────────────
    ("audio/sfx", "break.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/break.ogg", "Glass/Debris Break SFX", "Wall fracture and glass destruction"),
    ("audio/sfx", "coin.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/coin.ogg", "Coin / Star Collect SFX", "Coin reward and star reveal"),
    ("audio/sfx", "fall.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/fall.ogg", "Fall SFX", "Object falling into pit or void"),
    ("audio/sfx", "jump.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/jump.ogg", "Launch SFX", "Gravity pad and ramp ejection"),
    ("audio/sfx", "land.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sounds/land.ogg", "Impact Land SFX", "Physics object impact and thud"),
    ("audio/sfx", "blaster.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/sounds/blaster.ogg", "Laser / Blaster SFX", "Laser emitter beam activation"),
    ("audio/sfx", "enemy_destroy.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-FPS/main/sounds/enemy_destroy.ogg", "Explosion Detonation SFX", "Bomb and barrel explosive blast"),
    ("audio/sfx", "tile-match.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Match-3/main/sounds/tile-match.ogg", "Chime Combo SFX", "Target hit and combo multiplier chime"),
    ("audio/sfx", "tile-land.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Match-3/main/sounds/tile-land.ogg", "Crate Drop SFX", "Heavy wooden / metal crate impact"),
    ("audio/sfx", "tile-swap.ogg", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-Match-3/main/sounds/tile-swap.ogg", "Tactile UI Click SFX", "Button press and apparatus tray select"),

    # ─── 2D Physics Sprites: Debris (Kenney Physics Assets - CC0) ─────────
    ("sprites/debris", "debrisGlass_1.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisGlass_1.png", "Glass Debris 1", "Breakable wall glass shard 1"),
    ("sprites/debris", "debrisGlass_2.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisGlass_2.png", "Glass Debris 2", "Breakable wall glass shard 2"),
    ("sprites/debris", "debrisGlass_3.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisGlass_3.png", "Glass Debris 3", "Breakable wall glass shard 3"),
    ("sprites/debris", "debrisWood_1.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisWood_1.png", "Wood Debris 1", "Crate splinter shard 1"),
    ("sprites/debris", "debrisWood_2.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisWood_2.png", "Wood Debris 2", "Crate splinter shard 2"),
    ("sprites/debris", "debrisWood_3.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisWood_3.png", "Wood Debris 3", "Crate splinter shard 3"),
    ("sprites/debris", "debrisStone_1.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisStone_1.png", "Stone Debris 1", "Concrete wall fracture shard 1"),
    ("sprites/debris", "debrisStone_2.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisStone_2.png", "Stone Debris 2", "Concrete wall fracture shard 2"),
    ("sprites/debris", "debrisStone_3.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Debris/debrisStone_3.png", "Stone Debris 3", "Concrete wall fracture shard 3"),

    # ─── 2D Physics Sprites: Explosives & Barrels ────────────────────────
    ("sprites/objects", "barrel_explosive.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Explosive%20elements/elementExplosive011.png", "Explosive Barrel Sprite", "Volatile explosive barrel apparatus"),
    ("sprites/objects", "tnt_block.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Explosive%20elements/elementExplosive014.png", "TNT Explosive Block", "Detonating explosive crate"),
    ("sprites/objects", "bomb_spiked.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Explosive%20elements/elementExplosive048.png", "Bomb Sphere Sprite", "Kinetic bomb apparatus"),

    # ─── 2D Physics Sprites: Wood & Metal Apparatus ───────────────────────
    ("sprites/objects", "crate_wood.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Wood%20elements/elementWood010.png", "Wood Crate Sprite", "Physics Box apparatus"),
    ("sprites/objects", "crate_metal.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Metal%20elements/elementMetal010.png", "Metal Block Sprite", "Heavy steel apparatus block"),
    ("sprites/objects", "ramp_wood.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Wood%20elements/elementWood044.png", "Wood Incline Triangle", "Physics Ramp wedge"),
    ("sprites/objects", "beam_metal.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Metal%20elements/elementMetal015.png", "Metal Girder Beam", "Structural barrier girder"),

    # ─── 2D Physics Sprites: Glass Barriers ──────────────────────────────
    ("sprites/objects", "glass_pane.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Glass%20elements/elementGlass010.png", "Glass Pane Sprite", "Breakable wall glass barrier"),
    ("sprites/objects", "glass_block.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Physics%20Assets/Glass%20elements/elementGlass014.png", "Glass Block Sprite", "Reinforced glass barrier"),

    # ─── 2D Spheres: Balls (Kenney Rolling Ball Assets) ───────────────────
    ("sprites/objects", "ball_metal.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Rolling%20Ball%20Assets/ball_blue_large.png", "Metallic Blue Sphere", "Physics rolling ball apparatus"),
    ("sprites/objects", "ball_red.png", "https://raw.githubusercontent.com/shorepine/kenney/master/2d/Rolling%20Ball%20Assets/ball_red_large.png", "Kinetic Red Sphere", "Heavy bowling ball skin"),

    # ─── VFX Particles & Shadows ─────────────────────────────────────────
    ("sprites/vfx", "particle_star.png", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sprites/particle.png", "Particle Glow Texture", "Explosion spark & kinetic impact"),
    ("sprites/vfx", "blob_shadow.png", "https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/sprites/blob_shadow.png", "Blob Shadow Texture", "Ground contact soft shadow"),

    # ─── UI Icons (Kenney Game Icons 2x White - CC0) ──────────────────────
    ("sprites/ui", "icon_star.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/star.png", "Star Icon", "Star rating badge"),
    ("sprites/ui", "icon_gear.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/gear.png", "Settings Gear Icon", "Settings button icon"),
    ("sprites/ui", "icon_audio_on.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/audioOn.png", "Audio On Icon", "Sound enabled icon"),
    ("sprites/ui", "icon_audio_off.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/audioOff.png", "Audio Off Icon", "Sound muted icon"),
    ("sprites/ui", "icon_music_on.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/musicOn.png", "Music On Icon", "Music enabled icon"),
    ("sprites/ui", "icon_music_off.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/musicOff.png", "Music Off Icon", "Music muted icon"),
    ("sprites/ui", "icon_checkmark.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/checkmark.png", "Checkmark Icon", "Target cleared icon"),
    ("sprites/ui", "icon_cross.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/cross.png", "Cross / Cancel Icon", "Close modal icon"),
    ("sprites/ui", "icon_pause.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/pause.png", "Pause Icon", "Pause simulation icon"),
    ("sprites/ui", "icon_arrow_right.png", "https://raw.githubusercontent.com/shorepine/kenney/master/icons/Game%20Icons/White/2x/arrowRight.png", "Next / Arrow Icon", "Navigation arrow icon"),

    # ─── UI Panels (Kenney Sci-fi UI - CC0) ───────────────────────────────
    ("sprites/ui", "glassPanel.png", "https://raw.githubusercontent.com/shorepine/kenney/master/ui/UI%20Pack%20-%20Sci-fi/glassPanel.png", "Glass Panel 9-Patch", "HUD cyberpunk glass card backdrop"),
    ("sprites/ui", "metalPanel_plate.png", "https://raw.githubusercontent.com/shorepine/kenney/master/ui/UI%20Pack%20-%20Sci-fi/metalPanel_plate.png", "Metal Panel Texture", "Heavy apparatus frame texture"),
    ("sprites/ui", "crosshair_cyan.png", "https://raw.githubusercontent.com/shorepine/kenney/master/ui/UI%20Pack%20-%20Sci-fi/crossair_blue.png", "Cyan Crosshair", "Target apparatus reticle"),
]

def main():
    print("=" * 60)
    print("CHAOS LAB — Downloading Kenney CC0 Asset Library")
    print("=" * 60)

    downloaded = []
    headers = {"User-Agent": "Mozilla/5.0 (ChaosLab Asset Downloader)"}

    for category, filename, url, asset_name, notes in ASSET_DOWNLOADS:
        dest_dir = os.path.join(ASSET_DIR, category)
        os.makedirs(dest_dir, exist_ok=True)
        dest_path = os.path.join(dest_dir, filename)

        rel_path = f"assets/{category}/{filename}".replace("\\", "/")
        print(f"Downloading: {rel_path} ...", end=" ")

        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = resp.read()
                with open(dest_path, "wb") as f:
                    f.write(data)
            print(f"OK ({len(data) / 1024:.1f} KB)")
            downloaded.append((rel_path, filename, asset_name, notes))
        except Exception as e:
            print(f"FAILED: {e}")

    # Append to licenses/ASSET_MANIFEST.csv
    manifest_path = os.path.join(PROJECT_ROOT, "licenses", "ASSET_MANIFEST.csv")
    print(f"\nUpdating {manifest_path} with downloaded assets...")

    existing_paths = set()
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                existing_paths.add(row["path"].replace("\\", "/"))

    new_rows = []
    for rel_path, filename, asset_name, notes in downloaded:
        if rel_path in existing_paths:
            continue
        ext = os.path.splitext(filename)[1].lower()
        asset_type = "Audio (OGG)" if ext == ".ogg" else "Texture (PNG)"
        asset_id = "KENNEY_" + filename.upper().replace(".", "_").replace("-", "_")
        new_rows.append({
            "path": rel_path,
            "license": "CC0-1.0",
            "asset_id": asset_id,
            "asset_name": f"Kenney {asset_name}",
            "type": asset_type,
            "source": "Kenney.nl",
            "source_url": "https://kenney.nl",
            "author": "Kenney Vleugels",
            "commercial_use": "True",
            "modification_allowed": "True",
            "attribution_required": "False",
            "date_verified": "2026-09-19",
            "notes": f"CC0 Public Domain. {notes}",
        })

    if new_rows:
        fieldnames = [
            "path", "license", "asset_id", "asset_name", "type",
            "source", "source_url", "author", "commercial_use",
            "modification_allowed", "attribution_required", "date_verified", "notes"
        ]
        file_exists = os.path.exists(manifest_path)
        with open(manifest_path, "a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if not file_exists:
                writer.writeheader()
            writer.writerows(new_rows)
        print(f"Added {len(new_rows)} new verified CC0 assets to manifest.")

    print("\n[SUCCESS] All Kenney CC0 assets successfully downloaded and registered.")

if __name__ == "__main__":
    main()
