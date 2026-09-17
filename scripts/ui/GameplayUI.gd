## Gameplay UI — Premium styled HUD for the experiment.
## GO, RESET, UNDO buttons + level info + chain counter + visual flair.
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
## Title label.
var title_label: Label = null

## Reference to experiment controller (set by Main).
var experiment_controller: ExperimentController = null

## Curated color palette.
const COLOR_GO := Color(0.18, 0.82, 0.45)       # Emerald green
const COLOR_GO_GLOW := Color(0.1, 0.95, 0.5, 0.3)
const COLOR_RESET := Color(0.95, 0.55, 0.15)     # Warm orange
const COLOR_UNDO := Color(0.45, 0.5, 0.65)       # Muted steel
const COLOR_PAUSE := Color(0.35, 0.4, 0.55)      # Slate
const COLOR_BTN_TEXT := Color(1, 1, 1, 0.95)
const COLOR_ACCENT := Color(0.4, 0.7, 1.0)       # Soft cyan
const COLOR_GOLD := Color(1.0, 0.85, 0.25)       # Gold
const COLOR_BG_DARK := Color(0.04, 0.05, 0.08, 0.92)
const COLOR_BG_PANEL := Color(0.07, 0.09, 0.13, 0.88)
const COLOR_BORDER := Color(0.25, 0.4, 0.65, 0.4)

## Glow animation time.
var _glow_time: float = 0.0


func _ready() -> void:
	layer = 10
	_create_ui()

	# Connect to game manager signals
	GameManager.state_changed.connect(_on_state_changed)

	# Update initial state
	_update_for_state(GameManager.current_state)


func _process(delta: float) -> void:
	_glow_time += delta
	# Pulsing GO button glow
	if go_button and not go_button.disabled:
		var pulse: float = (sin(_glow_time * 2.5) * 0.5 + 0.5)
		var glow_color := COLOR_GO.lerp(COLOR_GO.lightened(0.3), pulse)
		var style := go_button.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			style.shadow_color = Color(glow_color, 0.25 + pulse * 0.15)


func _create_ui() -> void:
	var root := Control.new()
	root.name = "UIRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_create_top_bar(root)
	_create_chain_display(root)
	_create_bottom_bar(root)


func _create_top_bar(root: Control) -> void:
	# ---- TOP BAR with glassmorphism ----
	var top_bg := PanelContainer.new()
	top_bg.name = "TopBar"
	top_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size.y = 64

	var top_style := StyleBoxFlat.new()
	top_style.bg_color = COLOR_BG_DARK
	top_style.border_width_bottom = 1
	top_style.border_color = COLOR_BORDER
	top_style.content_margin_left = 24
	top_style.content_margin_right = 24
	top_style.content_margin_top = 10
	top_style.content_margin_bottom = 10
	# Subtle bottom shadow
	top_style.shadow_color = Color(0, 0, 0, 0.3)
	top_style.shadow_size = 4
	top_style.shadow_offset = Vector2(0, 2)
	top_bg.add_theme_stylebox_override("panel", top_style)
	top_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bg)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bg.add_child(top_bar)

	# Pause button (left) — icon-style
	pause_button = _create_icon_button("⏸", COLOR_PAUSE, 44)
	pause_button.pressed.connect(_on_pause_pressed)
	top_bar.add_child(pause_button)

	# Left spacer
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer1)

	# Center: Title + Level
	var center_box := VBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", -2)
	top_bar.add_child(center_box)

	title_label = Label.new()
	title_label.text = "CHAOS LAB"
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(0.5, 0.65, 0.85, 0.7))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(title_label)

	level_label = Label.new()
	level_label.text = "EXPERIMENT 1"
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.98))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(level_label)

	# Right spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer2)

	# State pill (right)
	state_label = Label.new()
	state_label.text = "● READY"
	state_label.add_theme_font_size_override("font_size", 14)
	state_label.add_theme_color_override("font_color", COLOR_GO)
	top_bar.add_child(state_label)


