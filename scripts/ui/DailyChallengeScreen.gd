## DailyChallengeScreen — Daily laboratory experiment UI terminal.
## Displays the active daily modifier, 7-day streak rewards roadmap, and trial launcher.
class_name DailyChallengeScreen
extends Control

signal closed()
signal start_daily_requested()

var _streak_label: Label = null
var _modifier_title_label: Label = null
var _modifier_desc_label: Label = null
var _modifier_icon_label: Label = null
var _roadmap_container: HBoxContainer = null
var _start_button: Button = null
var _double_bonus_btn: Button = null
var _coins_label: Label = null
var _bonus_doubled_today: bool = false

const COLOR_BG := Color(0.03, 0.05, 0.08, 0.98)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_FLAME := Color(1.0, 0.45, 0.1)


func _ready() -> void:
	_create_ui()
	_refresh_display()


func _create_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	# Main VBox
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	vbox.offset_left = 80
	vbox.offset_right = -80
	vbox.offset_top = 36
	vbox.offset_bottom = -36
	add_child(vbox)

	# Top Navigation Bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 20)
	vbox.add_child(top_bar)

	var back_btn := Button.new()
	back_btn.text = "← BACK"
	back_btn.custom_minimum_size = Vector2(130, 46)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		closed.emit()
	)
	top_bar.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "DAILY EXPERIMENT PROTOCOL"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Coins pill
	_coins_label = Label.new()
	_coins_label.text = "🪙 0"
	_coins_label.add_theme_font_size_override("font_size", 20)
	_coins_label.add_theme_color_override("font_color", COLOR_GOLD)
	top_bar.add_child(_coins_label)

	# Streak Banner
	var streak_card := PanelContainer.new()
	streak_card.custom_minimum_size = Vector2(0, 100)
	var sc_style := StyleBoxFlat.new()
	sc_style.bg_color = Color(0.12, 0.08, 0.04, 0.9)
	sc_style.border_color = COLOR_FLAME
	sc_style.set_border_width_all(2)
	sc_style.set_corner_radius_all(14)
	sc_style.content_margin_left = 24
	sc_style.content_margin_right = 24
	streak_card.add_theme_stylebox_override("panel", sc_style)
	vbox.add_child(streak_card)

	var sc_hbox := HBoxContainer.new()
	sc_hbox.add_theme_constant_override("separation", 18)
	streak_card.add_child(sc_hbox)

	var flame_icon := Label.new()
	flame_icon.text = "🔥"
	flame_icon.add_theme_font_size_override("font_size", 42)
	sc_hbox.add_child(flame_icon)

	var sc_vbox := VBoxContainer.new()
	sc_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sc_hbox.add_child(sc_vbox)

	_streak_label = Label.new()
	_streak_label.text = "CURRENT STREAK: 0 DAYS"
	_streak_label.add_theme_font_size_override("font_size", 22)
	_streak_label.add_theme_color_override("font_color", COLOR_FLAME)
	sc_vbox.add_child(_streak_label)

	var streak_sub := Label.new()
	streak_sub.text = "Complete consecutive daily experiments to earn massive coin multipliers!"
	streak_sub.add_theme_font_size_override("font_size", 13)
	streak_sub.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	sc_vbox.add_child(streak_sub)

	# 7-Day Reward Roadmap
	var roadmap_label := Label.new()
	roadmap_label.text = "7-DAY STREAK REWARDS"
	roadmap_label.add_theme_font_size_override("font_size", 16)
	roadmap_label.add_theme_color_override("font_color", COLOR_GOLD)
	vbox.add_child(roadmap_label)

	_roadmap_container = HBoxContainer.new()
	_roadmap_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_roadmap_container.add_theme_constant_override("separation", 14)
	vbox.add_child(_roadmap_container)

	# Active Modifier Section
	var mod_label := Label.new()
	mod_label.text = "ACTIVE LABORATORY MODIFIER"
	mod_label.add_theme_font_size_override("font_size", 16)
	mod_label.add_theme_color_override("font_color", COLOR_CYAN)
	vbox.add_child(mod_label)

	var mod_panel := PanelContainer.new()
	var mp_style := StyleBoxFlat.new()
	mp_style.bg_color = Color(0.06, 0.1, 0.16, 0.95)
	mp_style.border_color = Color(0.15, 0.3, 0.45, 0.8)
	mp_style.set_border_width_all(1)
	mp_style.set_corner_radius_all(12)
	mp_style.content_margin_left = 24
	mp_style.content_margin_right = 24
	mp_style.content_margin_top = 20
	mp_style.content_margin_bottom = 20
	mod_panel.add_theme_stylebox_override("panel", mp_style)
	vbox.add_child(mod_panel)

	var mp_hbox := HBoxContainer.new()
	mp_hbox.add_theme_constant_override("separation", 20)
	mod_panel.add_child(mp_hbox)

	_modifier_icon_label = Label.new()
	_modifier_icon_label.text = "⚡"
	_modifier_icon_label.add_theme_font_size_override("font_size", 38)
	mp_hbox.add_child(_modifier_icon_label)

	var mp_vbox := VBoxContainer.new()
	mp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mp_hbox.add_child(mp_vbox)

	_modifier_title_label = Label.new()
	_modifier_title_label.text = "Modifier Title"
	_modifier_title_label.add_theme_font_size_override("font_size", 20)
	_modifier_title_label.add_theme_color_override("font_color", Color.WHITE)
	mp_vbox.add_child(_modifier_title_label)

	_modifier_desc_label = Label.new()
	_modifier_desc_label.text = "Modifier description text detailing physics alterations."
	_modifier_desc_label.add_theme_font_size_override("font_size", 14)
	_modifier_desc_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	mp_vbox.add_child(_modifier_desc_label)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# Action Button
	_start_button = Button.new()
	_start_button.custom_minimum_size = Vector2(340, 56)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.add_theme_font_size_override("font_size", 18)
	_start_button.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		start_daily_requested.emit()
	)
	vbox.add_child(_start_button)

	_double_bonus_btn = Button.new()
	_double_bonus_btn.custom_minimum_size = Vector2(340, 48)
	_double_bonus_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_double_bonus_btn.focus_mode = Control.FOCUS_NONE
	var db_style := StyleBoxFlat.new()
	db_style.bg_color = Color(0.85, 0.55, 0.05, 0.95)
	db_style.border_color = Color(1.0, 0.9, 0.3)
	db_style.set_border_width_all(1)
	db_style.set_corner_radius_all(10)
	_double_bonus_btn.add_theme_stylebox_override("normal", db_style)
	_double_bonus_btn.add_theme_font_size_override("font_size", 15)
	_double_bonus_btn.add_theme_color_override("font_color", Color.WHITE)
	_double_bonus_btn.pressed.connect(_on_double_bonus_pressed)
	_double_bonus_btn.visible = false
	vbox.add_child(_double_bonus_btn)


