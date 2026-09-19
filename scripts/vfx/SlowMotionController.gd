## SlowMotionController — Climactic slow-motion time dilation manager.
## Autoload singleton. Called statically from anywhere.
## Usage: SlowMotionController.trigger()
##
## When triggered on the final target shatter or 4x+ combo:
##   1. Engine.time_scale ramps down to 0.2x over 0.1s (real-time)
##   2. Holds at 0.2x for 0.4s real-time
##   3. Ramps back to 1.0x over 0.25s real-time
##   4. Simultaneously applies a low-pass audio filter via AudioFilterController
class_name SlowMotionController
extends Node

static var instance: SlowMotionController = null

## Target time scale during slow-motion.
const SLOWMO_SCALE: float = 0.2
## Real-time seconds to ramp down from 1.0 to SLOWMO_SCALE.
const RAMP_DOWN_DURATION: float = 0.10
## Real-time seconds to hold at slow-motion.
const HOLD_DURATION: float = 0.40
## Real-time seconds to ramp back to 1.0.
const RAMP_UP_DURATION: float = 0.25

## Hz cutoff applied to SFX bus during slow-motion.
const SLOWMO_LOWPASS_HZ: float = 1200.0
const NORMAL_LOWPASS_HZ: float = 20000.0

var _is_active: bool = false
var _saved_time_scale: float = 1.0


func _ready() -> void:
	instance = self
	# Must run even while game is paused / during slowmo itself
	process_mode = Node.PROCESS_MODE_ALWAYS


## Trigger climactic slow-motion. Safe to call from any object.
## Does nothing if already active.
static func trigger() -> void:
	if instance and not instance._is_active:
		instance._do_slowmo()


## Force-cancel slow-motion immediately (e.g., on level reset or pause).
static func cancel() -> void:
	if instance and instance._is_active:
		Engine.time_scale = instance._saved_time_scale
		instance._is_active = false
		# Restore audio filter
		if AudioFilterController.instance:
			AudioFilterController.set_lowpass(NORMAL_LOWPASS_HZ, 0.0)


## Whether slow-motion is currently running.
static func is_active() -> bool:
	return instance != null and instance._is_active


func _do_slowmo() -> void:
	_is_active = true
	_saved_time_scale = Engine.time_scale

	# Apply low-pass filter immediately
	if AudioFilterController.instance:
		AudioFilterController.set_lowpass(SLOWMO_LOWPASS_HZ, 0.05)

	# All tweens use REAL TIME so they aren't slowed by time_scale
	var t := create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)

	# Ramp down
	t.tween_method(_set_time_scale, 1.0, SLOWMO_SCALE, RAMP_DOWN_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Hold
	t.tween_interval(HOLD_DURATION)

	# Ramp up
	t.tween_method(_set_time_scale, SLOWMO_SCALE, 1.0, RAMP_UP_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Restore audio filter and mark complete
	t.tween_callback(func():
		_is_active = false
		if AudioFilterController.instance:
			AudioFilterController.set_lowpass(NORMAL_LOWPASS_HZ, 0.08)
	)


func _set_time_scale(value: float) -> void:
	Engine.time_scale = clampf(value, 0.0, 4.0)
