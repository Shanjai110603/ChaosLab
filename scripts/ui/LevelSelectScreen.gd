## LevelSelectScreen — World and Level selection menu.
## Displays world tabs, level cards with stars, high scores, and lock states.
class_name LevelSelectScreen
extends Control

signal level_chosen(level_id: int)
signal back_to_menu_requested()

var current_world: int = 1
var _grid_container: GridContainer = null
var _stars_label: Label = null
var _coins_label: Label = null
var _world_title_label: Label = null
var _tab_world1: Button = null
var _tab_world2: Button = null

const COLOR_BG := Color(0.04, 0.06, 0.09, 0.96)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_LOCKED := Color(0.2, 0.25, 0.32, 0.6)


func _ready() -> void:
	_create_ui()
	_refresh_display()


func _create_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fullscreen dark lab background
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	# Main VBox container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	vbox.offset_left = 60
	vbox.offset_right = -60
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	add_child(vbox)

	# Top navigation bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 20)
	vbox.add_child(top_bar)

	var back_btn := Button.new()
	back_btn.text = "← MENU"
	back_btn.custom_minimum_size = Vector2(120, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func(): back_to_menu_requested.emit())
	top_bar.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "EXPERIMENT SELECTION"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Stars pill
	_stars_label = Label.new()
	_stars_label.text = "★ 0 / 60"
	_stars_label.add_theme_font_size_override("font_size", 18)
	_stars_label.add_theme_color_override("font_color", COLOR_GOLD)
	top_bar.add_child(_stars_label)

	# Coins pill
	_coins_label = Label.new()
	_coins_label.text = "🪙 0"
	_coins_label.add_theme_font_size_override("font_size", 18)
	_coins_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	top_bar.add_child(_coins_label)

	# World selector tabs
	var tabs_box := HBoxContainer.new()
	tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_box.add_theme_constant_override("separation", 24)
	vbox.add_child(tabs_box)

	_tab_world1 = Button.new()
	_tab_world1.text = "WORLD 1: THE MECHANICS LAB"
	_tab_world1.custom_minimum_size = Vector2(300, 48)
	_tab_world1.add_theme_font_size_override("font_size", 15)
	_tab_world1.focus_mode = Control.FOCUS_NONE
	_tab_world1.pressed.connect(func(): _select_world(1))
	tabs_box.add_child(_tab_world1)

	_tab_world2 = Button.new()
	_tab_world2.text = "WORLD 2: KINETIC BALLISTICS"
	_tab_world2.custom_minimum_size = Vector2(300, 48)
	_tab_world2.add_theme_font_size_override("font_size", 15)
	_tab_world2.focus_mode = Control.FOCUS_NONE
	_tab_world2.pressed.connect(func(): _select_world(2))
	tabs_box.add_child(_tab_world2)

	# Grid Container for Level Cards (5 columns x 2 rows)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var center_margin := MarginContainer.new()
	center_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_margin.add_theme_constant_override("margin_left", 40)
	center_margin.add_theme_constant_override("margin_right", 40)
	center_margin.add_theme_constant_override("margin_top", 10)
	scroll.add_child(center_margin)

	_grid_container = GridContainer.new()
	_grid_container.columns = 5
	_grid_container.add_theme_constant_override("h_separation", 24)
	_grid_container.add_theme_constant_override("v_separation", 24)
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_margin.add_child(_grid_container)


func _select_world(world: int) -> void:
	current_world = world
	_refresh_display()


func _refresh_display() -> void:
	# Update pills
	_stars_label.text = "★ %d / 60" % SaveManager.get_total_stars()
	_coins_label.text = "🪙 %d" % SaveManager.get_coins()

	# Highlight active tab
	if current_world == 1:
		_tab_world1.modulate = Color(0.0, 1.0, 0.85, 1.0)
		_tab_world2.modulate = Color(0.7, 0.75, 0.85, 0.7)
	else:
		_tab_world1.modulate = Color(0.7, 0.75, 0.85, 0.7)
		_tab_world2.modulate = Color(0.0, 1.0, 0.85, 1.0)

	# Clear and rebuild level cards
	for child in _grid_container.get_children():
		child.queue_free()

	var start_id := (current_world - 1) * 10 + 1
	var end_id := start_id + 9

	for id in range(start_id, end_id + 1):
		_create_level_card(id)


func _create_level_card(level_id: int) -> void:
	var is_unlocked := SaveManager.is_level_unlocked(level_id)
	var stars := SaveManager.get_level_stars(level_id)
	var best_score := SaveManager.get_level_best_score(level_id)

	var card := Button.new()
	card.custom_minimum_size = Vector2(240, 140)
	card.focus_mode = Control.FOCUS_NONE

	var card_style := StyleBoxFlat.new()
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 14
	card_style.content_margin_bottom = 14

	if is_unlocked:
		card_style.bg_color = Color(0.08, 0.13, 0.2, 0.9)
		card_style.border_color = Color(0.0, 0.85, 1.0, 0.4) if stars > 0 else Color(0.2, 0.4, 0.6, 0.3)
		card_style.set_border_width_all(1)
		card.add_theme_stylebox_override("normal", card_style)

		var hover_style := card_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0.12, 0.2, 0.32, 0.95)
		hover_style.border_color = Color(0.0, 1.0, 0.85, 0.8)
		card.add_theme_stylebox_override("hover", hover_style)
	else:
		card_style.bg_color = COLOR_LOCKED
		card_style.border_color = Color(0.2, 0.25, 0.3, 0.2)
		card_style.set_border_width_all(1)
		card.add_theme_stylebox_override("normal", card_style)
		card.disabled = true

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	if is_unlocked:
		var num_lbl := Label.new()
		num_lbl.text = "LEVEL %d" % level_id
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 18)
		num_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		vbox.add_child(num_lbl)

		# Star symbols
		var star_str := ""
		for s in range(3):
			star_str += "★ " if s < stars else "☆ "
		var star_lbl := Label.new()
		star_lbl.text = star_str.strip_edges()
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.add_theme_font_size_override("font_size", 20)
		star_lbl.add_theme_color_override("font_color", COLOR_GOLD if stars > 0 else Color(0.4, 0.45, 0.55))
		vbox.add_child(star_lbl)

		var score_lbl := Label.new()
		score_lbl.text = "BEST: %d" % best_score if best_score > 0 else "NOT CLEARED"
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_lbl.add_theme_font_size_override("font_size", 12)
		score_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.8))
		vbox.add_child(score_lbl)
	else:
		var lock_icon := Label.new()
		lock_icon.text = "🔒"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_icon.add_theme_font_size_override("font_size", 28)
		vbox.add_child(lock_icon)

		var lock_lbl := Label.new()
		lock_lbl.text = "LEVEL %d" % level_id
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 14)
		lock_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.7))
		vbox.add_child(lock_lbl)

	card.pressed.connect(func():
		if is_unlocked:
			level_chosen.emit(level_id)
	)

	_grid_container.add_child(card)
