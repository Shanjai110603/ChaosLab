## Arena — the physics playground where experiments happen.
## Contains walls, background, objects, targets, and the experiment controller.
extends Node2D

## The container for spawned game objects.
@onready var objects_container: Node2D = $ObjectsContainer
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

	# Draw the arena background
	queue_redraw()

	# Load the first level or the current level
	if GameManager.current_level_id > 0:
		_load_level(GameManager.current_level_id)
	else:
		_load_level(1)


func _draw() -> void:
	# Arena background
	var bg_rect := Rect2(arena_offset, Vector2(arena_width, arena_height))
	draw_rect(bg_rect, Color(0.08, 0.1, 0.14))

	# Grid lines for laboratory feel
	var grid_color := Color(0.12, 0.15, 0.2, 0.3)
	var grid_spacing := 80.0

	var x := arena_offset.x
	while x <= arena_offset.x + arena_width:
		draw_line(Vector2(x, arena_offset.y), Vector2(x, arena_offset.y + arena_height), grid_color, 1.0)
		x += grid_spacing

	var y := arena_offset.y
	while y <= arena_offset.y + arena_height:
		draw_line(Vector2(arena_offset.x, y), Vector2(arena_offset.x + arena_width, y), grid_color, 1.0)
		y += grid_spacing

	# Arena border
	var border_color := Color(0.3, 0.5, 0.7, 0.8)
	draw_rect(bg_rect, border_color, false, 3.0)


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


## Handle game state changes.
func _on_state_changed(_old: GameManager.GameState, _new: GameManager.GameState) -> void:
	pass


## Handle level start request.
func _on_level_started(level_id: int) -> void:
	_load_level(level_id)
