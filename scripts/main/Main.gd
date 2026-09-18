## Main — Root scene and primary coordinator for Chaos Lab.
## Manages seamless screen transitions between Main Menu, Level Select, The Lab Hub,
## Chaos Mode, Daily Challenges, Shop, Achievements, Settings, and Gameplay Arena.
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

## Screen Overlays inside ScreensLayer
var screens_layer: CanvasLayer = null
var main_menu_screen: Control = null
var level_select_screen: Control = null
var lab_hub_screen: Control = null
var chaos_mode_screen: Control = null
var shop_screen: Control = null
var daily_screen: Control = null
var achievements_screen: Control = null
var settings_screen: Control = null

## Camera & Shake.
var camera: Camera2D = null
var camera_shake: CameraShake = null


func _ready() -> void:
	# Set background clear color
	RenderingServer.set_default_clear_color(Color(0.03, 0.05, 0.09))

	# 1. Create camera
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2.ONE
	add_child(camera)
	camera.make_current()

	camera_shake = CameraShake.new()
	camera_shake.name = "CameraShake"
	camera.add_child(camera_shake)

	# 2. Create arena
	var arena_script := load("res://scripts/gameplay/Arena.gd")
	arena = Node2D.new()
	arena.name = "Arena"
	arena.set_script(arena_script)
	add_child(arena)
	arena.visible = false

	# 3. Create gameplay UI
	var ui_script := load("res://scripts/ui/GameplayUI.gd")
	gameplay_ui = CanvasLayer.new()
	gameplay_ui.name = "GameplayUI"
	gameplay_ui.set_script(ui_script)
	add_child(gameplay_ui)
	gameplay_ui.visible = false

	# Connect gameplay UI signals
	if gameplay_ui.has_signal("object_spawn_requested") and arena.has_method("spawn_object"):
		gameplay_ui.object_spawn_requested.connect(arena.spawn_object)
	if gameplay_ui.has_signal("level_select_requested"):
		gameplay_ui.level_select_requested.connect(_show_level_select)
	if gameplay_ui.has_signal("main_menu_requested"):
		gameplay_ui.main_menu_requested.connect(_show_main_menu)

	# 4. Create pause menu
	var pause_script := load("res://scripts/ui/PauseMenu.gd")
	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_script(pause_script)
	add_child(pause_menu)

	# 5. Create result screen
	var result_script := load("res://scripts/ui/ResultScreen.gd")
	result_screen = CanvasLayer.new()
	result_screen.name = "ResultScreen"
	result_screen.set_script(result_script)
	add_child(result_screen)

	if result_screen:
		if result_screen.has_signal("level_select_requested"):
			result_screen.level_select_requested.connect(_show_level_select)
		if result_screen.has_signal("retry_requested"):
			result_screen.retry_requested.connect(_on_retry_requested)
		if result_screen.has_signal("next_requested"):
			result_screen.next_requested.connect(_on_next_requested)

	# 6. Create ScreenVignette for chromatic impact flashes
	var vignette := ScreenVignette.new()
	vignette.name = "ScreenVignette"
	add_child(vignette)

	# 7. Create ScreensLayer for full-screen UI overlays (Layer 25)
	screens_layer = CanvasLayer.new()
	screens_layer.name = "ScreensLayer"
	screens_layer.layer = 25
	add_child(screens_layer)

	_instantiate_screens()

	# Connect experiment controller
	await get_tree().process_frame
	if arena and arena.experiment_controller:
		arena.experiment_controller.experiment_result.connect(_on_experiment_result)
		arena.experiment_controller.chain_manager.chain_updated.connect(_on_chain_updated)
		arena.experiment_controller.chain_manager.chain_event_registered.connect(_on_chain_event)
		gameplay_ui.experiment_controller = arena.experiment_controller

	# Start on Main Menu
	_show_main_menu()
	print("[Main] Chaos Lab Full Version Initialized Successfully!")


