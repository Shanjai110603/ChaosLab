## Debug overlay and development tools.
## Autoload singleton — toggled with F1, hidden in release builds.
class_name DebugManagerClass
extends CanvasLayer

## Whether the debug overlay is currently visible.
var overlay_visible: bool = false

## Debug label for FPS, state, object count.
var _debug_label: Label = null
## Container for debug controls.
var _debug_panel: PanelContainer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100  # Always on top

	if not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		print("[DebugManager] Release build — debug tools disabled")
		return

	_create_overlay()
	_hide_overlay()
	print("[DebugManager] Initialized (F1 to toggle)")


func _process(_delta: float) -> void:
	if overlay_visible and _debug_label:
		_update_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event.is_action_pressed("debug_toggle"):
		toggle_overlay()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("debug_skip_level"):
		if GameManager.current_state == GameManager.GameState.PLACING or \
		   GameManager.current_state == GameManager.GameState.SIMULATING:
			GameManager.complete_level(0, 0, 1)
			print("[Debug] Level skipped")
		get_viewport().set_input_as_handled()


## Toggle the debug overlay visibility.
func toggle_overlay() -> void:
	if overlay_visible:
		_hide_overlay()
	else:
		_show_overlay()


func _show_overlay() -> void:
	overlay_visible = true
	if _debug_panel:
		_debug_panel.visible = true


func _hide_overlay() -> void:
	overlay_visible = false
	if _debug_panel:
		_debug_panel.visible = false


## Create the debug overlay UI.
func _create_overlay() -> void:
	# Panel container
	_debug_panel = PanelContainer.new()
	_debug_panel.name = "DebugPanel"
	_debug_panel.custom_minimum_size = Vector2(320, 0)

	# Style the panel with semi-transparent background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_debug_panel.add_theme_stylebox_override("panel", style)

	# Position top-right
	_debug_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_debug_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# VBox for layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Title
	var title := Label.new()
	title.text = "DEBUG (F1)"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title)

	# Info label
	_debug_label = Label.new()
	_debug_label.text = "Loading..."
	_debug_label.add_theme_font_size_override("font_size", 12)
	_debug_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_debug_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Debug buttons
	_add_debug_button(vbox, "Skip Level (F2)", _on_skip_level)
	_add_debug_button(vbox, "Trigger GO", _on_trigger_go)
	_add_debug_button(vbox, "Reset Level", _on_reset_level)
	_add_debug_button(vbox, "Add 1000 Coins", _on_add_coins)
	_add_debug_button(vbox, "Clear Save", _on_clear_save)

	_debug_panel.add_child(vbox)
	add_child(_debug_panel)


func _add_debug_button(parent: Control, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size.y = 28
	parent.add_child(btn)


## Update the debug info text.
func _update_overlay() -> void:
	var fps := Engine.get_frames_per_second()
	var state_name: String = GameManager.GameState.keys()[GameManager.current_state]
	var level_id: int = GameManager.current_level_id
	var coins: int = SaveManager.get_coins()

	# Count physics objects in scene
	var object_count: int = 0
	var tree := get_tree()
	if tree and tree.current_scene:
		object_count = tree.current_scene.get_tree().get_nodes_in_group("game_objects").size()

	var paused_str: String = " [PAUSED]" if get_tree().paused else ""

	_debug_label.text = "FPS: %d%s\nState: %s\nLevel: %d\nObjects: %d\nCoins: %d\nPlatform: %s" % [
		fps, paused_str, state_name, level_id, object_count, coins,
		PlatformService.get_platform_name()
	]


# Debug button callbacks
func _on_skip_level() -> void:
	GameManager.complete_level(0, 0, 1)

func _on_trigger_go() -> void:
	GameManager.trigger_go()

func _on_reset_level() -> void:
	GameManager.trigger_reset()

func _on_add_coins() -> void:
	SaveManager.add_coins(1000)
	print("[Debug] Added 1000 coins. Total: ", SaveManager.get_coins())

func _on_clear_save() -> void:
	SaveManager.clear_save()
	print("[Debug] Save data cleared")
