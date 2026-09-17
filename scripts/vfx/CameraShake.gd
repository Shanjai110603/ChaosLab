## Camera Shake utility.
## Attach to a Camera2D node. Call shake() to trigger screen shake.
class_name CameraShake
extends Node

## The camera to shake.
var camera: Camera2D = null
## Maximum shake intensity (pixels).
var max_intensity: float = 10.0
## Current shake intensity.
var _intensity: float = 0.0
## Shake decay rate.
var _decay_rate: float = 5.0
## Original camera offset.
var _original_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Find the parent camera
	if get_parent() is Camera2D:
		camera = get_parent() as Camera2D
		_original_offset = camera.offset


func _process(delta: float) -> void:
	if not camera or _intensity <= 0.01:
		if camera:
			camera.offset = _original_offset
		return

	_intensity = lerpf(_intensity, 0.0, _decay_rate * delta)

	var shake_offset := Vector2(
		randf_range(-_intensity, _intensity),
		randf_range(-_intensity, _intensity),
	)
	camera.offset = _original_offset + shake_offset


## Trigger a screen shake.
func shake(intensity: float = 5.0, decay: float = 5.0) -> void:
	_intensity = minf(intensity, max_intensity)
	_decay_rate = decay
