## ChaosModeScreen — Endless procedural physics sandbox challenge interface.
## Generates procedural physics puzzle scenarios with random apparatus inventories,
## target constellations, and physics mutators.
class_name ChaosModeScreen
extends Control

signal closed()
signal start_chaos_requested(level_def: Dictionary)

var _current_scenario: Dictionary = {}
var _mutator_label: Label = null
var _desc_label: Label = null
var _inventory_label: Label = null
var _best_score_label: Label = null
var _best_chain_label: Label = null

const COLOR_BG := Color(0.04, 0.05, 0.09, 0.98)
const COLOR_PURPLE := Color(0.75, 0.35, 1.0)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)


func _ready() -> void:
	custom_minimum_size = Vector2(1920, 1080)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_generate_next()


func _generate_next() -> void:
	_current_scenario = ChaosGenerator.generate_chaos_scenario()
	_refresh_display()


func _refresh_display() -> void:
	if _mutator_label:
		_mutator_label.text = "⚡ MUTATOR: %s" % _current_scenario.get("mutator", "STANDARD")
	if _desc_label:
		_desc_label.text = _current_scenario.get("description", "")

	if _inventory_label:
		var inv: Dictionary = _current_scenario.get("inventory", {})
		var items: Array[String] = []
		for k in inv:
			items.append("%s ×%d" % [k, inv[k]])
		_inventory_label.text = "📦 APPARATUS GRANTED: %s" % ", ".join(items)

	if _best_score_label and get_node_or_null("/root/SaveManager"):
		var stats: Dictionary = SaveManager.data.get("stats", {})
		_best_score_label.text = "🏆 HIGH SCORE: %d" % stats.get("best_score", 0)
	if _best_chain_label and get_node_or_null("/root/SaveManager"):
		var stats: Dictionary = SaveManager.data.get("stats", {})
		_best_chain_label.text = "🔗 BEST CHAIN: ×%d" % stats.get("best_chain", 0)


func _build_ui() -> void:
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(800, 720)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = "⚡ CHAOS MODE"
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", COLOR_PURPLE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var subtitle := Label.new()
	subtitle.text = "Infinite procedural experiments. Random physics mutators."
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 0.75))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Stats Row
	var stats_h := HBoxContainer.new()
	stats_h.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_h.add_theme_constant_override("separation", 32)
	vbox.add_child(stats_h)

	_best_score_label = Label.new()
	_best_score_label.text = "🏆 HIGH SCORE: 0"
	_best_score_label.add_theme_font_size_override("font_size", 14)
	_best_score_label.add_theme_color_override("font_color", COLOR_GOLD)
	stats_h.add_child(_best_score_label)

	_best_chain_label = Label.new()
	_best_chain_label.text = "🔗 BEST CHAIN: ×0"
	_best_chain_label.add_theme_font_size_override("font_size", 14)
	_best_chain_label.add_theme_color_override("font_color", COLOR_CYAN)
	stats_h.add_child(_best_chain_label)

	# Mission Briefing Card
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(760, 220)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.12, 0.2, 0.95)
	card_style.border_width_bottom = 2
	card_style.border_width_top = 2
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_color = COLOR_PURPLE
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 32
	card_style.content_margin_right = 32
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	vbox.add_child(card)

	var card_v := VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 12)
	card.add_child(card_v)

	_mutator_label = Label.new()
	_mutator_label.text = "⚡ MUTATOR: HYPER RESTITUTION"
	_mutator_label.add_theme_font_size_override("font_size", 18)
	_mutator_label.add_theme_color_override("font_color", COLOR_PURPLE)
	card_v.add_child(_mutator_label)

	_desc_label = Label.new()
	_desc_label.text = "Mutator active: Physics bounce restitution increased to 1.4x."
	_desc_label.add_theme_font_size_override("font_size", 13)
	_desc_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_v.add_child(_desc_label)

	_inventory_label = Label.new()
	_inventory_label.text = "📦 APPARATUS: Ball x2, Bomb x1, Rocket x1, Barrel x1"
	_inventory_label.add_theme_font_size_override("font_size", 13)
	_inventory_label.add_theme_color_override("font_color", COLOR_CYAN)
	_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_v.add_child(_inventory_label)

	# Action Buttons
	var btn_v := VBoxContainer.new()
	btn_v.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_v)

	var btn_start := Button.new()
	btn_start.text = "▶  INITIATE EXPERIMENT"
	btn_start.custom_minimum_size = Vector2(360, 60)
	btn_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_start.add_theme_font_size_override("font_size", 18)
	btn_start.focus_mode = Control.FOCUS_NONE

	var start_style := StyleBoxFlat.new()
	start_style.bg_color = Color(0.25, 0.12, 0.38, 0.95)
	start_style.border_width_bottom = 3
	start_style.border_width_top = 1
	start_style.border_width_left = 1
	start_style.border_width_right = 1
	start_style.border_color = COLOR_PURPLE
	start_style.corner_radius_top_left = 10
	start_style.corner_radius_top_right = 10
	start_style.corner_radius_bottom_left = 10
	start_style.corner_radius_bottom_right = 10
	start_style.shadow_color = Color(COLOR_PURPLE, 0.3)
	start_style.shadow_size = 10
	btn_start.add_theme_stylebox_override("normal", start_style)

	btn_start.pressed.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
		start_chaos_requested.emit(_current_scenario)
	)
	btn_v.add_child(btn_start)

	var btn_reroll := Button.new()
	btn_reroll.text = "🎲 REROLL SCENARIO"
	btn_reroll.custom_minimum_size = Vector2(240, 42)
	btn_reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_reroll.focus_mode = Control.FOCUS_NONE
	btn_reroll.pressed.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
		_generate_next()
	)
	btn_v.add_child(btn_reroll)

	var btn_back := Button.new()
	btn_back.text = "←  MAIN MENU"
	btn_back.custom_minimum_size = Vector2(200, 38)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_back.focus_mode = Control.FOCUS_NONE
	btn_back.pressed.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
		closed.emit()
	)
	btn_v.add_child(btn_back)


func _show_screen() -> void:
	visible = true
	_generate_next()
