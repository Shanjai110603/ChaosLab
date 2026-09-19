## AudioFilterController — Low-pass filter modulation for audio buses.
## Autoload singleton.
## Applies a cinematic low-pass filter to the SFX bus during slow-motion.
## Usage: AudioFilterController.set_lowpass(1200.0, 0.08)
class_name AudioFilterController
extends Node

static var instance: AudioFilterController = null

const BUS_SFX: StringName = &"SFX"
const DEFAULT_CUTOFF_HZ: float = 20000.0

var _lowpass_effect: AudioEffectLowPassFilter = null
var _bus_idx: int = -1


func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Defer setup so AudioManager has time to create buses first
	call_deferred("_setup_lowpass")


func _setup_lowpass() -> void:
	_bus_idx = AudioServer.get_bus_index(BUS_SFX)
	if _bus_idx == -1:
		push_warning("[AudioFilterController] SFX bus not found — filter will not apply.")
		return

	_lowpass_effect = AudioEffectLowPassFilter.new()
	_lowpass_effect.cutoff_hz = DEFAULT_CUTOFF_HZ
	_lowpass_effect.resonance = 0.5
	AudioServer.add_bus_effect(_bus_idx, _lowpass_effect)
	print("[AudioFilterController] Low-pass filter installed on SFX bus at %.0f Hz" % DEFAULT_CUTOFF_HZ)


## Set the low-pass cutoff frequency, with optional smooth transition.
## hz: target cutoff in Hertz (20 = fully muffled, 20000 = no filter)
## transition_sec: time to reach target. 0 = instant snap.
static func set_lowpass(hz: float, transition_sec: float = 0.08) -> void:
	if not instance or not instance._lowpass_effect:
		return

	hz = clampf(hz, 20.0, 20000.0)

	if transition_sec <= 0.0:
		instance._lowpass_effect.cutoff_hz = hz
		return

	var t := instance.create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
	t.tween_property(instance._lowpass_effect, "cutoff_hz", hz, transition_sec) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Restore to full-range (no filter) immediately.
static func reset() -> void:
	set_lowpass(DEFAULT_CUTOFF_HZ, 0.0)


## Current cutoff Hz value.
static func get_current_hz() -> float:
	if instance and instance._lowpass_effect:
		return instance._lowpass_effect.cutoff_hz
	return DEFAULT_CUTOFF_HZ
