## Result Screen — shown after an experiment completes or fails.
## Displays score, chain, stars, coins, and action buttons.
extends CanvasLayer

## Emitted when player chooses retry.
signal retry_requested()
## Emitted when player chooses next level.
signal next_requested()

var _panel: PanelContainer = null
var _result_label: Label = null
var _chain_label: Label = null
var _score_label: Label = null
var _stars_container: HBoxContainer = null
var _coins_label: Label = null
var _retry_btn: Button = null
var _next_btn: Button = null


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false

	GameManager.state_changed.connect(_on_state_changed)


func _create_ui() -> void:
	# Dark overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(400, 450)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.6)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	_panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# Result label (PERFECT! / GREAT! / COMPLETE! / INCOMPLETE)
	_result_label = Label.new()
	_result_label.text = "COMPLETE!"
	_result_label.add_theme_font_size_override("font_size", 36)
	_result_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)

	# Chain label
	_chain_label = Label.new()
	_chain_label.text = "CHAIN ×5"
	_chain_label.add_theme_font_size_override("font_size", 24)
	_chain_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	_chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_chain_label)

	# Score
	_score_label = Label.new()
	_score_label.text = "2,840"
	_score_label.add_theme_font_size_override("font_size", 42)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_score_label)

	# Stars
	_stars_container = HBoxContainer.new()
	_stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_stars_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_stars_container)

	# Coins
	_coins_label = Label.new()
	_coins_label.text = "+450 COINS"
	_coins_label.add_theme_font_size_override("font_size", 20)
	_coins_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_coins_label)

	# Separator
	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	_retry_btn = _make_button("RETRY", Color(0.8, 0.5, 0.2))
	_retry_btn.pressed.connect(_on_retry)
	btn_container.add_child(_retry_btn)

	_next_btn = _make_button("NEXT", Color(0.2, 0.7, 0.3))
	_next_btn.pressed.connect(_on_next)
	btn_container.add_child(_next_btn)


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 50)

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)

	return btn


## Show the result screen with experiment data.
func show_result(result: Dictionary) -> void:
	visible = true

	# Update labels
	_result_label.text = result.get("label", "COMPLETE!")
	var complete: bool = result.get("complete", false)

	if complete:
		_result_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	else:
		_result_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	var chain: int = result.get("chain", 0)
	_chain_label.text = "CHAIN ×%d" % chain if chain > 0 else ""

	var score: int = result.get("score", 0)
	_score_label.text = _format_number(score)

	var coins: int = result.get("coins", 0)
	_coins_label.text = "+%d COINS" % coins if coins > 0 else ""

	# Update stars
	_update_stars(result.get("stars", 0))

	# Show/hide next button based on completion
	_next_btn.visible = complete
	_next_btn.disabled = not complete


func _update_stars(star_count: int) -> void:
	# Clear existing stars
	for child in _stars_container.get_children():
		child.queue_free()

	for i in 3:
		var star := Label.new()
		if i < star_count:
			star.text = "★"
			star.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		else:
			star.text = "☆"
			star.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		star.add_theme_font_size_override("font_size", 40)
		_stars_container.add_child(star)


func _format_number(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result


func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	if new != GameManager.GameState.RESULT:
		visible = false


func _on_retry() -> void:
	visible = false
	GameManager.retry_level()
	retry_requested.emit()


func _on_next() -> void:
	visible = false
	GameManager.next_level()
	next_requested.emit()