func _on_double_bonus_pressed() -> void:
	if _bonus_doubled_today:
		return
	AudioManager.play_ui_blip("click")
	var daily_mgr = get_node_or_null("/root/DailyChallengeManager")
	var streak: int = daily_mgr.get_streak() if daily_mgr else 1
	var bonus_amount: int = daily_mgr.get_streak_reward(streak) if daily_mgr else 100

	PlatformService.show_rewarded_ad("daily_bonus_doubler", func(success: bool):
		if success:
			SaveManager.add_coins(bonus_amount)
			_bonus_doubled_today = true
			AudioManager.play_fanfare()
			_refresh_display()
	)


func _refresh_display() -> void:
	if not get_node_or_null("/root/DailyChallengeManager"):
		return

	var daily_mgr = get_node_or_null("/root/DailyChallengeManager")
	var streak: int = daily_mgr.get_streak()
	var completed_today: bool = daily_mgr.is_today_completed()

	if _coins_label:
		_coins_label.text = "🪙 %d" % SaveManager.get_coins()

	if _streak_label:
		_streak_label.text = "CURRENT STREAK: %d DAYS" % streak

	# Active Modifier
	var mod_info: Dictionary = daily_mgr.get_modifier_info()
	if _modifier_icon_label:
		_modifier_icon_label.text = mod_info.get("icon", "⚡")
	if _modifier_title_label:
		_modifier_title_label.text = mod_info.get("name", "Daily Modifier")
		_modifier_title_label.add_theme_color_override("font_color", mod_info.get("color", Color.WHITE))
	if _modifier_desc_label:
		_modifier_desc_label.text = mod_info.get("desc", "")

	# Roadmap Cards
	for child in _roadmap_container.get_children():
		child.queue_free()

	var rewards: Array = daily_mgr.STREAK_REWARDS
	for day_idx in rewards.size():
		var day_num := day_idx + 1
		var reward_val: int = rewards[day_idx]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(105, 110)

		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(10)
		style.content_margin_top = 10
		style.content_margin_bottom = 10

		var is_past: bool = (day_num <= streak)
		var is_current: bool = (day_num == streak + 1 and not completed_today)

		if is_past:
			style.bg_color = Color(0.08, 0.2, 0.12, 0.9)
			style.border_color = Color(0.2, 0.9, 0.4)
			style.set_border_width_all(1)
		elif is_current:
			style.bg_color = Color(0.18, 0.14, 0.05, 0.95)
			style.border_color = COLOR_GOLD
			style.set_border_width_all(2)
		else:
			style.bg_color = Color(0.06, 0.08, 0.12, 0.7)
			style.border_color = Color(0.15, 0.2, 0.28, 0.5)
			style.set_border_width_all(1)

		card.add_theme_stylebox_override("panel", style)

		var cvbox := VBoxContainer.new()
		cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(cvbox)

		var d_lbl := Label.new()
		d_lbl.text = "DAY %d" % day_num
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d_lbl.add_theme_font_size_override("font_size", 12)
		d_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		cvbox.add_child(d_lbl)

		var r_lbl := Label.new()
		r_lbl.text = "🪙 %d" % reward_val
		r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r_lbl.add_theme_font_size_override("font_size", 14)
		r_lbl.add_theme_color_override("font_color", COLOR_GOLD if (is_past or is_current) else Color(0.6, 0.6, 0.6))
		cvbox.add_child(r_lbl)

		var status_lbl := Label.new()
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.add_theme_font_size_override("font_size", 16)
		status_lbl.text = "✓" if is_past else ("★" if is_current else "🔒")
		status_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4) if is_past else (COLOR_GOLD if is_current else Color(0.4, 0.4, 0.4)))
		cvbox.add_child(status_lbl)

		_roadmap_container.add_child(card)

	# Action Buttons
	if completed_today:
		_start_button.text = "✓ EXPERIMENT COMPLETED TODAY"
		_start_button.disabled = true
		_double_bonus_btn.visible = true
		if _bonus_doubled_today:
			_double_bonus_btn.text = "✓ 2X BONUS CLAIMED"
			_double_bonus_btn.disabled = true
		else:
			_double_bonus_btn.text = "🎬 DOUBLE TODAY'S BONUS (2X)"
			_double_bonus_btn.disabled = false
	else:
		_start_button.text = "▶ START DAILY EXPERIMENT"
		_start_button.disabled = false
		_double_bonus_btn.visible = false
		var start_style := StyleBoxFlat.new()
		start_style.bg_color = Color(0.1, 0.45, 0.75, 0.95)
		start_style.border_color = COLOR_CYAN
		start_style.set_border_width_all(1)
		start_style.set_corner_radius_all(10)
		_start_button.add_theme_stylebox_override("normal", start_style)
