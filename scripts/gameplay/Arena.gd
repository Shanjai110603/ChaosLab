## Arena — the physics playground where experiments happen.
## Contains walls, background, objects, targets, and the experiment controller.
extends Node2D

## The container for spawned game objects.
var objects_container: Node2D = null
## The experiment controller.
var experiment_controller: ExperimentController = null
## The level loader.
var level_loader: LevelLoader = null
## Current level definition.
var current_level: LevelDefinition = null

## Arena wall thickness.
const WALL_THICKNESS: float = 20.0
## Arena dimensions (set from level data).
var arena_width: float = 1600.0
var arena_height: float = 800.0
## Arena offset from screen edge.
var arena_offset: Vector2 = Vector2(160, 100)


func _ready() -> void:
	# Create objects container
	if not objects_container:
		objects_container = Node2D.new()
		objects_container.name = "ObjectsContainer"
		add_child(objects_container)

	# Create experiment controller
	experiment_controller = ExperimentController.new()
	experiment_controller.name = "ExperimentController"
	add_child(experiment_controller)

	# Create level loader
	level_loader = LevelLoader.new()
	level_loader.name = "LevelLoader"
	add_child(level_loader)

	# Connect signals
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.level_started.connect(_on_level_started)
	if get_node_or_null("/root/CosmeticManager"):
		CosmeticManager.skin_equipped.connect(func(_slot, _id): queue_redraw())

	# Find GameplayUI and connect object spawn signal
	var ui := get_tree().root.find_child("GameplayUI", true, false)
	if ui and ui.has_signal("object_spawn_requested"):
		ui.object_spawn_requested.connect(spawn_object)

	# Draw the arena background
	queue_redraw()

	# Load the first level or the current level
	if GameManager.current_level_id > 0:
		_load_level(GameManager.current_level_id)
	else:
		_load_level(1)


func _draw() -> void:
	var bg_rect := Rect2(arena_offset, Vector2(arena_width, arena_height))
	
	var bg_col := Color(0.04, 0.06, 0.09, 1.0)
	var grid_color := Color(0.08, 0.16, 0.24, 0.45)
	var major_grid_color := Color(0.12, 0.28, 0.42, 0.65)
	var border_color := Color(0.0, 0.65, 0.95, 0.75)
	var corner_color := Color(0.0, 1.0, 0.85, 0.95)

	if get_node_or_null("/root/CosmeticManager"):
		var theme_data: Dictionary = CosmeticManager.get_active_theme()
		bg_col = theme_data.get("bg_color", bg_col)
		var base_gc: Color = theme_data.get("grid_color", grid_color)
		grid_color = Color(base_gc.r, base_gc.g, base_gc.b, 0.35)
		major_grid_color = Color(base_gc.r, base_gc.g, base_gc.b, 0.65)
		border_color = theme_data.get("border_color", border_color)
		corner_color = theme_data.get("bracket_color", corner_color)

	# Deep laboratory background with subtle inner vignette
	draw_rect(bg_rect, bg_col)
	
	# Blueprint laboratory grid
	var grid_spacing := 60.0
	
	var col_idx := 0
	var x := arena_offset.x
	while x <= arena_offset.x + arena_width:
		var c := major_grid_color if (col_idx % 4 == 0) else grid_color
		var width := 1.5 if (col_idx % 4 == 0) else 1.0
		draw_line(Vector2(x, arena_offset.y), Vector2(x, arena_offset.y + arena_height), c, width)
		x += grid_spacing
		col_idx += 1
	
	var row_idx := 0
	var y := arena_offset.y
	while y <= arena_offset.y + arena_height:
		var c := major_grid_color if (row_idx % 4 == 0) else grid_color
		var width := 1.5 if (row_idx % 4 == 0) else 1.0
		draw_line(Vector2(arena_offset.x, y), Vector2(arena_offset.x + arena_width, y), c, width)
		y += grid_spacing
		row_idx += 1
	
	# Soft neon inner aura & border
	draw_rect(bg_rect.grow(-2), Color(border_color.r, border_color.g, border_color.b, 0.05), false, 4.0)
	draw_rect(bg_rect, border_color, false, 2.0)
	
	# Cybernetic corner brackets
	var bracket_len := 32.0
	var corners := [
		arena_offset,
		Vector2(arena_offset.x + arena_width, arena_offset.y),
		Vector2(arena_offset.x, arena_offset.y + arena_height),
		Vector2(arena_offset.x + arena_width, arena_offset.y + arena_height)
	]
	
	# Top-left
	draw_line(corners[0], corners[0] + Vector2(bracket_len, 0), corner_color, 3.5)
	draw_line(corners[0], corners[0] + Vector2(0, bracket_len), corner_color, 3.5)
	# Top-right
	draw_line(corners[1], corners[1] + Vector2(-bracket_len, 0), corner_color, 3.5)
	draw_line(corners[1], corners[1] + Vector2(0, bracket_len), corner_color, 3.5)
	# Bottom-left
	draw_line(corners[2], corners[2] + Vector2(bracket_len, 0), corner_color, 3.5)
	draw_line(corners[2], corners[2] + Vector2(0, -bracket_len), corner_color, 3.5)
	# Bottom-right
	draw_line(corners[3], corners[3] + Vector2(-bracket_len, 0), corner_color, 3.5)
	draw_line(corners[3], corners[3] + Vector2(0, -bracket_len), corner_color, 3.5)
	
	# Laboratory center target crosshair
	var center := arena_offset + Vector2(arena_width, arena_height) * 0.5
	draw_line(center - Vector2(16, 0), center + Vector2(16, 0), Color(0.0, 0.85, 1.0, 0.25), 1.0)
	draw_line(center - Vector2(0, 16), center + Vector2(0, 16), Color(0.0, 0.85, 1.0, 0.25), 1.0)
	draw_arc(center, 24.0, 0, TAU, 32, Color(0.0, 0.85, 1.0, 0.15), 1.0)


