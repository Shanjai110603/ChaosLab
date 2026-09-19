## Result Screen — shown after an experiment completes or fails.
## Displays score breakdown, par efficiency bonus, animated stars, and navigation buttons.
class_name ResultScreenClass
extends CanvasLayer

signal retry_requested()
signal next_requested()
signal level_select_requested()

var _panel: PanelContainer = null
var _result_label: Label = null
var _score_label: Label = null
var _raw_score_label: Label = null
var _par_bonus_label: Label = null
var _stars_container: HBoxContainer = null
var _coins_label: Label = null
var _double_btn: Button = null
var _retry_btn: Button = null
var _select_btn: Button = null
var _next_btn: Button = null

var _earned_coins: int = 0
var _double_claimed: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false
	GameManager.state_changed.connect(_on_state_changed)
	# Apply spring-physics micro-animations to all buttons
	UIAnimations.setup_all_buttons(self)


func _create_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.04, 0.07, 0.82)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(460, 520)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.16, 0.95)
	style.set_corner_radius_all(18)
	style.set_border_width_all(2)
	style.border_color = Color(0.0, 0.85, 1.0, 0.6)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# Title Banner
	_result_label = Label.new()
	_result_label.text = "EXPERIMENT COMPLETE!"
	_result_label.add_theme_font_size_override("font_size", 28)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)

	# Animated Stars Container
	_stars_container = HBoxContainer.new()
	_stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_stars_container.add_theme_constant_override("separation", 16)
	vbox.add_child(_stars_container)

	# Score display
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", 46)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_score_label)

	# Score breakdown box
	var breakdown := VBoxContainer.new()
	breakdown.add_theme_constant_override("separation", 4)
	vbox.add_child(breakdown)

	_raw_score_label = Label.new()
	_raw_score_label.text = "Chain Reaction Points: 0"
	_raw_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raw_score_label.add_theme_font_size_override("font_size", 14)
	_raw_score_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 0.85))
	breakdown.add_child(_raw_score_label)

	_par_bonus_label = Label.new()
	_par_bonus_label.text = "Par Efficiency Bonus: +0"
	_par_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_par_bonus_label.add_theme_font_size_override("font_size", 14)
	_par_bonus_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 0.9))
	breakdown.add_child(_par_bonus_label)

	_coins_label = Label.new()
	_coins_label.text = "+0 COINS"
	_coins_label.add_theme_font_size_override("font_size", 20)
	_coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_coins_label)

	# 2X Rewarded Ad Doubler Button
	_double_btn = Button.new()
	_double_btn.text = "2X DOUBLE COINS"
	_double_btn.custom_minimum_size = Vector2(240, 42)
	_double_btn.focus_mode = Control.FOCUS_NONE
	var d_style := StyleBoxFlat.new()
	d_style.bg_color = Color(0.85, 0.55, 0.05, 0.95)
	d_style.border_color = Color(1.0, 0.9, 0.3)
	d_style.set_border_width_all(1)
	d_style.set_corner_radius_all(10)
	_double_btn.add_theme_stylebox_override("normal", d_style)
	_double_btn.add_theme_font_size_override("font_size", 14)
	_double_btn.add_theme_color_override("font_color", Color.WHITE)
	_double_btn.pressed.connect(_on_double_pressed)
	vbox.add_child(_double_btn)

	vbox.add_child(HSeparator.new())

	# Action Buttons
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_container)

	_retry_btn = _make_button("RETRY", Color(0.85, 0.5, 0.15))
	_retry_btn.pressed.connect(_on_retry)
	btn_container.add_child(_retry_btn)

	_select_btn = _make_button("LEVELS", Color(0.3, 0.45, 0.65))
	_select_btn.pressed.connect(_on_level_select)
	btn_container.add_child(_select_btn)

	_next_btn = _make_button("NEXT", Color(0.18, 0.82, 0.45))
	_next_btn.pressed.connect(_on_next)
	btn_container.add_child(_next_btn)


