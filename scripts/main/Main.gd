## Main — root scene for Chaos Lab.
## Manages screen transitions and instantiates Arena + UI layers.
extends Node2D

## The arena instance.
var arena: Node2D = null
## The gameplay UI.
var gameplay_ui: CanvasLayer = null
## The pause menu.
var pause_menu: CanvasLayer = null
## The result screen.
var result_screen: CanvasLayer = null
## Camera.
var camera: Camera2D = null
## Camera shake component.
var camera_shake: CameraShake = null


func _ready() -> void:
	# Set background color
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))

	# Create camera
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.position = Vector2(960, 540)  # Center of 1920×1080
	camera.zoom = Vector2.ONE
	add_child(camera)
	camera.make_current()

	# Camera shake
	camera_shake = CameraShake.new()
	camera_shake.name = "CameraShake"
	camera.add_child(camera_shake)

	# Create arena
	var arena_script := load("res://scripts/gameplay/Arena.gd")
	arena = Node2D.new()
	arena.name = "Arena"
	arena.set_script(arena_script)
	add_child(arena)

	# Create gameplay UI
	var ui_script := load("res://scripts/ui/GameplayUI.gd")
	gameplay_ui = CanvasLayer.new()
	gameplay_ui.name = "GameplayUI"
	gameplay_ui.set_script(ui_script)
	add_child(gameplay_ui)

	# Create pause menu
	var pause_script := load("res://scripts/ui/PauseMenu.gd")
	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_script(pause_script)
	add_child(pause_menu)

	# Create result screen
	var result_script := load("res://scripts/ui/ResultScreen.gd")
	result_screen = CanvasLayer.new()
	result_screen.name = "ResultScreen"
	result_screen.set_script(result_script)
	add_child(result_screen)

	# Connect experiment result to result screen
	await get_tree().process_frame  # Wait for arena to initialize
	if arena and arena.experiment_controller:
		arena.experiment_controller.experiment_result.connect(_on_experiment_result)
		# Connect chain updates to gameplay UI
		arena.experiment_controller.chain_manager.chain_updated.connect(_on_chain_updated)
		arena.experiment_controller.chain_manager.chain_event_registered.connect(_on_chain_event)
		# Give UI a reference to experiment controller
		gameplay_ui.experiment_controller = arena.experiment_controller

	print("[Main] Chaos Lab initialized!")
	print("[Main] Controls: SPACE=GO, R=RESET, Z=UNDO, ESC=PAUSE, F1=DEBUG")


## Handle experiment result — show result screen.
func _on_experiment_result(result: Dictionary) -> void:
	if result_screen and result_screen.has_method("show_result"):
		result_screen.show_result(result)


## Handle chain updates — update HUD.
func _on_chain_updated(chain_count: int, total_score: int) -> void:
	if gameplay_ui and gameplay_ui.has_method("update_chain"):
		var label: String = ""
		if arena and arena.experiment_controller:
			label = arena.experiment_controller.chain_manager.get_chain_label()
		gameplay_ui.update_chain(chain_count, total_score, label)


## Handle chain events — trigger VFX and camera shake.
func _on_chain_event(event: Dictionary) -> void:
	var event_type: String = event.get("type", "")
	match event_type:
		"explosion":
			if camera_shake:
				camera_shake.shake(8.0, 4.0)
			# Spawn explosion VFX at the source position
			# (In a future iteration, we'll get the position from the event)
		"collision":
			if camera_shake:
				camera_shake.shake(2.0, 8.0)
		"launch":
			if camera_shake:
				camera_shake.shake(3.0, 6.0)
