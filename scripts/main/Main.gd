## Main — root scene for Chaos Lab.
## Manages screen transitions between Gameplay, Level Select, and Overlays.
class_name MainClass
extends Node2D

## The arena instance.
var arena: Node2D = null
## The gameplay UI.
var gameplay_ui: CanvasLayer = null
## The pause menu.
var pause_menu: CanvasLayer = null
## The result screen.
var result_screen: CanvasLayer = null
## The level select screen.
var level_select_screen: Control = null
## The shop screen.
var shop_screen: Control = null
## Camera.
var camera: Camera2D = null
## Camera shake component.
var camera_shake: CameraShake = null


func _ready() -> void:
	# Set background color
	RenderingServer.set_default_clear_color(Color(0.04, 0.06, 0.09))

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

	# Create Level Select screen
	var level_select_scene := load("res://scenes/ui/LevelSelectScreen.tscn") as PackedScene
	if level_select_scene:
		level_select_screen = level_select_scene.instantiate() as Control
		level_select_screen.name = "LevelSelectScreen"
		level_select_screen.visible = false
		add_child(level_select_screen)
		level_select_screen.level_chosen.connect(_on_level_chosen)
		level_select_screen.back_to_menu_requested.connect(_on_level_select_back)
		if level_select_screen.has_signal("shop_requested"):
			level_select_screen.shop_requested.connect(_show_shop)

	# Create Shop screen
	var shop_scene := load("res://scenes/ui/ShopScreen.tscn") as PackedScene
	if shop_scene:
		shop_screen = shop_scene.instantiate() as Control
		shop_screen.name = "ShopScreen"
		shop_screen.visible = false
		add_child(shop_screen)
		if shop_screen.has_signal("closed"):
			shop_screen.closed.connect(_on_shop_closed)

	# Create ScreenVignette for chromatic impact flashes
	var vignette := ScreenVignette.new()
	vignette.name = "ScreenVignette"
	add_child(vignette)

	# Connect result screen signals
	if result_screen:
		if result_screen.has_signal("level_select_requested"):
			result_screen.level_select_requested.connect(_show_level_select)

	# Connect experiment result to result screen
	await get_tree().process_frame
	if arena and arena.experiment_controller:
		arena.experiment_controller.experiment_result.connect(_on_experiment_result)
		arena.experiment_controller.chain_manager.chain_updated.connect(_on_chain_updated)
		arena.experiment_controller.chain_manager.chain_event_registered.connect(_on_chain_event)
		gameplay_ui.experiment_controller = arena.experiment_controller

	print("[Main] Chaos Lab initialized with 20 Campaign levels & Level Select!")


func _show_level_select() -> void:
	if level_select_screen:
		level_select_screen.visible = true
		level_select_screen._refresh_display()
	if gameplay_ui:
		gameplay_ui.visible = false
	if arena:
		arena.visible = false
	if shop_screen:
		shop_screen.visible = false


func _show_shop() -> void:
	if shop_screen:
		shop_screen.visible = true
		shop_screen._refresh_display()
	if level_select_screen:
		level_select_screen.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if arena:
		arena.visible = false


func _on_shop_closed() -> void:
	if shop_screen:
		shop_screen.visible = false
	if level_select_screen:
		level_select_screen.visible = true
		level_select_screen._refresh_display()
	elif gameplay_ui:
		gameplay_ui.visible = true
		if arena:
			arena.visible = true


func _on_level_chosen(level_id: int) -> void:
	if level_select_screen:
		level_select_screen.visible = false
	if arena:
		arena.visible = true
		arena._load_level(level_id)
	if gameplay_ui:
		gameplay_ui.visible = true


func _on_level_select_back() -> void:
	if level_select_screen:
		level_select_screen.visible = false
	if arena:
		arena.visible = true
	if gameplay_ui:
		gameplay_ui.visible = true


func _on_experiment_result(result: Dictionary) -> void:
	if result_screen and result_screen.has_method("show_result"):
		result_screen.show_result(result)


func _on_chain_updated(chain_count: int, total_score: int) -> void:
	if gameplay_ui and gameplay_ui.has_method("update_chain"):
		var label: String = ""
		if arena and arena.experiment_controller:
			label = arena.experiment_controller.chain_manager.get_chain_label()
		gameplay_ui.update_chain(chain_count, total_score, label)


func _on_chain_event(event: Dictionary) -> void:
	var event_type: String = event.get("type", "")
	match event_type:
		"explosion":
			CameraShake.shake(0.8)
		"collision":
			CameraShake.shake(0.2)
		"launch":
			CameraShake.shake(0.35)


func _physics_process(delta: float) -> void:
	if not camera:
		return

	var default_cam_pos := Vector2(960, 540)
	if GameManager.current_state == GameManager.GameState.SIMULATING and arena and arena.objects_container:
		var total_pos := Vector2.ZERO
		var active_count := 0
		for child in arena.objects_container.get_children():
			if child is RigidBody2D and not child.freeze and child.visible:
				if child.linear_velocity.length() > 30.0:
					total_pos += child.global_position
					active_count += 1

		if active_count > 0:
			var target_pos := total_pos / float(active_count)
			target_pos.x = clampf(target_pos.x, 760.0, 1160.0)
			target_pos.y = clampf(target_pos.y, 440.0, 640.0)
			camera.position = camera.position.lerp(target_pos, delta * 3.5)
		else:
			camera.position = camera.position.lerp(default_cam_pos, delta * 2.0)
	else:
		camera.position = camera.position.lerp(default_cam_pos, delta * 4.0)