func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(125, 48)
	btn.focus_mode = Control.FOCUS_NONE

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


func show_result(result: Dictionary) -> void:
	visible = true

	var complete: bool = result.get("complete", false)
	_result_label.text = result.get("label", "EXPERIMENT COMPLETE!")
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25) if complete else Color(1.0, 0.35, 0.35))

	var raw_score: int = result.get("raw_score", 0)
	var par_bonus: int = result.get("par_bonus", 0)
	var final_score: int = result.get("score", raw_score)
	var coins: int = result.get("coins", 0)
	var stars: int = result.get("stars", 0)

	_score_label.text = "%d" % final_score
	_raw_score_label.text = "Chain Reaction Points: %d" % raw_score
	_par_bonus_label.text = "Par Efficiency Bonus: +%d" % par_bonus if par_bonus > 0 else ""
	_coins_label.text = "+%d COINS" % coins if coins > 0 else ""

	_earned_coins = coins
	_double_claimed = false
	if complete and coins > 0:
		_double_btn.visible = true
		_double_btn.disabled = false
		_double_btn.text = "2X DOUBLE (+%d COINS)" % coins
	else:
		_double_btn.visible = false

	_animate_stars(stars)

	# 3-Star Celebration Juice
	if complete and stars >= 3:
		ConfettiEffect.spawn(self)
		AudioManager.play_fanfare()
	elif complete:
		AudioManager.play_chime(4)

	_next_btn.visible = complete
	_next_btn.disabled = not complete


func _on_double_pressed() -> void:
	if _double_claimed or _earned_coins <= 0:
		return
	AudioManager.play_ui_blip("click")
	PlatformService.show_rewarded_ad("result_double_coins", func(success: bool):
		if success:
			SaveManager.add_coins(_earned_coins)
			_double_claimed = true
			_double_btn.text = "2X CLAIMED"
			_double_btn.disabled = true
			_coins_label.text = "+%d COINS (DOUBLED! 2X)" % (_earned_coins * 2)
			ConfettiEffect.spawn(self)
			AudioManager.play_fanfare()
	)


func _animate_stars(star_count: int) -> void:
	for child in _stars_container.get_children():
		child.queue_free()

	for i in 3:
		var star_box := Control.new()
		star_box.custom_minimum_size = Vector2(52, 52)
		star_box.pivot_offset = Vector2(26, 26)
		star_box.scale = Vector2.ZERO
		var is_earned := (i < star_count)
		star_box.draw.connect(func():
			var center := Vector2(26, 26)
			var radius: float = 24.0
			var inner: float = radius * 0.42
			var pts := PackedVector2Array()
			for j in range(10):
				var ang := -PI * 0.5 + j * (PI / 5.0)
				var r := radius if (j % 2 == 0) else inner
				pts.append(center + Vector2(cos(ang), sin(ang)) * r)
			if is_earned:
				star_box.draw_colored_polygon(pts, Color(1.0, 0.85, 0.2))
				star_box.draw_polyline(pts, Color(1.0, 1.0, 0.6), 2.0, true)
			else:
				star_box.draw_polyline(pts, Color(0.3, 0.35, 0.45), 2.0, true)
		)
		_stars_container.add_child(star_box)

		if is_earned:
			var tween := create_tween()
			tween.tween_interval(0.15 * (i + 1))
			tween.tween_property(star_box, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(star_box, "scale", Vector2.ONE, 0.1)
		else:
			star_box.scale = Vector2.ONE


func _on_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	if new != GameManager.GameState.RESULT:
		visible = false


func _on_retry() -> void:
	visible = false
	GameManager.retry_level()
	retry_requested.emit()


func _on_next() -> void:
	PlatformService.on_level_completed()
	PlatformService.show_interstitial("next_level", func():
		visible = false
		GameManager.next_level()
		next_requested.emit()
	)


func _on_level_select() -> void:
	PlatformService.on_level_completed()
	PlatformService.show_interstitial("level_select", func():
		visible = false
		level_select_requested.emit()
	)
