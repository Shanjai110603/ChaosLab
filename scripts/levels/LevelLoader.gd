## Level Loader.
## Loads LevelDefinition from JSON files and instantiates objects in the arena.
class_name LevelLoader
extends Node

## Scene references for object types.
const OBJECT_SCENES: Dictionary = {
	"ball": "res://scenes/objects/Ball.tscn",
	"box": "res://scenes/objects/Box.tscn",
	"barrel": "res://scenes/objects/Barrel.tscn",
	"bomb": "res://scenes/objects/Bomb.tscn",
	"rocket": "res://scenes/objects/Rocket.tscn",
	"ramp": "res://scenes/objects/Ramp.tscn",
	"magnet": "res://scenes/objects/Magnet.tscn",
	"portal": "res://scenes/objects/Portal.tscn",
	"gravity_pad": "res://scenes/objects/GravityPad.tscn",
	"laser": "res://scenes/objects/Laser.tscn",
}

const TARGET_SCENE: String = "res://scenes/objects/Target.tscn"

## Cached packed scenes.
var _scene_cache: Dictionary = {}

## Base path for campaign levels.
const CAMPAIGN_PATH: String = "res://levels/campaign/"


func _ready() -> void:
	_preload_scenes()


## Preload all object scenes.
func _preload_scenes() -> void:
	for key in OBJECT_SCENES:
		var path: String = OBJECT_SCENES[key]
		if ResourceLoader.exists(path):
			_scene_cache[key] = load(path)
		else:
			push_warning("[LevelLoader] Scene not found: %s" % path)

	if ResourceLoader.exists(TARGET_SCENE):
		_scene_cache["target"] = load(TARGET_SCENE)


## Load a level definition from JSON by level ID.
func load_level_data(level_id: int) -> LevelDefinition:
	var world: int = ((level_id - 1) / 10) + 1
	var file_name: String = "level_%03d.json" % level_id
	var path: String = "%sworld_%d/%s" % [CAMPAIGN_PATH, world, file_name]

	if not FileAccess.file_exists(path):
		push_warning("[LevelLoader] Level file not found: %s" % path)
		# Return a default test level
		return _create_default_level(level_id)

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[LevelLoader] Failed to open: %s" % path)
		return _create_default_level(level_id)

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("[LevelLoader] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return _create_default_level(level_id)

	return LevelDefinition.from_dict(json.data)


## Get metadata for all levels in a specific world.
func get_levels_in_world(world: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start_id := (world - 1) * 10 + 1
	var end_id := start_id + 9

	for id in range(start_id, end_id + 1):
		var def := load_level_data(id)
		if def and def.level_id > 0:
			result.append({
				"level_id": def.level_id,
				"world": def.world,
				"title": def.title,
				"description": def.description,
				"score_targets": def.score_targets,
				"par_objects": def.par_objects,
				"targets_count": def.target_positions.size(),
			})
	return result


## Get total number of campaign levels across all worlds.
func get_total_level_count() -> int:
	return 20


## Instantiate all objects from a level definition into a parent node.
## Returns arrays of game_objects and targets.
func instantiate_level(level_def: LevelDefinition, parent: Node2D) -> Dictionary:
	var game_objects: Array[GameObject] = []
	var targets: Array[TargetObject] = []

	# Spawn objects
	for obj_data in level_def.objects:
		var obj_type: String = obj_data.get("type", "ball")
		var obj: GameObject = _spawn_object(obj_type, obj_data)
		if obj:
			parent.add_child(obj)
			obj.global_position = Vector2(obj_data.get("x", 0), obj_data.get("y", 0))
			obj.global_rotation = deg_to_rad(obj_data.get("rotation", 0))

			# Apply optional property overrides
			if obj_data.has("draggable"):
				obj.draggable = obj_data["draggable"]
			if obj_data.has("mass") and obj is PhysicalObject:
				obj.object_mass = obj_data["mass"]
				obj.mass = obj_data["mass"]

			# Store initial position after setting it
			obj.initial_position = obj.global_position
			obj.initial_rotation = obj.global_rotation
			obj.freeze = true

			game_objects.append(obj)

	# Spawn targets
	for tgt_data in level_def.target_positions:
		var target: TargetObject = _spawn_target(tgt_data)
		if target:
			parent.add_child(target)
			target.global_position = Vector2(tgt_data.get("x", 0), tgt_data.get("y", 0))
			targets.append(target)

	# Update object tray inventory if available
	if not level_def.inventory.is_empty() and parent.is_inside_tree():
		var ui := parent.get_tree().root.find_child("GameplayUI", true, false)
		if ui and ui.object_tray:
			ui.object_tray.set_inventory(level_def.inventory)

	print("[LevelLoader] Level %d loaded: %d objects, %d targets" % [
		level_def.level_id, game_objects.size(), targets.size()
	])

	return {
		"objects": game_objects,
		"targets": targets,
	}


## Spawn a game object by type.
func _spawn_object(obj_type: String, data: Dictionary) -> GameObject:
	if not _scene_cache.has(obj_type):
		push_warning("[LevelLoader] Unknown object type: %s" % obj_type)
		return null

	var scene: PackedScene = _scene_cache[obj_type]
	var instance: GameObject = scene.instantiate() as GameObject
	return instance


## Spawn a target.
func _spawn_target(data: Dictionary) -> TargetObject:
	if not _scene_cache.has("target"):
		push_warning("[LevelLoader] Target scene not cached")
		return null

	var scene: PackedScene = _scene_cache["target"]
	var instance: TargetObject = scene.instantiate() as TargetObject

	# Apply optional radius
	if data.has("radius"):
		instance.target_radius = data["radius"]

	return instance


## Create a fallback test level when JSON file doesn't exist.
func _create_default_level(level_id: int) -> LevelDefinition:
	var def := LevelDefinition.new()
	def.level_id = level_id
	def.world = 1
	def.title = "Test Experiment %d" % level_id
	def.arena_width = 1600.0
	def.arena_height = 800.0

	# Simple default: ball above target
	def.objects = [
		{"type": "ball", "x": 400, "y": 200, "draggable": true},
		{"type": "box", "x": 700, "y": 600, "draggable": false},
		{"type": "barrel", "x": 800, "y": 500, "draggable": false},
	]
	def.target_positions = [
		{"x": 1100, "y": 600},
	]
	def.score_targets = [50, 150, 350]

	return def


## Validate a level definition for common errors.
func validate_level(def: LevelDefinition) -> Array[String]:
	var errors: Array[String] = []

	if def.level_id <= 0:
		errors.append("Invalid level_id: %d" % def.level_id)

	if def.objects.is_empty():
		errors.append("No objects defined")

	if def.target_positions.is_empty():
		errors.append("No targets defined")

	for i in def.objects.size():
		var obj: Dictionary = def.objects[i]
		if not obj.has("type"):
			errors.append("Object %d: missing type" % i)
		elif obj["type"] not in OBJECT_SCENES:
			errors.append("Object %d: unknown type '%s'" % [i, obj["type"]])
		if not obj.has("x") or not obj.has("y"):
			errors.append("Object %d: missing position" % i)

	for i in def.target_positions.size():
		var tgt: Dictionary = def.target_positions[i]
		if not tgt.has("x") or not tgt.has("y"):
			errors.append("Target %d: missing position" % i)

	if def.score_targets.size() < 3:
		errors.append("score_targets should have 3 values")

	return errors
