## LevelSelectScreen — World and Level selection menu.
## Displays world tabs, level cards with stars, high scores, and lock states.
class_name LevelSelectScreen
extends Control

signal level_chosen(level_id: int)
signal back_to_menu_requested()
signal shop_requested()
signal daily_requested()
signal achievements_requested()

var current_world: int = 1
const MAX_WORLDS: int = 10

const WORLD_NAMES: Array[String] = [
	"THE MECHANICS LAB",
	"KINETIC BALLISTICS",
	"CHAIN CATALYST",
	"PRECISION ANGLES",
	"STRUCTURAL DEMOLITION",
	"VOLATILE MOMENTUM",
	"HAZARD CONTROL",
	"ROCKET GUIDANCE",
	"CHAOS CHAMBER",
	"THE OMNIVERSE COLLIDER",
]

var _grid_container: GridContainer = null
var _stars_label: Label = null
var _coins_label: Label = null
var _world_title_label: Label = null
var _world_stars_label: Label = null
var _btn_prev_world: Button = null
var _btn_next_world: Button = null

const COLOR_BG := Color(0.04, 0.06, 0.09, 0.96)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_LOCKED := Color(0.2, 0.25, 0.32, 0.6)


func _ready() -> void:
	_create_ui()
	_refresh_display()
	# Apply spring-physics micro-animations to all buttons
	UIAnimations.setup_all_buttons(self)


func _create_ui() -> void:
	custom_minimum_size = Vector2(1920, 1080)
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
	back_btn.text = "← BACK TO LAB"
	back_btn.custom_minimum_size = Vector2(140, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		back_to_menu_requested.emit()
	)
	top_bar.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "EXPERIMENT SELECTION"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Total Stars pill
	_stars_label = Label.new()
	_stars_label.text = "STARS: 0 / 300"
	_stars_label.add_theme_font_size_override("font_size", 16)
	_stars_label.add_theme_color_override("font_color", COLOR_GOLD)
	top_bar.add_child(_stars_label)

	# Coins pill
	_coins_label = Label.new()
	_coins_label.text = "COINS: 0"
	_coins_label.add_theme_font_size_override("font_size", 16)
	_coins_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	top_bar.add_child(_coins_label)

	# Shop Button
	var shop_btn := Button.new()
	shop_btn.text = "ARMORY"
	shop_btn.custom_minimum_size = Vector2(110, 44)
	shop_btn.add_theme_font_size_override("font_size", 14)
	shop_btn.focus_mode = Control.FOCUS_NONE
	var shop_style := StyleBoxFlat.new()
	shop_style.bg_color = Color(0.12, 0.35, 0.55, 0.85)
	shop_style.border_color = COLOR_CYAN
	shop_style.set_border_width_all(1)
	shop_style.set_corner_radius_all(8)
	shop_btn.add_theme_stylebox_override("normal", shop_style)
	shop_btn.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		shop_requested.emit()
	)
	top_bar.add_child(shop_btn)

	# Daily Button
	var daily_btn := Button.new()
	daily_btn.text = "DAILY"
	daily_btn.custom_minimum_size = Vector2(100, 44)
	daily_btn.add_theme_font_size_override("font_size", 14)
	daily_btn.focus_mode = Control.FOCUS_NONE
	var daily_style := StyleBoxFlat.new()
	daily_style.bg_color = Color(0.35, 0.15, 0.05, 0.9)
	daily_style.border_color = Color(1.0, 0.45, 0.1)
	daily_style.set_border_width_all(1)
	daily_style.set_corner_radius_all(8)
	daily_btn.add_theme_stylebox_override("normal", daily_style)
	daily_btn.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		daily_requested.emit()
	)
	top_bar.add_child(daily_btn)

	# Trophies Button
	var ach_btn := Button.new()
	ach_btn.text = "AWARDS"
	ach_btn.custom_minimum_size = Vector2(110, 44)
	ach_btn.add_theme_font_size_override("font_size", 14)
	ach_btn.focus_mode = Control.FOCUS_NONE
	var ach_style := StyleBoxFlat.new()
	ach_style.bg_color = Color(0.28, 0.22, 0.05, 0.9)
	ach_style.border_color = COLOR_GOLD
	ach_style.set_border_width_all(1)
	ach_style.set_corner_radius_all(8)
	ach_btn.add_theme_stylebox_override("normal", ach_style)
	ach_btn.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		achievements_requested.emit()
	)
	top_bar.add_child(ach_btn)

	# World selector carousel
	var world_box := HBoxContainer.new()
	world_box.alignment = BoxContainer.ALIGNMENT_CENTER
	world_box.add_theme_constant_override("separation", 20)
	vbox.add_child(world_box)

	_btn_prev_world = Button.new()
	_btn_prev_world.text = "◀"
	_btn_prev_world.custom_minimum_size = Vector2(48, 48)
	_btn_prev_world.add_theme_font_size_override("font_size", 20)
	_btn_prev_world.focus_mode = Control.FOCUS_NONE
	_btn_prev_world.pressed.connect(func():
		if current_world > 1:
			_select_world(current_world - 1)
	)
	world_box.add_child(_btn_prev_world)

	var world_center_vbox := VBoxContainer.new()
	world_center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	world_box.add_child(world_center_vbox)

	_world_title_label = Label.new()
	_world_title_label.text = "WORLD 1: THE MECHANICS LAB"
	_world_title_label.add_theme_font_size_override("font_size", 18)
	_world_title_label.add_theme_color_override("font_color", COLOR_CYAN)
	_world_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_center_vbox.add_child(_world_title_label)

	_world_stars_label = Label.new()
	_world_stars_label.text = "STARS: 0 / 30"
	_world_stars_label.add_theme_font_size_override("font_size", 14)
	_world_stars_label.add_theme_color_override("font_color", COLOR_GOLD)
	_world_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_center_vbox.add_child(_world_stars_label)

	_btn_next_world = Button.new()
	_btn_next_world.text = "▶"
	_btn_next_world.custom_minimum_size = Vector2(48, 48)
	_btn_next_world.add_theme_font_size_override("font_size", 20)
	_btn_next_world.focus_mode = Control.FOCUS_NONE
	_btn_next_world.pressed.connect(func():
		if current_world < MAX_WORLDS:
			_select_world(current_world + 1)
	)
	world_box.add_child(_btn_next_world)

	# Grid Container for Level Cards (5 columns x 2 rows)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1760, 800)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	current_world = clampi(world, 1, MAX_WORLDS)
	AudioManager.play_ui_blip("select")
	_refresh_display()


