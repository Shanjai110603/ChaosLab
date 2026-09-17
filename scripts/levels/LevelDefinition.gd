## Level Definition — data class for level configuration.
## Loaded from JSON files. Describes objects, positions, objectives, and targets.
class_name LevelDefinition
extends RefCounted

## Unique level identifier (1-based).
var level_id: int = 0
## World number (1-10).
var world: int = 1
## Display title.
var title: String = ""
## Description/hint text.
var description: String = ""

## Arena dimensions.
var arena_width: float = 1600.0
var arena_height: float = 800.0

## Background color.
var bg_color: Color = Color(0.12, 0.14, 0.18)

## Objects to spawn. Each entry: {type, x, y, rotation, draggable, properties}
var objects: Array[Dictionary] = []

## Target positions. Each entry: {x, y}
var target_positions: Array[Dictionary] = []

## Score targets for star rating: [1-star, 2-star, 3-star].
var score_targets: Array = [100, 300, 600]

## Time limit for simulation (0 = no limit).
var time_limit: float = 15.0

## Allowed object types the player can use (empty = all).
var allowed_objects: Array[String] = []

## Optional tutorial hints.
var hints: Array[String] = []


## Create a LevelDefinition from a dictionary (parsed from JSON).
static func from_dict(data: Dictionary) -> LevelDefinition:
	var def := LevelDefinition.new()
	def.level_id = data.get("level_id", 0)
	def.world = data.get("world", 1)
	def.title = data.get("title", "Experiment %d" % def.level_id)
	def.description = data.get("description", "")
	def.arena_width = data.get("arena_width", 1600.0)
	def.arena_height = data.get("arena_height", 800.0)

	var bg: Variant = data.get("bg_color", null)
	if bg is String:
		def.bg_color = Color.from_string(bg, Color(0.12, 0.14, 0.18))
	elif bg is Array and bg.size() >= 3:
		def.bg_color = Color(bg[0], bg[1], bg[2])

	def.objects = []
	var objs: Variant = data.get("objects", [])
	if objs is Array:
		for obj in objs:
			if obj is Dictionary:
				def.objects.append(obj)

	def.target_positions = []
	var tgts: Variant = data.get("targets", [])
	if tgts is Array:
		for tgt in tgts:
			if tgt is Dictionary:
				def.target_positions.append(tgt)

	var st: Variant = data.get("score_targets", [100, 300, 600])
	if st is Array:
		def.score_targets = st

	def.time_limit = data.get("time_limit", 15.0)

	var ao: Variant = data.get("allowed_objects", [])
	if ao is Array:
		for a in ao:
			def.allowed_objects.append(str(a))

	var hints_data: Variant = data.get("hints", [])
	if hints_data is Array:
		for h in hints_data:
			def.hints.append(str(h))

	return def


## Convert to dictionary (for serialization/validation).
func to_dict() -> Dictionary:
	return {
		"level_id": level_id,
		"world": world,
		"title": title,
		"description": description,
		"arena_width": arena_width,
		"arena_height": arena_height,
		"objects": objects,
		"targets": target_positions,
		"score_targets": score_targets,
		"time_limit": time_limit,
		"allowed_objects": allowed_objects,
		"hints": hints,
	}
