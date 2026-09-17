## Target — static goal object that detects hits.
## The player must cause physics objects to hit all targets to complete a level.
class_name TargetObject
extends StaticBody2D

## Emitted when this target is hit by a physics object.
signal target_hit(target: TargetObject)
## Emitted when this target is destroyed (hit with enough force).
signal target_destroyed(target: TargetObject)

## Display name.
@export var object_name: String = "Target"
## Target radius.
@export var target_radius: float = 28.0
## Minimum impact velocity to count as a "hit".
@export var min_hit_velocity: float = 30.0
## Whether this target has been hit.
var is_hit: bool = false
## Whether this target has been destroyed.
var is_destroyed: bool = false

## Visual node.
var _visual: Node2D = null
## Detection area.
var _detection_area: Area2D = null


func _ready() -> void:
	add_to_group("game_objects")
	add_to_group("targets")

	# Targets are on layer 3
	collision_layer = 0b00100  # Layer 3
	collision_mask = 0

	_create_visual()
	_create_collision()
	_create_detection_area()

	GameManager.state_changed.connect(_on_game_state_changed)


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_target.bind(_visual))
	_visual.queue_redraw()


func _draw_target(node: Node2D) -> void:
	if is_destroyed:
		# Destroyed state — faded X
		var x_color := Color(0.5, 0.5, 0.5, 0.3)
		var s := target_radius * 0.7
		node.draw_line(Vector2(-s, -s), Vector2(s, s), x_color, 3.0)
		node.draw_line(Vector2(-s, s), Vector2(s, -s), x_color, 3.0)
		return

	# Outer ring (red)
	node.draw_circle(Vector2.ZERO, target_radius, Color(0.9, 0.15, 0.15))
	# White ring
	node.draw_circle(Vector2.ZERO, target_radius * 0.75, Color.WHITE)
	# Middle ring (red)
	node.draw_circle(Vector2.ZERO, target_radius * 0.5, Color(0.9, 0.15, 0.15))
	# Inner white ring
	node.draw_circle(Vector2.ZERO, target_radius * 0.3, Color.WHITE)
	# Bullseye
	node.draw_circle(Vector2.ZERO, target_radius * 0.15, Color(0.9, 0.15, 0.15))

	# Outline
	node.draw_arc(Vector2.ZERO, target_radius, 0, TAU, 32, Color.BLACK, 2.0, true)

	# Hit indicator
	if is_hit:
		var check_color := Color(0.1, 0.8, 0.2)
		var offset := Vector2(target_radius * 0.5, -target_radius * 0.5)
		node.draw_circle(offset, 8, check_color)
		# Checkmark
		node.draw_line(offset + Vector2(-4, 0), offset + Vector2(-1, 3), Color.WHITE, 2.0)
		node.draw_line(offset + Vector2(-1, 3), offset + Vector2(4, -4), Color.WHITE, 2.0)


func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = target_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_detection_area() -> void:
	# Area2D to detect when a physics body enters the target zone
	_detection_area = Area2D.new()
	_detection_area.name = "DetectionArea"
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 0b00010  # Detect objects (layer 2)
	_detection_area.monitoring = false  # Only enabled during simulation

	var shape := CircleShape2D.new()
	shape.radius = target_radius * 1.2  # Slightly larger for generous detection
	var col := CollisionShape2D.new()
	col.shape = shape
	_detection_area.add_child(col)
	_detection_area.body_entered.connect(_on_body_entered_detection)
	add_child(_detection_area)


func _on_body_entered_detection(body: Node) -> void:
	if is_destroyed:
		return
	if body is RigidBody2D:
		_register_hit(body)


func _register_hit(body: Node2D) -> void:
	if not is_hit:
		is_hit = true
		target_hit.emit(self)
		if _visual:
			_visual.queue_redraw()

	# Check if impact is strong enough for destruction
	if body is RigidBody2D:
		var vel: float = body.linear_velocity.length()
		if vel > min_hit_velocity * 3:  # Significant impact → destroy
			_destroy()


func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	target_destroyed.emit(self)
	if _visual:
		_visual.queue_redraw()
	# Scale-down animation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3).set_ease(Tween.EASE_IN)


func _on_game_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	match new:
		GameManager.GameState.SIMULATING:
			if _detection_area:
				_detection_area.monitoring = true
		GameManager.GameState.PLACING:
			if _detection_area:
				_detection_area.monitoring = false


## Reset target to initial state.
func reset() -> void:
	is_hit = false
	is_destroyed = false
	scale = Vector2.ONE
	if _detection_area:
		_detection_area.monitoring = false
	if _visual:
		_visual.queue_redraw()
