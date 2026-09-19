## Camera Shake utility.
## Cinematic trauma-based screenshake.
## Can be called statically from anywhere: CameraShake.shake(0.6, 0.3)
class_name CameraShake
extends Node

static var instance: CameraShake = null

var camera: Camera2D = null
## Refined: less max offset to avoid nausea on mobile
var max_offset: Vector2 = Vector2(18.0, 15.0)
## Subtle roll — perceptible but not jarring on small screens
var max_roll: float = 0.05  # Radians

var _trauma: float = 0.0
## Exponential decay — higher power = sharper drop-off
var _trauma_power: float = 2.2
## Faster settle so objects stop bouncing after the initial impact
var _decay_rate: float = 2.5
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


## Trigger hit-stop impact freeze frame (near-freeze for visceral punch).
## Uses real-time timer so duration is not slowed by time_scale.
static func hit_stop(duration: float = 0.04) -> void:
	if instance and instance.is_inside_tree():
		# Don't nest hit-stops if slow-motion is already active
		var prev_scale := Engine.time_scale
		Engine.time_scale = 0.05  # Near-freeze (was 0.08)
		# Real-time timer (process_always=true, ignore_time_scale=true)
		var timer := instance.get_tree().create_timer(duration, true, false, true)
		timer.timeout.connect(func():
			Engine.time_scale = prev_scale
		)


func _add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
