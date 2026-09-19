## Chain Reaction Manager.
## Tracks sequence of physics events during simulation.
## Calculates combo multipliers, floating score popups, and reaction telemetry.
class_name ChainReactionManager
extends Node

signal chain_event_registered(event: Dictionary)
signal chain_updated(chain_count: int, total_score: int)
signal chain_complete(result: Dictionary)

var events: Array[Dictionary] = []
var chain_count: int = 0
var total_score: int = 0
var targets_destroyed: int = 0
var targets_hit: int = 0
var chain_start_time: float = 0.0
var max_simultaneous: int = 0
var affected_objects: Array[Node] = []

## Combo window duration. Events occurring within this window maintain/elevate combo.
const COMBO_WINDOW: float = 1.8         # Extended: more forgiving, more fun
var _last_event_time: float = 0.0
var _combo_multiplier: float = 1.0
## How much the multiplier increases per in-window event.
const COMBO_INCREMENT: float = 0.4      # was 0.35
## Maximum combo multiplier ceiling.
const COMBO_CAP: float = 8.0            # was 6.0

const SCORE_VALUES: Dictionary = {
	"collision":        25,    # was 15
	"explosion":        200,   # was 80
	"ignition":         100,   # was 40
	"launch":           120,   # was 50
	"target_hit":       1000,  # was 250
	"target_destroyed": 2500,  # was 500
	"wall_broken":      350,   # NEW
}

const CHAIN_LABELS: Dictionary = {
	2:  "DOUBLE!",
	3:  "TRIPLE!",
	5:  "SUPER CHAIN!",
	8:  "CHAOS MATRIX!",
	12: "MEGA CATACLYSM!",
	18: "TOTAL CHAOS!",
}

## Combo tiers that trigger a vignette pulse.
const VIGNETTE_PULSE_TIERS: Array[int] = [4, 6, 8]

var _frame_events: int = 0
var _is_tracking: bool = false


func _ready() -> void:
	GameManager.experiment_started.connect(_on_experiment_started)
	GameManager.state_changed.connect(_on_state_changed)


func _physics_process(_delta: float) -> void:
	if not _is_tracking:
		return

	if _frame_events > max_simultaneous:
		max_simultaneous = _frame_events
	_frame_events = 0


func _on_experiment_started() -> void:
	reset()
	_is_tracking = true
	chain_start_time = Time.get_ticks_msec() / 1000.0
	_last_event_time = chain_start_time


func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	if new != GameManager.GameState.SIMULATING and _is_tracking:
		_is_tracking = false


## Register a chain event with source and target node context.
func register_event(event_type: String, source: Node = null, target_node: Node = null) -> void:
	if not _is_tracking:
		return

	var current_time: float = Time.get_ticks_msec() / 1000.0
	var time_since_last: float = current_time - _last_event_time
	_last_event_time = current_time

	chain_count += 1
	_frame_events += 1

	# Combo multiplier scaling
	if time_since_last <= COMBO_WINDOW:
		_combo_multiplier = clampf(_combo_multiplier + COMBO_INCREMENT, 1.0, COMBO_CAP)
	else:
		_combo_multiplier = 1.0

	# Vignette pulse at milestone combo tiers
	var tier := int(_combo_multiplier)
	if tier in VIGNETTE_PULSE_TIERS:
		var vignette := get_tree().root.find_child("ScreenVignette", true, false)
		if vignette and vignette.has_method("pulse_combo"):
			vignette.pulse_combo(tier)

	var base_score: int = SCORE_VALUES.get(event_type, 10)
	var event_score: int = int(base_score * _combo_multiplier)
	total_score += event_score

	# Track affected objects
	if source and source not in affected_objects:
		affected_objects.append(source)
	if target_node and target_node not in affected_objects:
		affected_objects.append(target_node)

	if event_type == "target_hit":
		targets_hit += 1
	elif event_type == "target_destroyed":
		targets_destroyed += 1

	var event := {
		"type": event_type,
		"chain": chain_count,
		"score": event_score,
		"multiplier": _combo_multiplier,
		"time": current_time - chain_start_time,
		"source": source.name if source else "",
		"target": target_node.name if target_node else "",
	}
	events.append(event)

	# Spawn floating text at event location
	if source is Node2D and is_instance_valid(source) and source.is_inside_tree():
		var spawn_pos: Vector2 = (source as Node2D).global_position
		var text := "+%d" % event_score
		var col := Color(1.0, 0.85, 0.2)
		
		if event_type == "explosion":
			text = "BOOM! +%d" % event_score
			col = Color(1.0, 0.35, 0.1)
		elif event_type == "target_hit":
			text = "BULLSEYE! +%d" % event_score
			col = Color(0.0, 1.0, 0.6)
		elif event_type == "target_destroyed":
			text = "SHATTER! +%d" % event_score
			col = Color(0.0, 0.9, 1.0)
		elif _combo_multiplier > 1.5:
			text = "x%.1f +%d" % [_combo_multiplier, event_score]
			
		FloatingText.spawn(source.get_parent(), text, spawn_pos, col)

	# Trigger procedural audio feedback
	if event_type == "explosion":
		AudioManager.play_explosion(1.0)
	elif event_type in ["target_hit", "target_destroyed"]:
		AudioManager.play_chime(int(_combo_multiplier * 1.5))
	else:
		AudioManager.play_chime(int(_combo_multiplier))

	# Notify UI
	var label_text := get_chain_label()
	var ui := get_tree().root.find_child("GameplayUI", true, false)
	if ui and ui.has_method("update_chain"):
		ui.update_chain(chain_count, total_score, label_text)

	chain_event_registered.emit(event)
	chain_updated.emit(chain_count, total_score)


func get_chain_label() -> String:
	var label := ""
	for threshold in CHAIN_LABELS:
		if chain_count >= threshold:
			label = CHAIN_LABELS[threshold]
	return label


func get_result() -> Dictionary:
	var duration: float = 0.0
	if events.size() > 0:
		duration = events[-1]["time"]

	return {
		"chain_count": chain_count,
		"total_score": total_score,
		"events": events.duplicate(),
		"targets_hit": targets_hit,
		"targets_destroyed": targets_destroyed,
		"affected_objects": affected_objects.size(),
		"max_simultaneous": max_simultaneous,
		"duration": duration,
		"label": get_chain_label(),
	}


func reset() -> void:
	events.clear()
	chain_count = 0
	total_score = 0
	targets_destroyed = 0
	targets_hit = 0
	chain_start_time = 0.0
	_last_event_time = 0.0
	_combo_multiplier = 1.0
	max_simultaneous = 0
	affected_objects.clear()
	_frame_events = 0
	_is_tracking = false
