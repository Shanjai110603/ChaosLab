## ChaosGenerator — Procedural endless physics scenario generator for Chaos Mode.
## Creates randomized, solvable physics puzzle definitions with unique apparatus constraints,
## procedural obstacle layouts, dynamic target coordinates, and chaos mutators.
class_name ChaosGenerator
extends RefCounted

const CHAOS_MUTATORS := [
	{ "name": "HYPER RESTITUTION", "desc": "Bouncy physics! All objects bounce with 1.4x restitution." },
	{ "name": "VOLATILE CHARGE", "desc": "Explosions have 1.5x blast radius and impulse." },
	{ "name": "LOW GRAVITY", "desc": "Reduced gravity! Objects float across the arena." },
	{ "name": "MOMENTUM TRANSFER", "desc": "Heavy objects accelerate rapidly down slopes." },
	{ "name": "MAGNETIC SURGE", "desc": "All metallic apparatuses react with amplified magnetic pull." }
]


static func generate_chaos_scenario(run_seed: int = 0) -> Dictionary:
	if run_seed != 0:
		seed(run_seed)

	var mutator: Dictionary = CHAOS_MUTATORS[randi() % CHAOS_MUTATORS.size()]

	# Random targets count: 2 to 4
	var target_count: int = randi_range(2, 4)
	var targets: Array[Dictionary] = []
	for i in range(target_count):
		var tx: float = randf_range(800.0, 1500.0)
		var ty: float = randf_range(280.0, 800.0)
		targets.append({
			"x": tx,
			"y": ty,
			"points": 500
		})

	# Pre-placed arena obstacles / reactors
	var objects: Array[Dictionary] = []

	# Add a fixed ramp or platform
	var rx: float = randf_range(400.0, 750.0)
	var ry: float = randf_range(450.0, 750.0)
	objects.append({
		"type": "Ramp",
		"x": rx,
		"y": ry,
		"rotation": deg_to_rad(randf_range(-30.0, 30.0)),
		"fixed": true
	})

	# Add 1 or 2 volatile explosive barrels in arena
	for i in range(randi_range(1, 2)):
		objects.append({
			"type": "Barrel",
			"x": randf_range(650.0, 1100.0),
			"y": randf_range(500.0, 800.0),
			"rotation": 0.0,
			"fixed": false
		})

	# Apparatus player inventory
	var inventory: Dictionary = {
		"Ball": randi_range(1, 2),
		"Bomb": randi_range(1, 2),
		"Rocket": randi_range(1, 2),
		"Barrel": randi_range(1, 2),
	}
	if randf() > 0.4:
		inventory["Magnet"] = 1
	if randf() > 0.5:
		inventory["Ramp"] = 1

	return {
		"level_id": 9990 + (randi() % 99),
		"title": "Procedural Chaos Run",
		"world": 10,
		"description": "Mutator: %s — %s" % [mutator["name"], mutator["desc"]],
		"mutator": mutator["name"],
		"objective": "destroy_targets",
		"inventory": inventory,
		"objects": objects,
		"targets": targets,
		"par_objects": 4,
		"time_limit": 30.0,
		"score_targets": [1500, 3000, 6000]
	}
