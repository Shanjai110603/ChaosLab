"""
Campaign Level Authoring Generator for CHAOS LAB.
Generates balanced, rich level definitions for Levels 21 through 100 across Worlds 3 to 10.
"""

import os
import json
import math

WORLD_CONFIGS = {
    3: {
        "world_title": "Chain Catalyst",
        "desc_theme": "Sequential and synchronized multi-point detonations.",
        "primary_objects": ["bomb", "barrel", "ball", "ramp"],
        "titles": [
            "Synchronized Fuse", "Double Ignition", "Blast Funnel", "Radial Relay",
            "Shockwave Ladder", "Cluster Detonator", "Dual Volley", "Thermal Convection",
            "Delayed Detonation", "World 3 Finale: Supernova Matrix"
        ]
    },
    4: {
        "world_title": "Precision Angles",
        "desc_theme": "Deflective geometries, ricochets, and acute angle navigation.",
        "primary_objects": ["ramp", "ball", "box", "bomb"],
        "titles": [
            "Acute Slalom", "Triple Ricochet", "The Bank Shot", "Deflection Arc",
            "Geometric Corridor", "Billiard Chasm", "Prism Bounce", "Refraction Gate",
            "Zig-Zag Descent", "World 4 Finale: The Grand Kaleido"
        ]
    },
    5: {
        "world_title": "Structural Demolition",
        "desc_theme": "High-rise crate fortresses, load-bearing pillars, and controlled collapses.",
        "primary_objects": ["box", "barrel", "ball", "bomb"],
        "titles": [
            "Pillar Collapse", "The Watchtower", "Suspended Beam", "Keystone Breach",
            "Counterweight Drop", "Fortress Gate", "Timber Run", "Jenga Spire",
            "Foundational Demolition", "World 5 Finale: Citadel's Fall"
        ]
    },
    6: {
        "world_title": "Volatile Momentum",
        "desc_theme": "High-velocity ramps, kinetic bowling, and heavy inertia transfers.",
        "primary_objects": ["barrel", "ball", "ramp", "rocket"],
        "titles": [
            "Speedway Launch", "Heavy Bowling", "Kinetic Conveyor", "Inertia Transfer",
            "The Accelerator", "Velocity Dip", "Dynamic Chasm", "Momentum Transfer",
            "Downhill Freight", "World 6 Finale: Velocity Singularity"
        ]
    },
    7: {
        "world_title": "Hazard Control",
        "desc_theme": "Narrow apertures, hazardous obstacles, and surgical timing.",
        "primary_objects": ["bomb", "rocket", "box", "ramp"],
        "titles": [
            "Needle's Eye", "Quarantine Chute", "Proximity Minefield", "Narrow Aperture",
            "Volatile Perch", "Containment Breach", "Precision Chasm", "Hazard Trench",
            "Laser Sieve", "World 7 Finale: Meltdown Containment"
        ]
    },
    8: {
        "world_title": "Rocket Guidance",
        "desc_theme": "Directional flight, multi-stage boosters, and aerial strikes.",
        "primary_objects": ["rocket", "bomb", "ramp", "barrel"],
        "titles": [
            "Booster Ignition", "Aerial Intercept", "Dual Thruster", "Ascent Vector",
            "Mid-Air Strike", "Parabolic Arc", "Rocket Ricochet", "Orbital Staging",
            "Guided Salvo", "World 8 Finale: Stratospheric Assault"
        ]
    },
    9: {
        "world_title": "Chaos Chamber",
        "desc_theme": "High-density clusters, multi-target splits, and domino cascades.",
        "primary_objects": ["ball", "barrel", "bomb", "rocket"],
        "titles": [
            "Chain Reaction Lab", "Pinball Swarm", "Cluster Collision", "Scattershot",
            "Entropy Cascade", "Multi-Target Fracture", "Resonance Chamber", "The Atom Smasher",
            "Chaos Engine", "World 9 Finale: Total Entropy"
        ]
    },
    10: {
        "world_title": "The Omniverse Collider",
        "desc_theme": "The ultimate pinnacle puzzle chambers demanding mastery of all physical forces.",
        "primary_objects": ["ball", "ramp", "box", "barrel", "bomb", "rocket"],
        "titles": [
            "The First Harmonic", "Dual Singularity", "Triple Nexus", "The Quad Chamber",
            "Symphonic Ignition", "Quantum Fulcrum", "Antigravity Bridge", "The Celestial Gyro",
            "Master Cascade", "World 10 Grand Finale: The Omniverse Collider"
        ]
    }
}


