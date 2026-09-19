## MainMenuScreen — The primary title screen and game portal for Chaos Lab.
## Features animated reactor ambiance, high-tech particle grid, currency display,
## and entry points to Campaign, Chaos Mode, Daily Chaos, The Lab Hub, Shop, Achievements, and Settings.
class_name MainMenuScreen
extends Control

signal play_campaign_requested()
signal chaos_mode_requested()
signal daily_requested()
signal lab_hub_requested()
signal shop_requested()
signal achievements_requested()
signal settings_requested()
signal exit_requested()

var _anim_time: float = 0.0
var _pulse: float = 0.0

var _coins_label: Label = null
var _stars_label: Label = null
var _lab_level_label: Label = null
var _btn_play: Button = null

const COLOR_BG := Color(0.03, 0.05, 0.09, 1.0)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_NEON_GREEN := Color(0.15, 0.95, 0.45)
const COLOR_PURPLE := Color(0.75, 0.35, 1.0)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)


func _ready() -> void:
	custom_minimum_size = Vector2(1920, 1080)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_data()
	set_process(true)
	# Apply spring-physics micro-animations to all buttons
	UIAnimations.setup_all_buttons(self)


func _process(delta: float) -> void:
	_anim_time += delta
	_pulse = (sin(_anim_time * 2.8) * 0.5 + 0.5)
	queue_redraw()

	if _btn_play:
		var style := _btn_play.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			style.shadow_color = Color(COLOR_NEON_GREEN.r, COLOR_NEON_GREEN.g, COLOR_NEON_GREEN.b, 0.3 + _pulse * 0.3)
			style.shadow_size = int(12 + _pulse * 8)


func _refresh_data() -> void:
	if _coins_label and get_node_or_null("/root/SaveManager"):
		_coins_label.text = "COINS: %d" % SaveManager.get_coins()
	if _stars_label and get_node_or_null("/root/SaveManager"):
		_stars_label.text = "STARS: %d / 300" % SaveManager.get_total_stars()
	if _lab_level_label and get_node_or_null("/root/SaveManager"):
		var stars: int = SaveManager.get_total_stars()
		var lab_lvl: int = maxi(1, int(stars / 10) + 1)
		_lab_level_label.text = "LAB SECTOR: LVL %d" % lab_lvl


