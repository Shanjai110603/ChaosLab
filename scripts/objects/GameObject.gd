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
			freeze = false
		GameManager.GameState.PAUSED:
			pass  # Tree pause handles this


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
	global_position = world_pos + InputManager.drag_offset


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


## Create highlight/selection visual overlay.
func _create_highlight() -> void:
	# Subclasses can override for custom highlights
	pass


## Set the highlight visual on/off.
func _set_highlighted(highlighted: bool) -> void:
	if _highlight:
		_highlight.visible = highlighted
	# Subclasses can add additional feedback (color change, scale, etc.)