def generate_level(level_id: int) -> dict:
    world = ((level_id - 1) // 10) + 1
    local_idx = (level_id - 1) % 10  # 0 to 9
    cfg = WORLD_CONFIGS[world]
    
    title = cfg["titles"][local_idx]
    is_finale = (local_idx == 9)
    num_targets = 4 if is_finale else (2 if local_idx < 5 else 3)
    par_objects = 2 if local_idx < 3 else (3 if local_idx < 7 else 4)

    # Base targets positions
    targets = []
    if num_targets == 2:
        targets = [
            {"x": 650 + (local_idx * 40), "y": 280 + (local_idx % 3) * 60},
            {"x": 1150 + (local_idx * 30), "y": 420 - (local_idx % 2) * 80}
        ]
    elif num_targets == 3:
        targets = [
            {"x": 550 + (local_idx * 30), "y": 220 + (local_idx % 2) * 50},
            {"x": 920 + (local_idx * 20), "y": 480 - (local_idx % 3) * 40},
            {"x": 1320 - (local_idx * 20), "y": 300 + (local_idx % 2) * 60}
        ]
    else:  # 4 targets
        targets = [
            {"x": 480, "y": 220},
            {"x": 780, "y": 520},
            {"x": 1120, "y": 260},
            {"x": 1420, "y": 480}
        ]

    # Pre-placed static/dynamic level objects
    objects = []
    # Catalyst trigger
    objects.append({
        "type": "ball",
        "x": 260 + (local_idx * 15),
        "y": 160 + (local_idx % 2) * 40,
        "rotation": 0,
        "draggable": True
    })

    # Intermediate interactive bodies depending on world theme
    if world in [3, 9]:
        # Explosive clusters
        objects.append({"type": "barrel", "x": 680, "y": 580, "rotation": 0, "draggable": False})
        objects.append({"type": "bomb", "x": 920, "y": 580, "rotation": 0, "draggable": False})
        if is_finale:
            objects.append({"type": "barrel", "x": 1200, "y": 540, "rotation": 0, "draggable": False})
    elif world in [4, 6]:
        # Ramps and momentum tracks
        objects.append({"type": "ramp", "x": 420, "y": 360, "rotation": 0, "draggable": True})
        objects.append({"type": "barrel", "x": 840, "y": 560, "rotation": 0, "draggable": False})
        if is_finale:
            objects.append({"type": "rocket", "x": 1150, "y": 520, "rotation": -45, "draggable": False})
    elif world in [5, 7]:
        # Heavy structures & barriers
        objects.append({"type": "box", "x": 580, "y": 520, "rotation": 0, "draggable": False})
        objects.append({"type": "box", "x": 580, "y": 420, "rotation": 0, "draggable": False})
        objects.append({"type": "bomb", "x": 580, "y": 320, "rotation": 0, "draggable": False})
        if is_finale:
            objects.append({"type": "barrel", "x": 1050, "y": 520, "rotation": 0, "draggable": False})
    elif world in [8, 10]:
        # Rockets and multi-tier launchers
        objects.append({"type": "ramp", "x": 440, "y": 380, "rotation": 0, "draggable": True})
        objects.append({"type": "rocket", "x": 820, "y": 560, "rotation": -60, "draggable": False})
        objects.append({"type": "bomb", "x": 1100, "y": 480, "rotation": 0, "draggable": False})
        if is_finale:
            objects.append({"type": "rocket", "x": 1340, "y": 380, "rotation": -90, "draggable": False})

    # Allowed player inventory
    inventory = {
        "ball": 2 if world in [4, 6, 9] else 1,
        "ramp": 2 if world in [4, 6, 10] else 1,
        "bomb": 1 if world in [3, 5, 7, 9, 10] else 0,
        "box": 1 if world in [5, 7, 10] else 0,
    }
    # Clean zero-count inventory keys
    inventory = {k: v for k, v in inventory.items() if v > 0}
    allowed_objects = list(inventory.keys())

    # Scoring thresholds
    base_score = 400 + (level_id * 35)
    score_targets = [
        int(base_score * 0.5),
        int(base_score * 1.0),
        int(base_score * 1.8)
    ]

    return {
        "level_id": level_id,
        "world": world,
        "world_title": cfg["world_title"],
        "title": title,
        "description": f"World {world} Stage {local_idx + 1}: {cfg['desc_theme']}",
        "par_objects": par_objects,
        "arena_width": 1600,
        "arena_height": 800,
        "objects": objects,
        "targets": targets,
        "score_targets": score_targets,
        "time_limit": 20,
        "allowed_objects": allowed_objects,
        "inventory": inventory,
        "hints": [
            f"Analyze the path towards target zones in {cfg['world_title']}",
            "Position kinetic triggers to initiate the optimal chain reaction",
            "Conserve inventory tools to earn the maximum par efficiency bonus"
        ]
    }


def main():
    base_dir = os.path.join(os.path.dirname(__file__), "..", "levels", "campaign")
    created_count = 0

    for world_id in range(3, 11):
        world_dir = os.path.join(base_dir, f"world_{world_id}")
        os.makedirs(world_dir, exist_ok=True)
        
        start_id = (world_id - 1) * 10 + 1
        end_id = start_id + 9
        
        for lvl_id in range(start_id, end_id + 1):
            data = generate_level(lvl_id)
            filepath = os.path.join(world_dir, f"level_{lvl_id:03d}.json")
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4)
            created_count += 1
            print(f"[OK] Generated: {filepath} (Level {lvl_id}: '{data['title']}')")

    print(f"\nSuccessfully generated {created_count} campaign level JSON files for Worlds 3 to 10!")


if __name__ == "__main__":
    main()
