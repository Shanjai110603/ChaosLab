# CHAOS LAB — Changelog

All notable changes, architectural milestones, and feature additions for **Chaos Lab** ("Build it. Trigger it. Cause chaos.") are documented in this file.

---

## [1.0.0] - 2026-09-18 - Production Commercial Release

### Added
- **Production Milestone**: Full cross-platform commercial release ready for Windows, Web/HTML5, and Android.
- **Commercial Store Listing Kit**: Comprehensive ASO metadata, feature bullets, content ratings, and privacy policy declarations in `docs/store/STORE_LISTING.md`.
- **Widescreen Feature Graphic**: Official 1024x500 promotional banner art for Google Play and Web storefronts.
- **Export Packaging**: Complete `export_presets.cfg` for Windows Desktop, HTML5/Web PWA, and Android APK/AAB.

---

## [0.9.0] - 2026-09-18 - Phase 9: Cross-Platform QA & Optimization

### Added
- **Export Presets**: Dedicated export configurations for Windows Desktop (`ChaosLab.exe`), Web PWA, and Android (`com.chaoslab.game`, SDK 24-34).
- **Automated Cross-Platform Test Suite**: `tests/test_cross_platform.py` verifying 101 levels, geometric boundaries, singletons, and export profiles.
- **Touch Calibration**: Added 8.0px touch drag deadzone in `InputManager.gd` to distinguish capacitive taps from drags.
- **Safe Area Padding**: Automatic notch and punch-hole margin calculations in `GameplayUI.gd`.

### Optimized
- **Physics Sleeping**: Configured linear and angular sleep thresholds in `project.godot` (`time_before_sleep = 0.4s`) to free CPU cycles during massive chain reactions.
- **Particle Capping**: Hard instance caps and auto-cull safeguards on `ImpactSpark` (max 24) and `FloatingText` (max 16) to eliminate garbage collection stutters.
- **Memory Leak Protection**: Comprehensive cleanup of spawned objects and orphaned VFX in `Arena.gd` on level reset/transition.

---

## [0.8.0] - 2026-09-18 - Phase 8: Monetization & Store Integration

### Added
- **Laboratory Armory IAP Store**: New `💎 SUPPLIES` tab in `ShopScreen.gd` featuring Coin Bundles ($0.99–$4.99), Remove Ads ($1.99), and VIP Scientist Pass ($4.99).
- **VIP Scientist Pass**: Permanent 2x coins on all levels, zero interstitial ads, exclusive VIP Gold cosmetics (`bomb_atomic`, `ball_quantum`, `theme_blueprint`), and +1,000 welcome coins.
- **Rewarded Ad Doubler**: Interactive `🎬 DOUBLE COINS (2X)` button on `ResultScreen.gd`.
- **Ad Simulation Engine**: Interactive `AdSimulationOverlay.gd` allowing full interactive simulation of video ads and purchases on desktop and web without live SDK credentials.
- **Cadence-Managed Interstitials**: Pacing engine enforcing 90s minimum cooldown and 3 level completions between ads, with zero interruptions during active experiments.

---

## [0.7.0] - 2026-09-18 - Phase 7: Retention Engine

### Added
- **Daily Experiment Engine**: Deterministic date-seeded challenges with 4 rotating mutators (`MOON_GRAVITY`, `HYPER_FUSE`, `SUPER_BOUNCE`, `HEAVY_MASS`).
- **7-Day Streak Roadmap**: Daily bonuses escalating from 100🪙 to 1,000🪙 with animated streak flame header.
- **12 Commercial Achievements**: Milestone tracking in `AchievementManager.gd` (`FIRST_SPARK`, `PYROMANIAC`, `CHAIN_GOD`, `PAR_PERFECTIONIST`, `SPEED_DEMON`, etc.) with claimable coin bounties.
- **Achievements Terminal**: Dedicated UI screen with progress bars and claiming animations.

---

## [0.6.0] - 2026-09-18 - Phase 6: Advanced Mechanics

### Added
- **Electromagnet**: Radial magnetic attraction and repulsion with inverse falloff physics.
- **Quantum Wormhole Portals**: Linked Alpha/Beta portals with angular trajectory remapping and velocity preservation.
- **Anti-Gravity Inverter Pad**: Upward-directed vertical ion force column lifting objects into anti-gravity suspension.
- **High-Energy Laser Projector**: Raycast laser optics beam with 3 surface reflections, fuse ignition, and remote target activation.

---

## [0.5.0] - 2026-09-18 - Phase 5: Progression & Economy

### Added
- **100 Campaign Levels**: 10 distinct worlds spanning Mechanics, Gravity, Supernovas, Kaleidoscopes, Kinetic Citadels, and Quantum Entanglement.
- **Armory Customization Shop**: Unlocking and equipping Bomb, Sphere, and Arena Theme skins.
- **Persistent Virtual Economy**: Coin rewards for stars, perfect clears, and par efficiency bonuses.
- **World Carousel**: Responsive navigation across Worlds 1–10 with world star tallies and progression locks.

---

## [0.4.0] - 2026-09-18 - Phase 4: Audio Synthesis & Juice

### Added
- **Procedural Audio Synthesizer**: 100% self-contained real-time PCM audio generation (`AudioStreamGenerator`) with zero external asset dependencies.
- **4-Layer Detonation VFX**: Expanding flash, shockwave distortion, incandescent sparks, and billowing smoke.
- **Dynamic Camera Juice**: Hit-stop impact freezing, trauma-based screen shake, and chromatic vignette flashes.
- **Cross-Platform Haptics**: Vibration feedback for collisions, explosions, and UI clicks across Web and Android.

---

## [0.3.0] - 2026-09-18 - Phase 3: Core Gameplay & Scoring

### Added
- **Par Efficiency System**: +250 points awarded per unused inventory item left in the tray.
- **Level Select Screen**: Responsive grid layout with animated 3-star ratings and star totals.
- **Result Screen**: Star pop-in sequences, score breakdown, and navigation flow.
- **First 20 Hand-Crafted Levels**: Worlds 1 and 2 complete with progressive difficulty curve.

---

## [0.2.0] - 2026-09-18 - Phase 2: Physics Prototype & 2.5D Art

### Added
- **Procedural 2.5D Rendering**: High-contrast laboratory aesthetic with metallic bevels, rivets, and glowing fuses.
- **Physics Objects**: Ball, Box, Barrel, Bomb, Rocket, and Target.
- **Object Tray**: Bottom inventory dock with rotation (±45°) and grid-snap alignment.
- **Chain Reaction Engine**: Quadratic blast shockwaves, impulse transfer, and combo multiplier cascades.

---

## [0.1.0] - 2026-09-18 - Phase 1: Foundation

### Added
- **Project Foundation**: Godot 4.x project setup with pure GDScript architecture.
- **Core Autoload Singletons**: `GameManager`, `InputManager`, `PlatformService`, `AudioManager`, `SaveManager`, `DebugManager`.
- **Level Serialization**: JSON-based level format supporting campaign, chaos, and custom definitions.
- **Platform Abstraction**: Base platform interface with Android, Web, and Windows adapters.
