## Chain Reaction Manager.
## Tracks the sequence of physics events during an experiment simulation.
## Calculates chain count, score, and reaction data.
class_name ChainReactionManager
extends Node

## Emitted when a new chain event is registered.
signal chain_event_registered(event: Dictionary)
## Emitted when the chain count increases.
signal chain_updated(chain_count: int, total_score: int)
## Emitted when the chain reaction ends (simulation settles).
signal chain_complete(result: Dictionary)

## All events in the current chain.
var events: Array[Dictionary] = []
## Current chain count (sequential events).
var chain_count: int = 0
## Total score accumulated.
var total_score: int = 0
## Number of targets destroyed.
var targets_destroyed: int = 0
## Number of targets hit (but not necessarily destroyed).
var targets_hit: int = 0
## Time the chain started.
var chain_start_time: float = 0.0
## Maximum simultaneous events in a single frame.
var max_simultaneous: int = 0
## Objects that have been part of the chain.
var affected_objects: Array[Node] = []

## Score values for different event types.
const SCORE_VALUES: Dictionary = {
	"collision": 10,
	"explosion": 50,
	"ignition": 20,
	"launch": 30,
	"target_hit": 100,
	"target_destroyed": 200,
}

## Chain multiplier thresholds.
const CHAIN_LABELS: Dictionary = {
	3: "NICE!",
	5: "GREAT!",
	8: "AWESOME!",
	12: "CHAOS!",
	18: "MASSIVE CHAIN!",
	25: "PERFECT!",
}

## Events registered this physics frame (for simultaneous tracking).
var _frame_events: int = 0
## Whether chain tracking is active.
var _is_tracking: bool = false


func _ready() -> void:
	GameManager.experiment_started.connect(_on_experiment_started)
	GameManager.state_changed.connect(_on_state_changed)


func _physics_process(_delta: float) -> void:
	if not _is_tracking:
		return

	# Track simultaneous events per frame
	if _frame_events > max_simultaneous:
		max_simultaneous = _frame_events
	_frame_events = 0


## Start tracking a new chain reaction.
func _on_experiment_started() -> void:
	reset()
	_is_tracking = true
	chain_start_time = Time.get_ticks_msec() / 1000.0


## Stop tracking when leaving simulation state.
func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	if new != GameManager.GameState.SIMULATING and _is_tracking:
		_is_tracking = false


## Register a chain event. Called by game objects when they participate in a reaction.
func register_event(event_type: String, source: Node = null, target_node: Node = null) -> void:
	if not _is_tracking:
		return

	chain_count += 1
	_frame_events += 1

	# Calculate score with chain multiplier
	var base_score: int = SCORE_VALUES.get(event_type, 5)
	var multiplier: float = _get_chain_multiplier()
	var event_score: int = int(base_score * multiplier)
	total_score += event_score

	# Track affected objects
	if source and source not in affected_objects:
		affected_objects.append(source)
	if target_node and target_node not in affected_objects:
		affected_objects.append(target_node)

	# Track target hits
	if event_type == "target_hit":
		targets_hit += 1
	elif event_type == "target_destroyed":
		targets_destroyed += 1

	# Create event record
	var event := {
		"type": event_type,
		"chain": chain_count,
		"score": event_score,
		"multiplier": multiplier,
		"time": Time.get_ticks_msec() / 1000.0 - chain_start_time,
		"source": source.name if source else "",
		"target": target_node.name if target_node else "",
	}
	events.append(event)

	chain_event_registered.emit(event)
	chain_updated.emit(chain_count, total_score)


## Get the current chain multiplier.
func _get_chain_multiplier() -> float:
	if chain_count <= 1:
		return 1.0
	elif chain_count <= 3:
		return 1.0 + (chain_count - 1) * 0.25
	elif chain_count <= 8:
		return 1.5 + (chain_count - 3) * 0.3
	elif chain_count <= 15:
		return 3.0 + (chain_count - 8) * 0.4
	else:
		return 5.0 + (chain_count - 15) * 0.5


## Get the label for the current chain count.
func get_chain_label() -> String:
	var label := ""
	for threshold in CHAIN_LABELS:
		if chain_count >= threshold:
			label = CHAIN_LABELS[threshold]
	return label


## Get the final chain result for the results screen.
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


## Reset all tracking data.
func reset() -> void:
	events.clear()
	chain_count = 0
	total_score = 0
	targets_destroyed = 0
	targets_hit = 0
	chain_start_time = 0.0
	max_simultaneous = 0
	affected_objects.clear()
	_frame_events = 0
	_is_tracking = false
