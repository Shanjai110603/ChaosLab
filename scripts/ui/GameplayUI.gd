## Gameplay UI — HUD for the experiment.
## GO, RESET, UNDO buttons + level info + chain counter.
extends CanvasLayer

## Chain count label.
var chain_label: Label = null
## Chain multiplier label.
var chain_mult_label: Label = null
## Score label.
var score_label: Label = null
## Level label.
var level_label: Label = null
## State indicator.
var state_label: Label = null
## GO button.
var go_button: Button = null
## Reset button.
var reset_button: Button = null
## Undo button.
var undo_button: Button = null
## Pause button.
var pause_button: Button = null

## Reference to experiment controller (set by Main).
var experiment_controller: ExperimentController = null

## Button style colors.
const COLOR_GO := Color(0.2, 0.8, 0.3)
const COLOR_GO_HOVER := Color(0.25, 0.9, 0.35)
const COLOR_RESET := Color(0.8, 0.5, 0.2)
const COLOR_UNDO := Color(0.5, 0.5, 0.6)
const COLOR_PAUSE := Color(0.4, 0.4, 0.5)
const COLOR_BTN_TEXT := Color.WHITE


func _ready() -> void:
	layer = 10
	_create_ui()

	# Connect to game manager signals
	GameManager.state_changed.connect(_on_state_changed)

	# Update initial state
	_update_for_state(GameManager.current_state)


func _create_ui() -> void:
	var root := Control.new()
	root.name = "UIRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ---- TOP BAR ----
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 60
	top_bar.add_theme_constant_override("separation", 20)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER

	# Top bar background
	var top_bg := PanelContainer.new()
	top_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size.y = 60
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	top_style.content_margin_left = 20
	top_style.content_margin_right = 20
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_bg.add_theme_stylebox_override("panel", top_style)
	top_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bg)

	top_bg.add_child(top_bar)

	# Pause button (left)
	pause_button = _create_styled_button("⏸", COLOR_PAUSE, 50)
	pause_button.pressed.connect(_on_pause_pressed)
	top_bar.add_child(pause_button)

	# Spacer
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer1)

	# Level label (center)
	level_label = Label.new()
	level_label.text = "EXPERIMENT 1"
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(level_label)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer2)

	# State label (right)
	state_label = Label.new()
	state_label.text = "PLACING"
	state_label.add_theme_font_size_override("font_size", 16)
	state_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.4))
	top_bar.add_child(state_label)

	# ---- CHAIN DISPLAY (center of screen) ----
	var chain_container := VBoxContainer.new()
	chain_container.name = "ChainDisplay"
	chain_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chain_container.position.y = 80
	chain_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	chain_container.alignment = BoxContainer.ALIGNMENT_CENTER
	chain_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chain_container)

	chain_label = Label.new()
	chain_label.text = ""
	chain_label.add_theme_font_size_override("font_size", 36)
	chain_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_label.visible = false
	chain_container.add_child(chain_label)

	chain_mult_label = Label.new()
	chain_mult_label.text = ""
	chain_mult_label.add_theme_font_size_override("font_size", 20)
	chain_mult_label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	chain_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_mult_label.visible = false
	chain_container.add_child(chain_mult_label)

	score_label = Label.new()
	score_label.text = ""
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.visible = false
	chain_container.add_child(score_label)

	# ---- BOTTOM BAR ----
	var bottom_bg := PanelContainer.new()
	bottom_bg.name = "BottomBar"
	bottom_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bg.custom_minimum_size.y = 80
	bottom_bg.set_anchor(SIDE_TOP, 1.0)
	bottom_bg.set_anchor(SIDE_BOTTOM, 1.0)
	bottom_bg.offset_top = -80
	bottom_bg.offset_bottom = 0
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	bottom_style.content_margin_left = 40
	bottom_style.content_margin_right = 40
	bottom_style.content_margin_top = 12
	bottom_style.content_margin_bottom = 12
	bottom_bg.add_theme_stylebox_override("panel", bottom_style)
	root.add_child(bottom_bg)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 30)
	bottom_bg.add_child(bottom_bar)

	# UNDO button
	undo_button = _create_styled_button("UNDO", COLOR_UNDO, 120)
	undo_button.pressed.connect(_on_undo_pressed)
	bottom_bar.add_child(undo_button)

	# RESET button
	reset_button = _create_styled_button("RESET", COLOR_RESET, 140)
	reset_button.pressed.connect(_on_reset_pressed)
	bottom_bar.add_child(reset_button)

	# GO button (larger, prominent)
	go_button = _create_styled_button("GO", COLOR_GO, 180, 56, 28)
	go_button.pressed.connect(_on_go_pressed)
	bottom_bar.add_child(go_button)


## Create a styled button with custom colors.
func _create_styled_button(text: String, color: Color, min_width: float = 120, min_height: float = 48, font_size: int = 20) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_width, min_height)

	# Normal style
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal)

	# Hover style
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	# Pressed style
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	# Disabled style
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COLOR_BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_BTN_TEXT)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))

	return btn


## Update UI based on game state.
func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	_update_for_state(new)


func _update_for_state(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.PLACING:
			go_button.disabled = false
			go_button.text = "GO"
			reset_button.disabled = false
			undo_button.disabled = false
			state_label.text = "PLACING"
			state_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.4))
			_hide_chain_display()

		GameManager.GameState.SIMULATING:
			go_button.disabled = true
			go_button.text = "..."
			reset_button.disabled = false
			undo_button.disabled = true
			state_label.text = "SIMULATING"
			state_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))

		GameManager.GameState.RESULT:
			go_button.disabled = true
			reset_button.disabled = true
			undo_button.disabled = true
			state_label.text = "RESULT"
			state_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))

		GameManager.GameState.PAUSED:
			state_label.text = "PAUSED"
			state_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	# Update level label
	if GameManager.current_level_id > 0:
		level_label.text = "EXPERIMENT %d" % GameManager.current_level_id


## Update chain display during simulation.
func update_chain(chain_count: int, total_score: int, label_text: String = "") -> void:
	if chain_count > 0:
		chain_label.visible = true
		chain_label.text = "CHAIN ×%d" % chain_count
		score_label.visible = true
		score_label.text = "%d" % total_score

		if label_text != "":
			chain_mult_label.visible = true
			chain_mult_label.text = label_text
		else:
			chain_mult_label.visible = false

		# Pulse animation on update
		var tween := create_tween()
		tween.tween_property(chain_label, "scale", Vector2(1.2, 1.2), 0.08)
		tween.tween_property(chain_label, "scale", Vector2.ONE, 0.15)


func _hide_chain_display() -> void:
	chain_label.visible = false
	chain_mult_label.visible = false
	score_label.visible = false


# Button callbacks
func _on_go_pressed() -> void:
	GameManager.trigger_go()

func _on_reset_pressed() -> void:
	GameManager.trigger_reset()

func _on_undo_pressed() -> void:
	if experiment_controller:
		experiment_controller.undo_last()

func _on_pause_pressed() -> void:
	GameManager.pause()
