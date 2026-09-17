## Central game state machine and flow controller.
## Autoload singleton — manages transitions between game states.
class_name GameManagerClass
extends Node

## Emitted when the game state changes. Passes old and new state.
signal state_changed(old_state: GameState, new_state: GameState)
## Emitted when a level starts loading.
signal level_started(level_id: int)
## Emitted when a level is completed successfully.
signal level_completed(level_id: int, score: int, chain: int, stars: int)
## Emitted when a level attempt fails.
signal level_failed(level_id: int)
## Emitted when the experiment is triggered (GO pressed).
signal experiment_started()
## Emitted when the experiment ends (all objects settled or timeout).
signal experiment_ended()

## All possible game states.
enum GameState {
	MENU,       ## Main menu / world select
	LOADING,    ## Level is being loaded
	PLACING,    ## Player is placing/dragging objects
	SIMULATING, ## Physics simulation is running
	RESULT,     ## Level result screen
	PAUSED,     ## Game is paused
}

## The current game state.
var current_state: GameState = GameState.MENU
## The state before pausing (restored on unpause).
var _state_before_pause: GameState = GameState.MENU

## Currently loaded level ID.
var current_level_id: int = -1
## Current world index (0-based).
var current_world: int = 0

## Whether this is a debug/development build.
var is_debug: bool = false


func _ready() -> void:
	is_debug = OS.is_debug_build()
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] Initialized. Debug: ", is_debug)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == GameState.PAUSED:
			unpause()
		elif current_state == GameState.PLACING or current_state == GameState.SIMULATING:
			pause()
		get_viewport().set_input_as_handled()


## Transition to a new game state. Validates the transition.
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	var old_state := current_state
	current_state = new_state
	print("[GameManager] State: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])
	state_changed.emit(old_state, new_state)


## Start loading a level by ID.
func start_level(level_id: int) -> void:
	current_level_id = level_id
	change_state(GameState.LOADING)
	level_started.emit(level_id)
	# After loading, transition to PLACING
	change_state(GameState.PLACING)


## Trigger the experiment (GO).
func trigger_go() -> void:
	if current_state != GameState.PLACING:
		return
	change_state(GameState.SIMULATING)
	experiment_started.emit()


## Reset the current experiment to initial state.
func trigger_reset() -> void:
	if current_state == GameState.SIMULATING or current_state == GameState.PLACING:
		change_state(GameState.PLACING)


## Complete the current level.
func complete_level(score: int, chain: int, stars: int) -> void:
	change_state(GameState.RESULT)
	level_completed.emit(current_level_id, score, chain, stars)


## Fail the current level.
func fail_level() -> void:
	change_state(GameState.RESULT)
	level_failed.emit(current_level_id)


## Pause the game.
func pause() -> void:
	if current_state == GameState.PAUSED:
		return
	_state_before_pause = current_state
	change_state(GameState.PAUSED)
	get_tree().paused = true


## Unpause the game.
func unpause() -> void:
	if current_state != GameState.PAUSED:
		return
	get_tree().paused = false
	change_state(_state_before_pause)


## Go to the next level.
func next_level() -> void:
	start_level(current_level_id + 1)


## Retry the current level.
func retry_level() -> void:
	start_level(current_level_id)


## Return to main menu.
func go_to_menu() -> void:
	get_tree().paused = false
	change_state(GameState.MENU)
