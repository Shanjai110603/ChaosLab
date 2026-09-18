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
## The daily challenge screen.
var daily_screen: Control = null
## The achievements screen.
var achievements_screen: Control = null
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

	# Connect arena and gameplay UI
	if arena and gameplay_ui:
		if gameplay_ui.has_signal("object_spawn_requested") and arena.has_method("spawn_object"):
			gameplay_ui.object_spawn_requested.connect(arena.spawn_object)
		if gameplay_ui.has_signal("level_select_requested"):
			gameplay_ui.level_select_requested.connect(_show_level_select)

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
		if level_select_screen.has_signal("daily_requested"):
			level_select_screen.daily_requested.connect(_show_daily)
		if level_select_screen.has_signal("achievements_requested"):
			level_select_screen.achievements_requested.connect(_show_achievements)

	# Create Shop screen
	var shop_scene := load("res://scenes/ui/ShopScreen.tscn") as PackedScene
	if shop_scene:
		shop_screen = shop_scene.instantiate() as Control
		shop_screen.name = "ShopScreen"
		shop_screen.visible = false
		add_child(shop_screen)
		if shop_screen.has_signal("closed"):
			shop_screen.closed.connect(_on_shop_closed)

	# Create Daily Challenge screen
	var daily_scene := load("res://scenes/ui/DailyChallengeScreen.tscn") as PackedScene
	if daily_scene:
		daily_screen = daily_scene.instantiate() as Control
		daily_screen.name = "DailyChallengeScreen"
		daily_screen.visible = false
		add_child(daily_screen)
		if daily_screen.has_signal("closed"):
			daily_screen.closed.connect(_on_daily_closed)
		if daily_screen.has_signal("start_daily_requested"):
			daily_screen.start_daily_requested.connect(_on_start_daily_requested)

	# Create Achievements screen
	var ach_scene := load("res://scenes/ui/AchievementsScreen.tscn") as PackedScene
	if ach_scene:
		achievements_screen = ach_scene.instantiate() as Control
		achievements_screen.name = "AchievementsScreen"
		achievements_screen.visible = false
		add_child(achievements_screen)
		if achievements_screen.has_signal("closed"):
			achievements_screen.closed.connect(_on_achievements_closed)

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
		if arena.current_level and gameplay_ui and gameplay_ui.object_tray:
			if not arena.current_level.inventory.is_empty():
				gameplay_ui.object_tray.set_inventory(arena.current_level.inventory)
			if gameplay_ui.level_label:
				gameplay_ui.level_label.text = "EXPERIMENT %d: %s" % [arena.current_level.level_id, arena.current_level.title.to_upper()]
			if gameplay_ui.hint_banner and not arena.current_level.description.is_empty():
				gameplay_ui.hint_banner.text = "🎯 Objective: %s" % arena.current_level.description

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


func _show_daily() -> void:
	if daily_screen:
		daily_screen.visible = true
		daily_screen._refresh_display()
	if level_select_screen:
		level_select_screen.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if arena:
		arena.visible = false


func _on_daily_closed() -> void:
	if daily_screen:
		daily_screen.visible = false
	if level_select_screen:
		level_select_screen.visible = true
		level_select_screen._refresh_display()


func _on_start_daily_requested() -> void:
	if daily_screen:
		daily_screen.visible = false
	if arena and get_node_or_null("/root/DailyChallengeManager"):
		var daily_mgr = get_node_or_null("/root/DailyChallengeManager")
		var def = daily_mgr.generate_daily_level_definition()
		arena.visible = true
		arena.load_custom_level(def)
	if gameplay_ui:
		gameplay_ui.visible = true


func _show_achievements() -> void:
	if achievements_screen:
		achievements_screen.visible = true
		achievements_screen._refresh_display()
	if level_select_screen:
		level_select_screen.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if arena:
		arena.visible = false


func _on_achievements_closed() -> void:
	if achievements_screen:
		achievements_screen.visible = false
	if level_select_screen:
		level_select_screen.visible = true
		level_select_screen._refresh_display()


func _on_level_chosen(level_id: int) -> void:
	if level_select_screen:
		level_select_screen.visible = false
	if arena:
		arena.visible = true
		arena._load_level(level_id)
	if gameplay_ui:
		gameplay_ui.visible = true
		if arena and arena.current_level and gameplay_ui.object_tray:
			if not arena.current_level.inventory.is_empty():
				gameplay_ui.object_tray.set_inventory(arena.current_level.inventory)
			if gameplay_ui.level_label:
				gameplay_ui.level_label.text = "EXPERIMENT %d: %s" % [arena.current_level.level_id, arena.current_level.title.to_upper()]
			if gameplay_ui.hint_banner and not arena.current_level.description.is_empty():
				gameplay_ui.hint_banner.text = "🎯 Objective: %s" % arena.current_level.description


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

	# Retention hooks
	var is_success: bool = result.get("success", false)
	if is_success:
		if arena and arena.current_level and arena.current_level.level_id == 990:
			if get_node_or_null("/root/DailyChallengeManager"):
				get_node_or_null("/root/DailyChallengeManager").record_daily_completed()

		if get_node_or_null("/root/AchievementManager"):
			var ach_mgr = get_node_or_null("/root/AchievementManager")
			ach_mgr.add_progress("FIRST_SPARK", 1)
			if result.get("duration", 99.0) <= 5.0:
				ach_mgr.add_progress("SPEED_DEMON", 1)
			if result.get("par_bonus", 0) > 0:
				ach_mgr.add_progress("PAR_PERFECTIONIST", 1)
			if SaveManager.get_world_stars(1) >= 30:
				ach_mgr.add_progress("WORLD_MASTER", 30)


func _on_chain_updated(chain_count: int, total_score: int) -> void:
	if gameplay_ui and gameplay_ui.has_method("update_chain"):
		var label: String = ""
		if arena and arena.experiment_controller:
			label = arena.experiment_controller.chain_manager.get_chain_label()
		gameplay_ui.update_chain(chain_count, total_score, label)

	if get_node_or_null("/root/AchievementManager"):
		var ach_mgr = get_node_or_null("/root/AchievementManager")
		if chain_count >= 5:
			ach_mgr.add_progress("CHAIN_PRO", 5)
		if chain_count >= 8:
			ach_mgr.add_progress("CHAIN_GOD", 8)


func _on_chain_event(event: Dictionary) -> void:
	var event_type: String = event.get("type", "")
	match event_type:
		"explosion":
			CameraShake.shake(0.8)
			if get_node_or_null("/root/AchievementManager"):
				get_node_or_null("/root/AchievementManager").add_progress("PYROMANIAC", 1)
		"collision":
			CameraShake.shake(0.2)
		"launch":
			CameraShake.shake(0.35)
		"teleport":
			if get_node_or_null("/root/AchievementManager"):
				get_node_or_null("/root/AchievementManager").add_progress("PORTAL_TRAVELER", 1)


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