func _create_chain_display(root: Control) -> void:
	# ---- CHAIN DISPLAY (center of screen) ----
	var chain_container := VBoxContainer.new()
	chain_container.name = "ChainDisplay"
	chain_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chain_container.position.y = 80
	chain_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	chain_container.alignment = BoxContainer.ALIGNMENT_CENTER
	chain_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(chain_container)

	# Chain backdrop
	var chain_bg := PanelContainer.new()
	chain_bg.custom_minimum_size = Vector2(260, 0)
	var chain_style := StyleBoxFlat.new()
	chain_style.bg_color = Color(0, 0, 0, 0.5)
	chain_style.corner_radius_top_left = 12
	chain_style.corner_radius_top_right = 12
	chain_style.corner_radius_bottom_left = 12
	chain_style.corner_radius_bottom_right = 12
	chain_style.border_width_left = 1
	chain_style.border_width_right = 1
	chain_style.border_width_top = 1
	chain_style.border_width_bottom = 1
	chain_style.border_color = COLOR_GOLD * Color(1, 1, 1, 0.3)
	chain_style.content_margin_left = 20
	chain_style.content_margin_right = 20
	chain_style.content_margin_top = 12
	chain_style.content_margin_bottom = 12
	chain_bg.add_theme_stylebox_override("panel", chain_style)
	chain_bg.visible = false
	chain_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chain_container.add_child(chain_bg)

	var chain_vbox := VBoxContainer.new()
	chain_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	chain_vbox.add_theme_constant_override("separation", 4)
	chain_bg.add_child(chain_vbox)

	chain_label = Label.new()
	chain_label.text = ""
	chain_label.add_theme_font_size_override("font_size", 38)
	chain_label.add_theme_color_override("font_color", COLOR_GOLD)
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_vbox.add_child(chain_label)

	chain_mult_label = Label.new()
	chain_mult_label.text = ""
	chain_mult_label.add_theme_font_size_override("font_size", 22)
	chain_mult_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	chain_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_mult_label.visible = false
	chain_vbox.add_child(chain_mult_label)

	score_label = Label.new()
	score_label.text = ""
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_vbox.add_child(score_label)


func _create_bottom_bar(root: Control) -> void:
	# ---- BOTTOM BAR with glassmorphism ----
	var bottom_bg := PanelContainer.new()
	bottom_bg.name = "BottomBar"
	bottom_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bg.custom_minimum_size.y = 90
	bottom_bg.set_anchor(SIDE_TOP, 1.0)
	bottom_bg.set_anchor(SIDE_BOTTOM, 1.0)
	bottom_bg.offset_top = -90
	bottom_bg.offset_bottom = 0

	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = COLOR_BG_DARK
	bottom_style.border_width_top = 1
	bottom_style.border_color = COLOR_BORDER
	bottom_style.content_margin_left = 40
	bottom_style.content_margin_right = 40
	bottom_style.content_margin_top = 14
	bottom_style.content_margin_bottom = 14
	# Top shadow
	bottom_style.shadow_color = Color(0, 0, 0, 0.3)
	bottom_style.shadow_size = 6
	bottom_style.shadow_offset = Vector2(0, -3)
	bottom_bg.add_theme_stylebox_override("panel", bottom_style)
	root.add_child(bottom_bg)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 20)
	bottom_bg.add_child(bottom_bar)

	# Keyboard hints container (left side)
	var hints := VBoxContainer.new()
	hints.add_theme_constant_override("separation", 0)
	hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hint1 := Label.new()
	hint1.text = "[Z] Undo   [R] Reset"
	hint1.add_theme_font_size_override("font_size", 11)
	hint1.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55, 0.6))
	hints.add_child(hint1)
	var hint2 := Label.new()
	hint2.text = "[Space] Go   [Esc] Pause"
	hint2.add_theme_font_size_override("font_size", 11)
	hint2.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55, 0.6))
	hints.add_child(hint2)
	bottom_bar.add_child(hints)

	# UNDO button
	undo_button = _create_action_button("↩ UNDO", COLOR_UNDO, 130, 52)
	undo_button.pressed.connect(_on_undo_pressed)
	bottom_bar.add_child(undo_button)

	# RESET button
	reset_button = _create_action_button("⟳ RESET", COLOR_RESET, 150, 52)
	reset_button.pressed.connect(_on_reset_pressed)
	bottom_bar.add_child(reset_button)

	# GO button (hero button — much larger)
	go_button = _create_go_button()
	go_button.pressed.connect(_on_go_pressed)
	bottom_bar.add_child(go_button)

	# Right spacer for balance
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(spacer)