## Load and instantiate a level.
func _load_level(level_id: int) -> void:
	# Clear existing objects
	_clear_objects()

	# Load level definition
	current_level = level_loader.load_level_data(level_id)

	# Update arena dimensions
	arena_width = current_level.arena_width
	arena_height = current_level.arena_height

	# Create walls
	_create_walls()

	# Instantiate objects
	var result := level_loader.instantiate_level(current_level, objects_container)
	var game_objects: Array[GameObject] = []
	for obj in result["objects"]:
		if obj is GameObject:
			game_objects.append(obj)

	var targets: Array[TargetObject] = []
	for tgt in result["targets"]:
		if tgt is TargetObject:
			targets.append(tgt)

	# Setup experiment controller
	experiment_controller.setup_level(
		current_level.to_dict(),
		game_objects,
		targets
	)

	# Update game state
	GameManager.current_level_id = level_id
	GameManager.change_state(GameManager.GameState.PLACING)

	queue_redraw()
	print("[Arena] Level %d loaded" % level_id)


## Load a custom LevelDefinition directly (used for Daily Experiments and Sandbox).
func load_custom_level(def: LevelDefinition) -> void:
	_clear_objects()
	current_level = def
	arena_width = current_level.arena_width
	arena_height = current_level.arena_height
	_create_walls()

	var result := level_loader.instantiate_level(current_level, objects_container)
	var game_objects: Array[GameObject] = []
	for obj in result["objects"]:
		if obj is GameObject:
			game_objects.append(obj)

	var targets: Array[TargetObject] = []
	for tgt in result["targets"]:
		if tgt is TargetObject:
			targets.append(tgt)

	experiment_controller.setup_level(
		current_level.to_dict(),
		game_objects,
		targets
	)
	GameManager.current_level_id = def.level_id
	GameManager.change_state(GameManager.GameState.PLACING)
	queue_redraw()
	print("[Arena] Custom level '%s' loaded" % def.title)


## Create physics walls around the arena.
func _create_walls() -> void:
	# Remove existing walls
	for child in get_children():
		if child.name.begins_with("Wall"):
			child.queue_free()

	var wall_data := [
		{"name": "WallTop", "pos": Vector2(arena_offset.x + arena_width / 2, arena_offset.y - WALL_THICKNESS / 2), "size": Vector2(arena_width + WALL_THICKNESS * 2, WALL_THICKNESS)},
		{"name": "WallBottom", "pos": Vector2(arena_offset.x + arena_width / 2, arena_offset.y + arena_height + WALL_THICKNESS / 2), "size": Vector2(arena_width + WALL_THICKNESS * 2, WALL_THICKNESS)},
		{"name": "WallLeft", "pos": Vector2(arena_offset.x - WALL_THICKNESS / 2, arena_offset.y + arena_height / 2), "size": Vector2(WALL_THICKNESS, arena_height)},
		{"name": "WallRight", "pos": Vector2(arena_offset.x + arena_width + WALL_THICKNESS / 2, arena_offset.y + arena_height / 2), "size": Vector2(WALL_THICKNESS, arena_height)},
	]

	for wd in wall_data:
		var wall := StaticBody2D.new()
		wall.name = wd["name"]
		wall.position = wd["pos"]
		wall.collision_layer = 0b00001  # Layer 1 = walls
		wall.collision_mask = 0

		var shape := RectangleShape2D.new()
		shape.size = wd["size"]
		var col := CollisionShape2D.new()
		col.shape = shape
		wall.add_child(col)

		# Visual for walls
		var visual := ColorRect.new()
		visual.color = Color(0.2, 0.3, 0.4, 0.8)
		visual.size = wd["size"]
		visual.position = -wd["size"] / 2
		wall.add_child(visual)

		add_child(wall)


## Clear all spawned objects from the arena.
func _clear_objects() -> void:
	if objects_container:
		for child in objects_container.get_children():
			child.queue_free()
	# Clean any lingering temporary VFX children
	for child in get_children():
		if child is ImpactSpark or child is FloatingText or child is ExplosionEffect:
			child.queue_free()


## Handle game state changes.
func _on_state_changed(_old: GameManager.GameState, _new: GameManager.GameState) -> void:
	pass


## Handle level start request.
func _on_level_started(level_id: int) -> void:
	_load_level(level_id)


## Dynamically spawn an object into the arena (from object tray).
func spawn_object(object_type: String, world_pos: Vector2) -> GameObject:
	var type_clean := object_type.strip_edges().to_lower()
	var scene_name := type_clean.capitalize()
	var scene_path := "res://scenes/objects/%s.tscn" % scene_name
	
	var scene := load(scene_path) as PackedScene
	if not scene:
		print("[Arena] Could not load object scene: %s" % scene_path)
		return null
		
	var obj := scene.instantiate() as GameObject
	if not obj:
		return null
		
	obj.global_position = world_pos
	objects_container.add_child(obj)
	
	if experiment_controller:
		experiment_controller.register_object(obj)
		
	InputManager._start_drag(obj, world_pos)
	print("[Arena] Spawned dynamic %s at %s" % [object_type, str(world_pos)])
	return obj

