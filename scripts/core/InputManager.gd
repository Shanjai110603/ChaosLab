## Unified input abstraction layer.
## Translates mouse/touch/keyboard into game actions.
## Autoload singleton.
class_name InputManagerClass
extends Node

## Emitted when an object is selected (clicked/tapped).
signal object_selected(object: Node2D, position: Vector2)
## Emitted when a drag operation updates.
signal object_dragged(object: Node2D, position: Vector2)
## Emitted when a drag operation ends.
signal object_released(object: Node2D, position: Vector2)
## Emitted when an object is rotated.
signal object_rotated(object: Node2D, degrees: float)
## Emitted on any tap/click that doesn't hit a draggable object.
signal empty_tap(position: Vector2)
## Emitted when grid snap state changes.
signal grid_snap_toggled(enabled: bool)

## Whether the player is currently dragging an object.
var is_dragging: bool = false
## The object currently being dragged or selected.
var dragged_object: Node2D = null
## Offset from object origin to grab point.
var drag_offset: Vector2 = Vector2.ZERO
## The object currently hovered (desktop only).
var hovered_object: Node2D = null

## Grid snap settings.
var grid_snap_enabled: bool = false
var grid_size: float = 30.0

## Minimum drag distance to distinguish tap from drag.
const DRAG_THRESHOLD: float = 5.0

var _press_position: Vector2 = Vector2.ZERO
var _is_pressing: bool = false
var _drag_started: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[InputManager] Initialized with rotation & grid-snap support")


func _unhandled_input(event: InputEvent) -> void:
	# Don't process input during menu or result states
	if GameManager.current_state == GameManager.GameState.MENU:
		return
	if GameManager.current_state == GameManager.GameState.RESULT:
		return
	if GameManager.current_state == GameManager.GameState.PAUSED:
		return

	# Handle GO action
	if event.is_action_pressed("go"):
		GameManager.trigger_go()
		get_viewport().set_input_as_handled()
		return

	# Handle RESET action
	if event.is_action_pressed("reset"):
		GameManager.trigger_reset()
		get_viewport().set_input_as_handled()
		return

	# Handle UNDO action
	if event.is_action_pressed("undo"):
		get_viewport().set_input_as_handled()
		return

	# Toggle Grid Snap with 'G' key
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			toggle_grid_snap()
			get_viewport().set_input_as_handled()
			return

		# Rotate object with 'R' key during PLACING state
		if event.keycode == KEY_R and GameManager.current_state == GameManager.GameState.PLACING:
			var rot_step: float = -45.0 if event.shift_pressed else 45.0
			rotate_selected_object(rot_step)
			get_viewport().set_input_as_handled()
			return

	# Mouse wheel rotation while dragging or hovering an object
	if event is InputEventMouseButton and GameManager.current_state == GameManager.GameState.PLACING:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				rotate_selected_object(15.0)
				get_viewport().set_input_as_handled()
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				rotate_selected_object(-15.0)
				get_viewport().set_input_as_handled()
				return

	# Mouse/touch dragging input during PLACING state
	if GameManager.current_state != GameManager.GameState.PLACING:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _is_pressing:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event as InputEventScreenDrag)


func rotate_selected_object(degrees: float) -> void:
	if dragged_object and dragged_object.has_method("rotate_by_degrees"):
		dragged_object.rotate_by_degrees(degrees)
		object_rotated.emit(dragged_object, degrees)


func toggle_grid_snap() -> bool:
	grid_snap_enabled = not grid_snap_enabled
	grid_snap_toggled.emit(grid_snap_enabled)
	return grid_snap_enabled


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_is_pressing = true
		_press_position = event.position
		_drag_started = false
		_try_select_at(event.position)
	else:
		if is_dragging and dragged_object:
			object_released.emit(dragged_object, event.position)
		elif not _drag_started:
			empty_tap.emit(event.position)
		_end_drag()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _is_pressing:
		return

	var distance := event.position.distance_to(_press_position)
	if distance > DRAG_THRESHOLD and not _drag_started:
		_drag_started = true

	if _drag_started and is_dragging and dragged_object:
		object_dragged.emit(dragged_object, event.position)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.index != 0:
		return

	if event.pressed:
		_is_pressing = true
		_press_position = event.position
		_drag_started = false
		_try_select_at(event.position)
	else:
		if is_dragging and dragged_object:
			object_released.emit(dragged_object, event.position)
		elif not _drag_started:
			empty_tap.emit(event.position)
		_end_drag()


func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if event.index != 0:
		return
	if not _is_pressing:
		return

	var distance := event.position.distance_to(_press_position)
	if distance > DRAG_THRESHOLD:
		_drag_started = true

	if _drag_started and is_dragging and dragged_object:
		object_dragged.emit(dragged_object, event.position)


## Attempt to select a draggable object at the given screen position.
func _try_select_at(screen_pos: Vector2) -> void:
	var viewport := get_viewport()
	if not viewport:
		return

	var canvas_transform := viewport.get_canvas_transform()
	var world_pos: Vector2 = canvas_transform.affine_inverse() * screen_pos

	var space_state := viewport.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 0b10000  # Layer 5 = draggable
	query.collide_with_bodies = true

	var results := space_state.intersect_point(query, 1)
	if results.size() > 0:
		var body: Node2D = results[0]["collider"]
		if body.has_method("is_draggable") and body.is_draggable():
			_start_drag(body, world_pos)


## Begin dragging an object.
func _start_drag(object: Node2D, world_pos: Vector2) -> void:
	dragged_object = object
	is_dragging = true
	drag_offset = object.global_position - world_pos
	object_selected.emit(object, world_pos)


## End the current drag operation.
func _end_drag() -> void:
	is_dragging = false
	drag_offset = Vector2.ZERO
	_is_pressing = false
	_drag_started = false