## Create the prominent GO button with glow effect.
func _create_go_button() -> Button:
	var btn := Button.new()
	btn.text = "▶ GO"
	btn.custom_minimum_size = Vector2(200, 58)

	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_GO
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	# Glow shadow
	normal.shadow_color = Color(COLOR_GO, 0.35)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 2)
	# Subtle inner border
	normal.border_width_top = 1
	normal.border_color = Color(1, 1, 1, 0.15)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = COLOR_GO.lightened(0.12)
	hover.shadow_size = 12
	hover.shadow_color = Color(COLOR_GO, 0.5)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = COLOR_GO.darkened(0.15)
	pressed.shadow_size = 3
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.2, 0.25, 0.3, 0.6)
	disabled.shadow_size = 0
	disabled.border_width_top = 0
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.95, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 0.6))

	return btn


## Create a styled action button (UNDO, RESET).
func _create_action_button(text: String, color: Color, min_width: float = 130, min_height: float = 50) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_width, min_height)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color, 0.85)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.border_width_top = 1
	normal.border_color = Color(1, 1, 1, 0.08)
	normal.shadow_color = Color(0, 0, 0, 0.25)
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.1)
	hover.shadow_size = 5
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	pressed.shadow_size = 1
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.2, 0.22, 0.28, 0.5)
	disabled.shadow_size = 0
	disabled.border_width_top = 0
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", COLOR_BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.5, 0.5))

	return btn


## Create a small icon button (pause).
func _create_icon_button(text: String, color: Color, btn_size: float = 44) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(btn_size, btn_size)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color, 0.6)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(1, 1, 1, 0.1)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.15)
	hover.border_color = Color(1, 1, 1, 0.2)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))

	return btn


## Update UI based on game state.
func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	_update_for_state(new)


func _update_for_state(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.PLACING:
			go_button.disabled = false
			go_button.text = "▶  GO"
			reset_button.disabled = false
			undo_button.disabled = false
			state_label.text = "● READY"
			state_label.add_theme_color_override("font_color", COLOR_GO)
			_hide_chain_display()

		GameManager.GameState.SIMULATING:
			go_button.disabled = true
			go_button.text = "⚡ RUNNING"
			reset_button.disabled = false
			undo_button.disabled = true
			state_label.text = "◉ SIMULATING"
			state_label.add_theme_color_override("font_color", COLOR_GOLD)

		GameManager.GameState.RESULT:
			go_button.disabled = true
			go_button.text = "✓ DONE"
			reset_button.disabled = true
			undo_button.disabled = true
			state_label.text = "★ RESULT"
			state_label.add_theme_color_override("font_color", COLOR_ACCENT)

		GameManager.GameState.PAUSED:
			state_label.text = "⏸ PAUSED"
			state_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))

	# Update level label
	if GameManager.current_level_id > 0:
		level_label.text = "EXPERIMENT %d" % GameManager.current_level_id


## Update chain display during simulation.
func update_chain(chain_count: int, total_score: int, label_text: String = "") -> void:
	if chain_count > 0:
		# Show the chain background panel
		var chain_bg := chain_label.get_parent().get_parent()
		if chain_bg:
			chain_bg.visible = true

		chain_label.text = "CHAIN ×%d" % chain_count
		score_label.text = "%d" % total_score

		if label_text != "":
			chain_mult_label.visible = true
			chain_mult_label.text = label_text
		else:
			chain_mult_label.visible = false

		# Pulse animation on update
		var tween := create_tween()
		tween.tween_property(chain_label, "scale", Vector2(1.15, 1.15), 0.06).set_ease(Tween.EASE_OUT)
		tween.tween_property(chain_label, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN_OUT)


func _hide_chain_display() -> void:
	var chain_bg := chain_label.get_parent().get_parent()
	if chain_bg:
		chain_bg.visible = false
	chain_mult_label.visible = false


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
