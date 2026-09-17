## Camera Shake utility.
## Cinematic trauma-based screenshake.
## Can be called statically from anywhere: CameraShake.shake(0.6, 0.3)
class_name CameraShake
extends Node

static var instance: CameraShake = null

var camera: Camera2D = null
var max_offset: Vector2 = Vector2(25.0, 20.0)
var max_roll: float = 0.08  # Radians

var _trauma: float = 0.0
var _trauma_power: float = 2.0
var _decay_rate: float = 2.2
var _original_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Find active camera in tree
	if get_parent() is Camera2D:
		camera = get_parent() as Camera2D
		_original_offset = camera.offset
	else:
		# Fallback: search for first Camera2D in viewport
		var cam := get_viewport().get_camera_2d()
		if cam:
			camera = cam
			_original_offset = camera.offset


func _process(delta: float) -> void:
	if not camera:
		var cam := get_viewport().get_camera_2d()
		if cam:
			camera = cam
			_original_offset = camera.offset
		else:
			return

	if _trauma > 0.0:
		_trauma = maxf(_trauma - _decay_rate * delta, 0.0)
		var shake_amount := pow(_trauma, _trauma_power)
		
		camera.offset = _original_offset + Vector2(
			max_offset.x * shake_amount * randf_range(-1.0, 1.0),
			max_offset.y * shake_amount * randf_range(-1.0, 1.0)
		)
		camera.rotation = max_roll * shake_amount * randf_range(-1.0, 1.0)
	else:
		camera.offset = _original_offset
		camera.rotation = 0.0


## Trigger screenshake. Can be called as CameraShake.shake(0.7) from any object.
static func shake(amount: float = 0.5, _duration: float = 0.25) -> void:
	if instance:
		instance._add_trauma(amount)


func _add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
