# CHAOS LAB

**Build it. Trigger it. Cause chaos.**

A cross-platform physics experiment puzzle game built with Godot 4.x.

## Overview

Chaos Lab is a hybrid-casual physics puzzle game where players manipulate objects in a laboratory arena, trigger chain reactions, and chase high scores. The core loop: **Observe → Plan → Place → GO → Chain Reaction → Score → Retry or Next**.

## Platforms

| Platform | Purpose | Status |
|----------|---------|--------|
| Windows  | Desktop release | 🔨 Development |
| HTML5/Web | Instant play, testing, sharing | 🔨 Development |
| Android  | Primary commercial mobile | 🔨 Development |

## Getting Started

### Prerequisites

- [Godot 4.7+](https://godotengine.org/download/) (standard build, not .NET)

### Running

1. Open Godot
2. Click **Import Existing Project**
3. Navigate to this folder and select `project.godot`
4. Press **Run** (F5)

### Controls (Desktop)

| Action | Key |
|--------|-----|
| Select/Drag | Mouse Left Click + Drag |
| GO | Space |
| Reset | R |
| Undo | Z |
| Pause | Escape |
| Debug Overlay | F1 |
| Skip Level (debug) | F2 |

## Project Structure

```
chaos-lab/
├── project.godot          # Godot project configuration
├── scenes/                # Scene files (.tscn)
│   ├── main/              # Main scene, root
│   ├── gameplay/          # Arena, gameplay UI
│   ├── objects/           # Physics object scenes
│   ├── ui/                # Menus, HUD, overlays
│   └── vfx/              # Visual effects
├── scripts/               # GDScript source
│   ├── core/              # Autoload singletons
│   ├── objects/           # Object scripts
│   ├── gameplay/          # Chain reaction, scoring, experiment
│   ├── levels/            # Level loading, definitions
│   ├── platform/          # Platform abstraction
│   ├── ui/                # UI scripts
│   └── vfx/              # VFX scripts
├── levels/                # Level data (JSON)
│   ├── campaign/          # Campaign levels by world
│   ├── chaos/             # Chaos mode definitions
│   └── daily/             # Daily challenge definitions
├── assets/                # Art, audio, fonts
│   ├── ASSET_MANIFEST.csv # Third-party asset tracking
│   └── ...
├── licenses/              # License documentation
├── localization/          # Translation strings
├── tests/                 # Automated tests
├── tools/                 # Dev tools, validators
├── docs/                  # Design docs
└── build/                 # Export builds (gitignored)
```

## Architecture

### Autoload Singletons

| Singleton | Purpose |
|-----------|---------|
| `GameManager` | Game state machine, flow control |
| `InputManager` | Unified input abstraction |
| `PlatformService` | Platform-specific services (ads, IAP, share) |
| `AudioManager` | Sound effects and music |
| `SaveManager` | Local save/load with versioning |
| `DailyChallengeManager` | Daily seed generation, modifiers, and streak progression |
| `AchievementManager` | 12 Commercial milestones, progress tracking, coin bounties |
| `DebugManager` | Debug overlay and dev tools |

### Object Hierarchy

```
GameObject (RigidBody2D)
└── PhysicalObject
    ├── Ball
    ├── Box
    ├── Barrel (explosive variant)
    ├── Bomb (fuse + explosion)
    ├── Rocket (thrust + direction)
    └── Target (hit detection)
```

### Game States

```
MENU → LOADING → PLACING → SIMULATING → RESULT → PAUSED
```

## Development Phases

- **Phase 1**: Project foundation ✓ Complete
- **Phase 2**: Physics prototype ✓ Complete
- **Phase 3**: Core gameplay (objectives, scoring, 20 levels) ✓ Complete
- **Phase 4**: Polish (VFX, audio synthesis, camera juice, haptics) ✓ Complete
- **Phase 5**: Progression (coins, shop/unlocks, 100 levels) ✓ Complete
- **Phase 6**: Additional mechanics (magnets, portals, lasers, anti-gravity) ✓ Complete
- **Phase 7**: Retention (Daily Experiments, Streaks, 12 Achievements) ✓ Complete
- **Phase 8**: Monetization (Rewarded ads, Interstitials, IAP, VIP pass) ✓ Complete
- **Phase 9**: Cross-platform QA, Optimization & Export Presets ✓ Complete
- **Phase 10**: Release Preparation, Store Kit & Production Launch ✓ Complete

## Store Kit & Graphics

- Commercial store listing metadata: `docs/store/STORE_LISTING.md`
- Official promotional feature graphic (1024x500): `assets/chaos_lab_feature_graphic.jpg`
- Release changelog: `CHANGELOG.md`

## License

All original code is proprietary. Third-party assets are documented in `assets/ASSET_MANIFEST.csv` and `licenses/`.

## Version

1.0.0 — Production Release (All 10 Phases Complete)
