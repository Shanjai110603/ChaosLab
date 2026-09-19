## AchievementsScreen — Laboratory Milestones and Achievements terminal.
## Displays progress bars, badge icons, and claimable coin rewards for all 12 achievements.
class_name AchievementsScreen
extends Control

signal closed()

var _coins_label: Label = null
var _unlocked_counter_label: Label = null
var _cards_container: VBoxContainer = null

const COLOR_BG := Color(0.03, 0.05, 0.08, 0.98)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_GREEN := Color(0.2, 0.9, 0.4)


func _ready() -> void:
	_create_ui()
	_refresh_display()
	# Apply spring-physics micro-animations to all buttons
	UIAnimations.setup_all_buttons(self)


func _create_ui() -> void:
	custom_minimum_size = Vector2(1920, 1080)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fullscreen background
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	# Main VBox
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.offset_left = 80
	vbox.offset_right = -80
	vbox.offset_top = 30
	vbox.offset_bottom = -30
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
	title_lbl.text = "LABORATORY MILESTONES & ACHIEVEMENTS"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Unlocked Counter
	_unlocked_counter_label = Label.new()
	_unlocked_counter_label.text = "0 / 12 UNLOCKED"
	_unlocked_counter_label.add_theme_font_size_override("font_size", 18)
	_unlocked_counter_label.add_theme_color_override("font_color", COLOR_GOLD)
	top_bar.add_child(_unlocked_counter_label)

	# Coins pill
	_coins_label = Label.new()
	_coins_label.text = "0 COINS"
	_coins_label.add_theme_font_size_override("font_size", 18)
	_coins_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	top_bar.add_child(_coins_label)

	# Scrollable List Container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 14)
	scroll.add_child(_cards_container)


func _refresh_display() -> void:
	if not get_node_or_null("/root/AchievementManager"):
		return

	var ach_mgr = get_node_or_null("/root/AchievementManager")

	if _coins_label:
		_coins_label.text = "%d COINS" % SaveManager.get_coins()

	if _unlocked_counter_label:
		_unlocked_counter_label.text = "%d / %d UNLOCKED" % [ach_mgr.get_completed_count(), ach_mgr.get_catalog().size()]

	# Clear and rebuild achievement cards
	for child in _cards_container.get_children():
		child.queue_free()

	for item in ach_mgr.get_catalog():
		var card := _create_achievement_card(item, ach_mgr)
		_cards_container.add_child(card)


func _create_achievement_card(item: Dictionary, ach_mgr: Node) -> Control:
	var id: String = item["id"]
	var progress: int = ach_mgr.get_progress(id)
	var target: int = item.get("target", 1)
	var is_done: bool = (progress >= target)
	var is_claimed: bool = ach_mgr.is_claimed(id)
	var reward: int = item.get("reward", 0)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 84)

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	if is_claimed:
		style.bg_color = Color(0.06, 0.12, 0.08, 0.9)
		style.border_color = Color(0.2, 0.7, 0.3, 0.6)
		style.set_border_width_all(1)
	elif is_done:
		style.bg_color = Color(0.14, 0.12, 0.04, 0.95)
		style.border_color = COLOR_GOLD
		style.set_border_width_all(2)
	else:
		style.bg_color = Color(0.06, 0.08, 0.13, 0.8)
		style.border_color = Color(0.15, 0.22, 0.32, 0.5)
		style.set_border_width_all(1)

	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	# Icon
	var icon_lbl := Label.new()
	icon_lbl.text = item.get("icon", "[ACH]")
	icon_lbl.add_theme_font_size_override("font_size", 16)
	icon_lbl.add_theme_color_override("font_color", COLOR_GOLD if is_done else COLOR_CYAN)
	hbox.add_child(icon_lbl)

	# Info VBox
	var ivbox := VBoxContainer.new()
	ivbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ivbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(ivbox)

	var name_lbl := Label.new()
	name_lbl.text = item.get("name", "Achievement")
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color.WHITE if not is_claimed else Color(0.75, 0.9, 0.75))
	ivbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	ivbox.add_child(desc_lbl)

	# Progress Bar
	var p_bar := ProgressBar.new()
	p_bar.custom_minimum_size = Vector2(0, 14)
	p_bar.min_value = 0
	p_bar.max_value = target
	p_bar.value = progress
	p_bar.show_percentage = false
	ivbox.add_child(p_bar)

	# Progress Text
	var p_lbl := Label.new()
	p_lbl.text = "%d / %d" % [progress, target]
	p_lbl.add_theme_font_size_override("font_size", 11)
	p_lbl.add_theme_color_override("font_color", COLOR_CYAN if not is_done else COLOR_GOLD)
	ivbox.add_child(p_lbl)

	# Action Claim Button
	var act_btn := Button.new()
	act_btn.custom_minimum_size = Vector2(170, 48)
	act_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	act_btn.focus_mode = Control.FOCUS_NONE
	act_btn.add_theme_font_size_override("font_size", 14)

	if is_claimed:
		act_btn.text = "CLAIMED"
		act_btn.disabled = true
	elif is_done:
		act_btn.text = "CLAIM %d COINS" % reward
		var claim_style := StyleBoxFlat.new()
		claim_style.bg_color = Color(0.8, 0.65, 0.1, 0.95)
		claim_style.set_corner_radius_all(8)
		act_btn.add_theme_stylebox_override("normal", claim_style)
		act_btn.pressed.connect(func():
			if ach_mgr.claim_reward(id):
				_refresh_display()
		)
	else:
		act_btn.text = "🪙 %d BOUNTY" % reward
		act_btn.disabled = true

	hbox.add_child(act_btn)
	return panel