func _refresh_display() -> void:
	# Update pills
	_stars_label.text = "STARS: %d / 300" % SaveManager.get_total_stars()
	_coins_label.text = "COINS: %d" % SaveManager.get_coins()

	# Update world title and stars
	var world_name: String = WORLD_NAMES[current_world - 1]
	_world_title_label.text = "WORLD %d: %s" % [current_world, world_name]
	var world_stars := SaveManager.get_world_stars(current_world)
	_world_stars_label.text = "STARS: %d / 30" % world_stars

	# Update arrow button states
	_btn_prev_world.disabled = (current_world <= 1)
	_btn_next_world.disabled = (current_world >= MAX_WORLDS)

	# Clear and rebuild level cards
	for child in _grid_container.get_children():
		child.queue_free()

	var start_id := (current_world - 1) * 10 + 1
	var end_id := start_id + 9

	for id in range(start_id, end_id + 1):
		_create_level_card(id)

	UIAnimations.animate_cards_in(_grid_container)
	UIAnimations.setup_all_buttons(_grid_container)


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

		# Procedural vector stars container
		var stars_row := HBoxContainer.new()
		stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_row.add_theme_constant_override("separation", 6)
		vbox.add_child(stars_row)

		var star_tex_path := "res://assets/sprites/ui/icon_star.png"
		var star_tex: Texture2D = load(star_tex_path) if ResourceLoader.exists(star_tex_path) else null

		for s in range(3):
			var earned: bool = (s < stars)
			if star_tex:
				var tr := TextureRect.new()
				tr.texture = star_tex
				tr.custom_minimum_size = Vector2(18, 18)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.modulate = COLOR_GOLD if earned else Color(0.25, 0.3, 0.4, 0.5)
				stars_row.add_child(tr)
			else:
				var star_box := Control.new()
				star_box.custom_minimum_size = Vector2(18, 18)
				star_box.draw.connect(func():
					var center := Vector2(9, 9)
					var radius: float = 8.0
					var inner: float = radius * 0.42
					var pts := PackedVector2Array()
					for i in range(10):
						var ang := -PI * 0.5 + i * (PI / 5.0)
						var r := radius if (i % 2 == 0) else inner
						pts.append(center + Vector2(cos(ang), sin(ang)) * r)
					if earned:
						star_box.draw_colored_polygon(pts, COLOR_GOLD)
						star_box.draw_polyline(pts, Color(1.0, 1.0, 0.6), 1.2, true)
					else:
						star_box.draw_polyline(pts, Color(0.3, 0.35, 0.45), 1.2, true)
				)
				stars_row.add_child(star_box)

		var score_lbl := Label.new()
		score_lbl.text = "BEST: %d" % best_score if best_score > 0 else "NOT CLEARED"
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_lbl.add_theme_font_size_override("font_size", 12)
		score_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.8))
		vbox.add_child(score_lbl)
	else:
		var lock_icon := Label.new()
		lock_icon.text = "[ LOCKED ]"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_icon.add_theme_font_size_override("font_size", 14)
		lock_icon.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
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