func _draw() -> void:
	var w := size.x if size.x > 0 else 1920.0
	var h := size.y if size.y > 0 else 1080.0

	# 1. Base Laboratory Background
	draw_rect(Rect2(0, 0, w, h), COLOR_BG)

	# 2. Glowing Ambient Lab Reactor Grid
	var grid_step := 80.0
	var center := Vector2(w * 0.5, h * 0.48)

	# Radial reactor background glow
	var glow_radius: float = 480.0 + _pulse * 40.0
	var glow_col := Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.07 + _pulse * 0.04)
	draw_circle(center, glow_radius, glow_col)
	draw_circle(center, glow_radius * 0.5, Color(COLOR_PURPLE.r, COLOR_PURPLE.g, COLOR_PURPLE.b, 0.05 + _pulse * 0.03))

	# Dynamic grid lines
	var gx := 0.0
	while gx <= w:
		var alpha: float = 0.08 + (0.05 * sin(gx * 0.01 + _anim_time))
		draw_line(Vector2(gx, 0), Vector2(gx, h), Color(0.1, 0.3, 0.55, alpha), 1.0)
		gx += grid_step

	var gy := 0.0
	while gy <= h:
		var alpha: float = 0.08 + (0.05 * cos(gy * 0.01 + _anim_time))
		draw_line(Vector2(0, gy), Vector2(w, gy), Color(0.1, 0.3, 0.55, alpha), 1.0)
		gy += grid_step

	# 3. Floating Kinetic Spark Atoms
	for i in range(12):
		var ang: float = _anim_time * 0.8 + (i * PI * 2.0 / 12.0)
		var rad: float = 240.0 + sin(_anim_time * 1.5 + i) * 60.0
		var pos := center + Vector2(cos(ang), sin(ang) * 0.6) * rad
		var spark_col := COLOR_CYAN if (i % 2 == 0) else COLOR_PURPLE
		draw_circle(pos, 3.5, Color(spark_col, 0.75))
		draw_circle(pos, 8.0, Color(spark_col, 0.25))


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# --- TOP HEADER BAR: CURRENCIES & META ---
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 68

	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.04, 0.07, 0.12, 0.85)
	top_style.border_width_bottom = 1
	top_style.border_color = Color(0.15, 0.35, 0.6, 0.4)
	top_style.content_margin_left = 36
	top_style.content_margin_right = 36
	top_bar.add_theme_stylebox_override("panel", top_style)
	root.add_child(top_bar)

	var top_h := HBoxContainer.new()
	top_h.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(top_h)

	var brand_pill := Label.new()
	brand_pill.text = "RESEARCH SECTOR 01"
	brand_pill.add_theme_font_size_override("font_size", 13)
	brand_pill.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.8))
	top_h.add_child(brand_pill)

	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(sp1)

	_lab_level_label = Label.new()
	_lab_level_label.text = "LAB SECTOR: LVL 1"
	_lab_level_label.add_theme_font_size_override("font_size", 14)
	_lab_level_label.add_theme_color_override("font_color", COLOR_CYAN)
	top_h.add_child(_lab_level_label)

	var sep1 := VSeparator.new()
	sep1.custom_minimum_size.x = 24
	top_h.add_child(sep1)

	_stars_label = Label.new()
	_stars_label.text = "STARS: 0 / 300"
	_stars_label.add_theme_font_size_override("font_size", 14)
	_stars_label.add_theme_color_override("font_color", COLOR_GOLD)
	top_h.add_child(_stars_label)

	var sep2 := VSeparator.new()
	sep2.custom_minimum_size.x = 24
	top_h.add_child(sep2)

	_coins_label = Label.new()
	_coins_label.text = "COINS: 0"
	_coins_label.add_theme_font_size_override("font_size", 14)
	_coins_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	top_h.add_child(_coins_label)

	# --- MAIN CENTER HERO BOX ---
	var center_box := VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.custom_minimum_size = Vector2(680, 500)
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 10)
	root.add_child(center_box)

	# Title & Tagline
	var title_lbl := Label.new()
	title_lbl.text = "CHAOS LAB"
	title_lbl.add_theme_font_size_override("font_size", 60)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", COLOR_CYAN)
	title_lbl.add_theme_constant_override("shadow_offset_x", 0)
	title_lbl.add_theme_constant_override("shadow_offset_y", 4)
	title_lbl.add_theme_constant_override("shadow_outline_size", 16)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(title_lbl)

	var tag_lbl := Label.new()
	tag_lbl.text = "BUILD IT • TRIGGER IT • CAUSE CHAOS"
	tag_lbl.add_theme_font_size_override("font_size", 14)
	tag_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(tag_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "One experiment. Infinite possibilities."
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9, 0.7))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	center_box.add_child(spacer)

	# --- HERO BUTTON: PLAY CAMPAIGN ---
	_btn_play = Button.new()
	_btn_play.text = "PLAY CAMPAIGN"
	_btn_play.custom_minimum_size = Vector2(440, 58)
	_btn_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn_play.add_theme_font_size_override("font_size", 20)
	_btn_play.focus_mode = Control.FOCUS_NONE

	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.08, 0.28, 0.16, 0.95)
	play_style.border_width_bottom = 3
	play_style.border_width_top = 3
	play_style.border_width_left = 3
	play_style.border_width_right = 3
	play_style.border_color = COLOR_NEON_GREEN
	play_style.corner_radius_top_left = 12
	play_style.corner_radius_top_right = 12
	play_style.corner_radius_bottom_left = 12
	play_style.corner_radius_bottom_right = 12
	play_style.shadow_color = Color(COLOR_NEON_GREEN, 0.4)
	play_style.shadow_size = 12
	_btn_play.add_theme_stylebox_override("normal", play_style)

	var play_hov := play_style.duplicate() as StyleBoxFlat
	play_hov.bg_color = Color(0.12, 0.4, 0.22, 1.0)
	_btn_play.add_theme_stylebox_override("hover", play_hov)
	_btn_play.pressed.connect(func():
		_on_btn_click()
		play_campaign_requested.emit()
	)
	center_box.add_child(_btn_play)

	# --- SECONDARY BUTTONS GRID ---
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.add_child(grid)

	# 1. Chaos Mode (Endless Sandbox)
	var btn_chaos := _create_menu_button("CHAOS MODE", COLOR_PURPLE, Vector2(215, 46))
	btn_chaos.pressed.connect(func():
		_on_btn_click()
		chaos_mode_requested.emit()
	)
	grid.add_child(btn_chaos)

	# 2. Daily Experiment
	var btn_daily := _create_menu_button("DAILY EXPERIMENT", Color(0.95, 0.5, 0.2), Vector2(215, 46))
	btn_daily.pressed.connect(func():
		_on_btn_click()
		daily_requested.emit()
	)
	grid.add_child(btn_daily)

	# 3. The Lab (Hub)
	var btn_hub := _create_menu_button("THE LAB (HUB)", COLOR_CYAN, Vector2(215, 46))
	btn_hub.pressed.connect(func():
		_on_btn_click()
		lab_hub_requested.emit()
	)
	grid.add_child(btn_hub)

	# 4. Lab Shop
	var btn_shop := _create_menu_button("ARMORY SHOP", COLOR_GOLD, Vector2(215, 46))
	btn_shop.pressed.connect(func():
		_on_btn_click()
		shop_requested.emit()
	)
	grid.add_child(btn_shop)

	# 5. Achievements
	var btn_ach := _create_menu_button("ACHIEVEMENTS", Color(0.4, 0.75, 1.0), Vector2(215, 46))
	btn_ach.pressed.connect(func():
		_on_btn_click()
		achievements_requested.emit()
	)
	grid.add_child(btn_ach)

	# 6. Settings
	var btn_set := _create_menu_button("SETTINGS", Color(0.7, 0.75, 0.85), Vector2(215, 46))
	btn_set.pressed.connect(func():
		_on_btn_click()
		settings_requested.emit()
	)
	grid.add_child(btn_set)

	# --- FOOTER / VERSION / PLATFORM ---
	var footer_h := HBoxContainer.new()
	footer_h.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_child(footer_h)

	var ver_lbl := Label.new()
	ver_lbl.text = "CHAOS LAB v1.0.0 • PRODUCTION RELEASE • GODOT 4.7"
	ver_lbl.add_theme_font_size_override("font_size", 11)
	ver_lbl.add_theme_color_override("font_color", Color(0.4, 0.55, 0.7, 0.6))
	footer_h.add_child(ver_lbl)

	if OS.has_feature("pc") and not OS.has_feature("web"):
		var quit_sep := VSeparator.new()
		quit_sep.custom_minimum_size.x = 20
		footer_h.add_child(quit_sep)

		var btn_exit := Button.new()
		btn_exit.text = "EXIT LAB"
		btn_exit.focus_mode = Control.FOCUS_NONE
		btn_exit.add_theme_font_size_override("font_size", 11)
		btn_exit.pressed.connect(func():
			_on_btn_click()
			exit_requested.emit()
		)
		footer_h.add_child(btn_exit)


func _create_menu_button(title: String, accent: Color, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 14)
	btn.focus_mode = Control.FOCUS_NONE

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.1, 0.16, 0.9)
	normal.border_width_bottom = 2
	normal.border_width_top = 1
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.95)
	hover.border_color = accent
	hover.shadow_color = Color(accent, 0.3)
	hover.shadow_size = 6
	btn.add_theme_stylebox_override("hover", hover)
	return btn


func _on_btn_click() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_ui_click()


func show_menu() -> void:
	visible = true
	_refresh_data()


func hide_menu() -> void:
	visible = false
