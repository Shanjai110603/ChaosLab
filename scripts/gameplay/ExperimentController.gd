## Experiment Controller.
## Manages the experiment lifecycle: setup → running → evaluating → complete.
## Controls GO, RESET, UNDO flow and level completion detection.
class_name ExperimentController
extends Node

## Emitted when the experiment result is ready.
signal experiment_result(result: Dictionary)

## Reference to the ChainReactionManager.
var chain_manager: ChainReactionManager = null
## All game objects in the current level.
var game_objects: Array[GameObject] = []
## All targets in the current level.
var targets: Array[TargetObject] = []

## Level definition data.
var level_data: Dictionary = {}
## Total number of targets in the level.
var total_targets: int = 0
## Score targets for star rating [1-star, 2-star, 3-star].
var score_targets: Array = [100, 300, 600]

## Timeout for experiment simulation (seconds).
@export var simulation_timeout: float = 15.0
## Time elapsed during simulation.
var _simulation_time: float = 0.0
## Whether we're checking for settlement (all objects at rest).
var _checking_settlement: bool = false
## Time since all objects appeared settled.
var _settlement_time: float = 0.0
## Time required for objects to be at rest before declaring settled.
const SETTLEMENT_THRESHOLD: float = 1.5


func _ready() -> void:
	# Create chain reaction manager as child
	chain_manager = ChainReactionManager.new()
	chain_manager.name = "ChainReactionManager"
	add_child(chain_manager)

	# Connect to game state
	GameManager.experiment_started.connect(_on_go)
	GameManager.state_changed.connect(_on_state_changed)


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	_simulation_time += delta

	# Check for timeout
	if _simulation_time >= simulation_timeout:
		_end_experiment()
		return

	# Check if all targets are hit
	var all_targets_hit := true
	for target in targets:
		if not target.is_hit:
			all_targets_hit = false
			break

	if all_targets_hit and targets.size() > 0:
		# All targets hit — wait a moment for additional chain events
		_settlement_time += delta
		if _settlement_time > 0.5:  # Brief delay for chain continuation
			_end_experiment()
		return

	# Check if all objects have settled (stopped moving)
	var all_settled := true
	for obj in game_objects:
		if obj is RigidBody2D and not obj.freeze:
			if obj.linear_velocity.length() > 5.0 or abs(obj.angular_velocity) > 0.5:
				all_settled = false
				break

	if all_settled and _simulation_time > 0.5:
		_settlement_time += delta
		if _settlement_time >= SETTLEMENT_THRESHOLD:
			_end_experiment()
	else:
		_settlement_time = 0.0


## Called when GO is pressed.
func _on_go() -> void:
	_simulation_time = 0.0
	_settlement_time = 0.0
	_checking_settlement = false


## Handle state changes.
func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	if new == GameManager.GameState.PLACING:
		_reset_experiment()


## Setup the experiment with level data.
func setup_level(data: Dictionary, objects: Array[GameObject], level_targets: Array[TargetObject]) -> void:
	level_data = data
	game_objects = objects
	targets = level_targets
	total_targets = targets.size()
	score_targets = data.get("score_targets", [100, 300, 600])

	# Connect chain events from all objects
	for obj in game_objects:
		if not obj.chain_event.is_connected(_on_chain_event):
			obj.chain_event.connect(_on_chain_event.bind(obj))

	# Connect target signals
	for target in targets:
		if not target.target_hit.is_connected(_on_target_hit):
			target.target_hit.connect(_on_target_hit)
		if not target.target_destroyed.is_connected(_on_target_destroyed):
			target.target_destroyed.connect(_on_target_destroyed)


## Handle chain event from a game object.
func _on_chain_event(event_type: String, other: Node2D, source: Node) -> void:
	chain_manager.register_event(event_type, source, other)


## Handle target hit.
func _on_target_hit(target: TargetObject) -> void:
	chain_manager.register_event("target_hit", target, null)


## Handle target destroyed.
func _on_target_destroyed(target: TargetObject) -> void:
	chain_manager.register_event("target_destroyed", target, null)


## End the experiment and evaluate results.
func _end_experiment() -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	var chain_result := chain_manager.get_result()
	
	# Calculate unused items for par efficiency bonus
	var unused_items := 0
	if is_inside_tree():
		var ui := get_tree().root.find_child("GameplayUI", true, false)
		if ui and ui.object_tray:
			for item in ui.object_tray.inventory.keys():
				var cnt: int = ui.object_tray.inventory[item]
				if cnt > 0:
					unused_items += cnt

	var result := ScoreSystem.evaluate_level(chain_result, total_targets, score_targets, unused_items)

	# Save result if completed
	if result["complete"]:
		SaveManager.save_level_result(
			GameManager.current_level_id,
			result["score"],
			result["chain"],
			result["stars"]
		)
		SaveManager.add_coins(result["coins"])
		GameManager.complete_level(result["score"], result["chain"], result["stars"])
	else:
		GameManager.fail_level()

	experiment_result.emit(result)


## Register a newly spawned game object.
func register_object(obj: GameObject) -> void:
	if obj not in game_objects:
		game_objects.append(obj)
		if not obj.chain_event.is_connected(_on_chain_event):
			obj.chain_event.connect(_on_chain_event.bind(obj))


## Reset the experiment for a fresh attempt.
func _reset_experiment() -> void:
	_simulation_time = 0.0
	_settlement_time = 0.0
	chain_manager.reset()

	# Restore all objects to their pre-GO placement snapshot
	for obj in game_objects:
		if obj.has_method("restore_sim_snapshot"):
			obj.restore_sim_snapshot()
		else:
			obj.reset_to_initial()

	# Reset all targets
	for target in targets:
		target.reset()


## Undo the last placement.
func undo_last() -> void:
	if GameManager.current_state != GameManager.GameState.PLACING:
		return

	# Find the most recently moved object and undo its position
	# For simplicity, we try to undo all objects' last state
	for obj in game_objects:
		obj.pop_undo_state()