func _instantiate_screens() -> void:
	# Main Menu
	var menu_scene := load("res://scenes/ui/MainMenuScreen.tscn") as PackedScene
	if menu_scene:
		main_menu_screen = menu_scene.instantiate() as Control
		main_menu_screen.name = "MainMenuScreen"
		screens_layer.add_child(main_menu_screen)
		main_menu_screen.play_campaign_requested.connect(_show_level_select)
		main_menu_screen.chaos_mode_requested.connect(_show_chaos_mode)
		main_menu_screen.daily_requested.connect(_show_daily)
		main_menu_screen.lab_hub_requested.connect(_show_lab_hub)
		main_menu_screen.shop_requested.connect(_show_shop)
		main_menu_screen.achievements_requested.connect(_show_achievements)
		main_menu_screen.settings_requested.connect(_show_settings)
		main_menu_screen.exit_requested.connect(func(): get_tree().quit())

	# Level Select
	var level_select_scene := load("res://scenes/ui/LevelSelectScreen.tscn") as PackedScene
	if level_select_scene:
		level_select_screen = level_select_scene.instantiate() as Control
		level_select_screen.name = "LevelSelectScreen"
		level_select_screen.visible = false
		screens_layer.add_child(level_select_screen)
		level_select_screen.level_chosen.connect(_on_level_chosen)
		level_select_screen.back_to_menu_requested.connect(_show_main_menu)
		level_select_screen.shop_requested.connect(_show_shop)
		level_select_screen.daily_requested.connect(_show_daily)
		level_select_screen.achievements_requested.connect(_show_achievements)

	# The Lab Hub
	var hub_scene := load("res://scenes/ui/LabHubScreen.tscn") as PackedScene
	if hub_scene:
		lab_hub_screen = hub_scene.instantiate() as Control
		lab_hub_screen.name = "LabHubScreen"
		lab_hub_screen.visible = false
		screens_layer.add_child(lab_hub_screen)
		lab_hub_screen.closed.connect(_show_main_menu)

	# Chaos Mode
	var chaos_scene := load("res://scenes/ui/ChaosModeScreen.tscn") as PackedScene
	if chaos_scene:
		chaos_mode_screen = chaos_scene.instantiate() as Control
		chaos_mode_screen.name = "ChaosModeScreen"
		chaos_mode_screen.visible = false
		screens_layer.add_child(chaos_mode_screen)
		chaos_mode_screen.closed.connect(_show_main_menu)
		chaos_mode_screen.start_chaos_requested.connect(_on_start_chaos_requested)

	# Shop Screen
	var shop_scene := load("res://scenes/ui/ShopScreen.tscn") as PackedScene
	if shop_scene:
		shop_screen = shop_scene.instantiate() as Control
		shop_screen.name = "ShopScreen"
		shop_screen.visible = false
		screens_layer.add_child(shop_screen)
		shop_screen.closed.connect(_show_main_menu)

	# Daily Challenge Screen
	var daily_scene := load("res://scenes/ui/DailyChallengeScreen.tscn") as PackedScene
	if daily_scene:
		daily_screen = daily_scene.instantiate() as Control
		daily_screen.name = "DailyChallengeScreen"
		daily_screen.visible = false
		screens_layer.add_child(daily_screen)
		daily_screen.closed.connect(_show_main_menu)
		daily_screen.start_daily_requested.connect(_on_start_daily_requested)

	# Achievements Screen
	var ach_scene := load("res://scenes/ui/AchievementsScreen.tscn") as PackedScene
	if ach_scene:
		achievements_screen = ach_scene.instantiate() as Control
		achievements_screen.name = "AchievementsScreen"
		achievements_screen.visible = false
		screens_layer.add_child(achievements_screen)
		achievements_screen.closed.connect(_show_main_menu)

	# Settings Screen
	var set_scene := load("res://scenes/ui/SettingsScreen.tscn") as PackedScene
	if set_scene:
		settings_screen = set_scene.instantiate() as Control
		settings_screen.name = "SettingsScreen"
		settings_screen.visible = false
		screens_layer.add_child(settings_screen)
		settings_screen.closed.connect(_show_main_menu)


