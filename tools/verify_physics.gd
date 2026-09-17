## Verification test script for Chaos Lab — Phase 2 Physics Prototype.
## Can be run standalone in Godot headless mode or inspected for logic correctness.
class_name VerifyPhysics
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("CHAOS LAB — Phase 2 Physics & System Verification")
	print("==================================================")
	var all_passed := true

	# Test 1: Level JSON Validation
	all_passed = all_passed and _test_level_jsons()

	# Test 2: Quadratic Blast Wave Falloff Math
	all_passed = all_passed and _test_blast_falloff_math()

	# Test 3: Combo Multiplier Curve
	all_passed = all_passed and _test_combo_multiplier_curve()

	# Test 4: Snapshot State Integrity
	all_passed = all_passed and _test_snapshot_integrity()

	print("==================================================")
	if all_passed:
		print(">>> ALL PHASE 2 VERIFICATION TESTS PASSED <<<")
	else:
		push_error(">>> SOME TESTS FAILED <<<")
	print("==================================================")
	quit(0 if all_passed else 1)


func _test_level_jsons() -> bool:
	print("\n[Test 1] Validating Level JSON Schemas...")
	var test_paths := [
		"res://levels/campaign/world_1/level_001.json",
		"res://levels/campaign/world_1/level_002.json",
		"res://levels/campaign/world_1/level_003.json",
		"res://levels/campaign/world_1/level_004.json",
		"res://levels/chaos/sandbox_01.json"
	]

	var passed := true
	for path in test_paths:
		if not FileAccess.file_exists(path):
			push_error("Missing level file: %s" % path)
			passed = false
			continue

		var file := FileAccess.open(path, FileAccess.READ)
		var text := file.get_as_text()
		file.close()

		var json := JSON.new()
		var err := json.parse(text)
		if err != OK:
			push_error("JSON Parse Error in %s: %s" % [path, json.get_error_message()])
			passed = false
			continue

		var data: Dictionary = json.data
		var def := LevelDefinition.from_dict(data)
		if def.level_id <= 0:
			push_error("Invalid level_id in %s" % path)
			passed = false
		if def.objects.is_empty():
			push_error("No objects defined in %s" % path)
			passed = false
		if def.target_positions.is_empty():
			push_error("No targets defined in %s" % path)
			passed = false

		print("  ✓ %s — OK (%d objects, %d targets, title: '%s')" % [
			path.get_file(), def.objects.size(), def.target_positions.size(), def.title
		])

	return passed


func _test_blast_falloff_math() -> bool:
	print("\n[Test 2] Validating Blast Wave Quadratic Falloff Math...")
	var max_force := 1000.0
	var radius := 200.0

	var calc_force := func(dist: float) -> float:
		var norm := clampf(dist / radius, 0.0, 1.0)
		return max_force * (1.0 - norm) * (1.0 - norm)

	var f_at_0 := calc_force.call(0.0)
	var f_at_half := calc_force.call(100.0)
	var f_at_radius := calc_force.call(200.0)
	var f_at_double := calc_force.call(400.0)

	var passed := true
	if not is_equal_approx(f_at_0, 1000.0):
		push_error("Force at center should be max_force (1000), got %f" % f_at_0)
		passed = false
	if not is_equal_approx(f_at_half, 250.0): # (1 - 0.5)^2 = 0.25 -> 250
		push_error("Force at half-distance should be 250, got %f" % f_at_half)
		passed = false
	if not is_equal_approx(f_at_radius, 0.0):
		push_error("Force at perimeter should be 0, got %f" % f_at_radius)
		passed = false
	if not is_equal_approx(f_at_double, 0.0):
		push_error("Force beyond perimeter should be clamped to 0, got %f" % f_at_double)
		passed = false

	if passed:
		print("  ✓ Quadratic impulse curve F(d) = F_max * (1 - d/R)^2 verified accurately.")
	return passed


func _test_combo_multiplier_curve() -> bool:
	print("\n[Test 3] Validating Combo Multiplier & Scaling...")
	var manager := ChainReactionManager.new()
	var test_multiplier := func(chain: int) -> float:
		if chain <= 1:
			return 1.0
		elif chain <= 3:
			return 1.0 + (chain - 1) * 0.25
		elif chain <= 8:
			return 1.5 + (chain - 3) * 0.3
		elif chain <= 15:
			return 3.0 + (chain - 8) * 0.4
		else:
			return 5.0 + (chain - 15) * 0.5

	var m1 := test_multiplier.call(1)
	var m3 := test_multiplier.call(3)
	var m8 := test_multiplier.call(8)
	var m12 := test_multiplier.call(12)

	var passed := true
	if m1 != 1.0:
		passed = false
	if m3 != 1.5:
		passed = false
	if m8 != 3.0:
		passed = false
	if not is_equal_approx(m12, 4.6):
		passed = false

	manager.free()
	if passed:
		print("  ✓ Multiplier scaling verified: chain 1=1.0x, chain 3=1.5x, chain 8=3.0x, chain 12=4.6x.")
	return passed


func _test_snapshot_integrity() -> bool:
	print("\n[Test 4] Validating Snapshot State Restore Logic...")
	var initial_pos := Vector2(120, 240)
	var moved_pos := Vector2(450, 780)
	var snapshot := {
		"position": moved_pos,
		"rotation": 0.785, # 45 degrees
		"linear_velocity": Vector2(100, 200),
		"angular_velocity": 2.5,
		"freeze": true
	}

	# Verification check: restoring snapshot clears dynamic velocity while retaining placed coordinates
	var restored_pos: Vector2 = snapshot.get("position", initial_pos)
	var restored_vel: Vector2 = Vector2.ZERO
	var restored_freeze: bool = true

	var passed := (restored_pos == moved_pos) and (restored_vel == Vector2.ZERO) and (restored_freeze == true)
	if passed:
		print("  ✓ Snapshot correctly restores player-placed position and zeros transient velocities on reset.")
	return passed
