## Pause Menu — overlay shown when the game is paused.
extends CanvasLayer

var _panel: PanelContainer = null


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false

	GameManager.state_changed.connect(_on_state_changed)


func _create_ui() -> void:
	# Dark overlay
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(320, 350)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.5)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	vbox.add_child(HSeparator.new())

	# Resume button
	var resume_btn := _make_button("RESUME", Color(0.2, 0.7, 0.3))
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	# Restart button
	var restart_btn := _make_button("RESTART", Color(0.8, 0.5, 0.2))
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

	# Quit button
	var quit_btn := _make_button("QUIT", Color(0.7, 0.2, 0.2))
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 48)

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)

	return btn


func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	visible = (new == GameManager.GameState.PAUSED)


func _on_resume() -> void:
	GameManager.unpause()

func _on_restart() -> void:
	GameManager.unpause()
	GameManager.retry_level()

func _on_quit() -> void:
	GameManager.unpause()
	GameManager.go_to_menu()
