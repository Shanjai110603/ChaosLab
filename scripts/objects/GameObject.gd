## Base game object class for all physics objects in the arena.
## Extends RigidBody2D. Provides drag interaction, undo state, and visual feedback.
class_name GameObject
extends RigidBody2D

## Emitted when this object is selected by the player.
signal selected()
## Emitted when this object is released after dragging.
signal released()
## Emitted when this object participates in a chain reaction event.
signal chain_event(event_type: String, other: Node2D)

## Display name for this object type (used in UI).
@export var object_name: String = "Object"
## Object type identifier.
@export var object_type: String = "generic"
## Whether the player can drag this object during PLACING state.
@export var draggable: bool = true
## Whether this object is currently active in the experiment.
@export var is_active: bool = true

## The initial position when the level was loaded (for RESET).
var initial_position: Vector2 = Vector2.ZERO
## The initial rotation when the level was loaded.
var initial_rotation: float = 0.0
## Stack of previous positions for UNDO.
var _undo_stack: Array[Dictionary] = []
## Maximum undo steps.
const MAX_UNDO: int = 20
## Whether this object is currently being dragged.
var _is_being_dragged: bool = false
## Visual node for selection/hover highlight.
var _highlight: Node2D = null
## The main visual sprite/shape for this object.
var _visual: Node2D = null


## Whether this object's current placement position is valid.
var is_placement_valid: bool = true
## Snapshot dictionary before simulation started.
var _sim_snapshot: Dictionary = {}


func _ready() -> void:
	# Store initial transform for RESET
	initial_position = global_position
	initial_rotation = global_rotation

	# Add to game_objects group for tracking
	add_to_group("game_objects")

	# Set collision layer to objects (layer 2) and draggable (layer 5)
	collision_layer = 0b10010  # Layers 2 and 5
	collision_mask = 0b00111   # Collide with walls (1), objects (2), targets (3)

	# Connect to input manager signals
	InputManager.object_selected.connect(_on_input_selected)
	InputManager.object_dragged.connect(_on_input_dragged)
	InputManager.object_released.connect(_on_input_released)

	# Connect to game state changes
	GameManager.state_changed.connect(_on_game_state_changed)

	# Create highlight visual
	_create_highlight()

	# Listen for body contacts for chain reaction tracking
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


## Whether this object can currently be dragged.
func is_draggable() -> bool:
	return draggable and is_active and GameManager.current_state == GameManager.GameState.PLACING


## Rotate object by a given degree increment during placement.
func rotate_by_degrees(deg: float) -> void:
	if not is_draggable():
		return
	push_undo_state()
	rotation_degrees += deg
	if _visual:
		_visual.queue_redraw()
	if _highlight:
		_highlight.queue_redraw()


## Save simulation snapshot right before GO starts.
func save_sim_snapshot() -> void:
	_sim_snapshot = {
		"position": global_position,
		"rotation": global_rotation,
		"linear_velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"visible": visible,
		"freeze": freeze
	}


## Restore simulation snapshot on RESET.
func restore_sim_snapshot() -> void:
	if _sim_snapshot.is_empty():
		reset_to_initial()
		return
	global_position = _sim_snapshot.get("position", initial_position)
	global_rotation = _sim_snapshot.get("rotation", initial_rotation)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	visible = true
	freeze = true
	_is_being_dragged = false
	_on_reset()


## Save the current state to the undo stack.
func push_undo_state() -> void:
	var state := {
		"position": global_position,
		"rotation": global_rotation,
	}
	_undo_stack.push_back(state)
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack.pop_front()


## Restore the last state from the undo stack.
func pop_undo_state() -> bool:
	if _undo_stack.is_empty():
		return false
	var state: Dictionary = _undo_stack.pop_back()
	global_position = state["position"]
	global_rotation = state["rotation"]
	if _visual:
		_visual.queue_redraw()
	return true


## Reset to the initial level-load state.
func reset_to_initial() -> void:
	global_position = initial_position
	global_rotation = initial_rotation
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_undo_stack.clear()
	freeze = true  # Frozen during PLACING
	_is_being_dragged = false
	visible = true
	_on_reset()


## Override in subclasses for custom reset behavior.
func _on_reset() -> void:
	pass


## Freeze/unfreeze based on game state.
func _on_game_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	match new:
		GameManager.GameState.PLACING:
			freeze = true
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
		GameManager.GameState.SIMULATING:
			save_sim_snapshot()
			freeze = false
		GameManager.GameState.PAUSED:
			pass


## Handle selection from InputManager.
func _on_input_selected(object: Node2D, _pos: Vector2) -> void:
	if object != self:
		_set_highlighted(false)
		return
	if not is_draggable():
		return
	push_undo_state()
	_is_being_dragged = true
	_set_highlighted(true)
	freeze = true
	selected.emit()


## Handle drag from InputManager.
func _on_input_dragged(object: Node2D, screen_pos: Vector2) -> void:
	if object != self or not _is_being_dragged:
		return

	# Convert screen position to world position
	var viewport := get_viewport()
	var canvas_transform := viewport.get_canvas_transform()
	var world_pos: Vector2 = canvas_transform.affine_inverse() * screen_pos
	var target_pos := world_pos + InputManager.drag_offset

	# Snap to grid if enabled in InputManager
	if InputManager.grid_snap_enabled:
		var grid_size := InputManager.grid_size
		target_pos.x = roundf(target_pos.x / grid_size) * grid_size
		target_pos.y = roundf(target_pos.y / grid_size) * grid_size

	global_position = target_pos
	_update_placement_validity()


## Check if object is inside arena and not colliding with walls.
func _update_placement_validity() -> void:
	# Keep within reasonable arena bounds
	is_placement_valid = true
	if _highlight:
		_highlight.queue_redraw()


## Handle release from InputManager.
func _on_input_released(object: Node2D, _pos: Vector2) -> void:
	if object != self:
		return
	_is_being_dragged = false
	_set_highlighted(false)
	released.emit()


## Handle physics collision — report to chain reaction system.
func _on_body_entered(body: Node) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return
	if body is GameObject:
		chain_event.emit("collision", body)

	# Compute impact speed for audio and visual sparks
	var impact_speed := linear_velocity.length()
	var contact_pos := global_position
	if body is RigidBody2D:
		impact_speed = (linear_velocity - body.linear_velocity).length()
		contact_pos = (global_position + body.global_position) * 0.5
	elif body is Node2D:
		contact_pos = (global_position + body.global_position) * 0.5

	if impact_speed > 130.0:
		var mat := "wood"
		if object_type in ["ball", "metal_ball", "magnet", "seesaw"]:
			mat = "metal"
		elif object_type in ["bouncy_pad", "balloon"]:
			mat = "rubber"
		elif object_type in ["laser", "target"]:
			mat = "glass"
		AudioManager.play_impact(mat, impact_speed)
		if get_parent():
			ImpactSpark.create_at(contact_pos, get_parent())
		if impact_speed > 350.0:
			PlatformService.haptic_light()


## Create highlight/selection visual overlay.
func _create_highlight() -> void:
	pass


## Set the highlight visual on/off.
func _set_highlighted(highlighted: bool) -> void:
	if _highlight:
		_highlight.visible = highlighted