func _hide_all_screens() -> void:
	if main_menu_screen:
		main_menu_screen.visible = false
	if level_select_screen:
		level_select_screen.visible = false
	if lab_hub_screen:
		lab_hub_screen.visible = false
	if chaos_mode_screen:
		chaos_mode_screen.visible = false
	if shop_screen:
		shop_screen.visible = false
	if daily_screen:
		daily_screen.visible = false
	if achievements_screen:
		achievements_screen.visible = false
	if settings_screen:
		settings_screen.visible = false
	if result_screen:
		result_screen.visible = false


func _show_main_menu() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if main_menu_screen:
		main_menu_screen.visible = true
		if main_menu_screen.has_method("_refresh_data"):
			main_menu_screen._refresh_data()
	GameManager.go_to_menu()


func _show_level_select() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if level_select_screen:
		level_select_screen.visible = true
		level_select_screen._refresh_display()


func _show_lab_hub() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if lab_hub_screen:
		lab_hub_screen.visible = true
		lab_hub_screen._refresh_display()


func _show_chaos_mode() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if chaos_mode_screen:
		chaos_mode_screen.visible = true
		chaos_mode_screen._generate_next()


func _show_shop() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if shop_screen:
		shop_screen.visible = true
		shop_screen._refresh_display()


func _show_daily() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if daily_screen:
		daily_screen.visible = true
		daily_screen._refresh_display()


func _show_achievements() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if achievements_screen:
		achievements_screen.visible = true
		achievements_screen._refresh_display()


func _show_settings() -> void:
	_hide_all_screens()
	if arena:
		arena.visible = false
	if gameplay_ui:
		gameplay_ui.visible = false
	if settings_screen:
		settings_screen.visible = true
		settings_screen._load_settings()


func _on_level_chosen(level_id: int) -> void:
	_hide_all_screens()
	if arena:
		arena.visible = true
		arena._load_level(level_id)
	if gameplay_ui:
		gameplay_ui.visible = true
		_sync_gameplay_ui_to_level()


func _on_start_chaos_requested(level_def: Dictionary) -> void:
	_hide_all_screens()
	if arena:
		arena.visible = true
		arena.load_custom_level(level_def)
	if gameplay_ui:
		gameplay_ui.visible = true
		_sync_gameplay_ui_to_level()


func _on_start_daily_requested() -> void:
	_hide_all_screens()
	if arena and get_node_or_null("/root/DailyChallengeManager"):
		var daily_mgr = get_node_or_null("/root/DailyChallengeManager")
		var def: Dictionary = daily_mgr.generate_daily_level_definition()
		arena.visible = true
		arena.load_custom_level(def)
	if gameplay_ui:
		gameplay_ui.visible = true
		_sync_gameplay_ui_to_level()


func _sync_gameplay_ui_to_level() -> void:
	if arena and arena.current_level and gameplay_ui:
		if gameplay_ui.object_tray and not arena.current_level.inventory.is_empty():
			gameplay_ui.object_tray.set_inventory(arena.current_level.inventory)
		if gameplay_ui.level_label:
			gameplay_ui.level_label.text = "EXPERIMENT %d: %s" % [arena.current_level.level_id, arena.current_level.title.to_upper()]
		if gameplay_ui.hint_banner and not arena.current_level.description.is_empty():
			gameplay_ui.hint_banner.text = "🎯 Objective: %s" % arena.current_level.description
		if gameplay_ui.has_method("greet_level"):
			gameplay_ui.greet_level(arena.current_level.level_id, arena.current_level.title, arena.current_level.description)


func _on_retry_requested() -> void:
	if result_screen:
		result_screen.visible = false
	if arena:
		arena.visible = true
	if gameplay_ui:
		gameplay_ui.visible = true
	GameManager.trigger_reset()


func _on_next_requested() -> void:
	if result_screen:
		result_screen.visible = false
	var next_id: int = GameManager.current_level_id + 1
	if next_id <= 100:
		_on_level_chosen(next_id)
	else:
		_show_level_select()


func _on_experiment_result(result: Dictionary) -> void:
	if result_screen and result_screen.has_method("show_result"):
		result_screen.show_result(result)

	var is_success: bool = result.get("success", false)
	var stars: int = result.get("stars", 0)

	if gameplay_ui and gameplay_ui.nix_companion:
		gameplay_ui.nix_companion.react_to_result(is_success, stars)

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
