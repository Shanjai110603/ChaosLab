## LabHubScreen — The Laboratory Facility Sector Restoration Meta-Space.
## Visualizes Dr. Nova's research facility across all 10 World Sectors,
## showing sector restoration status, star progress, upgrade level, and Dr. Nova's Lost Audio Logs.
class_name LabHubScreen
extends Control

signal closed()

var _coins_label: Label = null
var _stars_label: Label = null
var _lab_level_label: Label = null
var _audio_log_panel: PanelContainer = null
var _log_title_label: Label = null
var _log_content_label: Label = null

const COLOR_BG := Color(0.04, 0.06, 0.09, 0.98)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_PURPLE := Color(0.75, 0.35, 1.0)

const SECTORS_DATA: Array[Dictionary] = [
	{
		"world": 1,
		"name": "THE MECHANICS SECTOR",
		"desc": "Primary kinetic testing chamber. Ordinary physical interaction and chain reactions.",
		"mechanic": "Ballistics & Collision",
		"icon": "[01]",
		"log": "Log #01: The Core reacts to momentum! Roll a ball into a barrel, and the output energy triples. I must keep testing."
	},
	{
		"world": 2,
		"name": "KINETIC BALLISTICS BAY",
		"desc": "Angular deflection corridors and high-velocity incline ramps.",
		"mechanic": "Ramps & Friction",
		"icon": "[02]",
		"log": "Log #14: Angles matter. A 45-degree slope yields maximum kinetic transfer. Note: Don't stand at the bottom of the ramp."
	},
	{
		"world": 3,
		"name": "DEMOLITION & EXPLOSIVES",
		"desc": "Reinforced blast containment chamber for explosive chains.",
		"mechanic": "Chained Detonations",
		"icon": "[03]",
		"log": "Log #27: Everything exploded again. Progress! A single bomb triggered five barrels across the hall."
	},
	{
		"world": 4,
		"name": "MAGNETIC RESONANCE LAB",
		"desc": "High-gauss polarized magnetic fields and electromagnetic switches.",
		"mechanic": "Attraction & Repulsion",
		"icon": "[04]",
		"log": "Log #39: The magnets don't just pull steel—they bend the Core's local field lines. Fascinating."
	},
	{
		"world": 5,
		"name": "PNEUMATIC WIND TUNNEL",
		"desc": "Continuous airflow turbines and pressurized aerodynamic chutes.",
		"mechanic": "Vector Airflow",
		"icon": "[05]",
		"log": "Log #48: You don't always have to touch an object to move it. The wind turbine blew my coffee cup through the portal."
	},
	{
		"world": 6,
		"name": "ELEMENTAL REACTION VAT",
		"desc": "Thermal crystallization vats. Fire melts ice; ice reduces friction to zero.",
		"mechanic": "Thermal Dynamics",
		"icon": "[06]",
		"log": "Log #56: Friction is a suggestion here. Objects glide across frozen platforms with zero resistance."
	},
	{
		"world": 7,
		"name": "ENERGY & TESLA GRID",
		"desc": "High-voltage conductive wire circuits and laser relay arrays.",
		"mechanic": "Laser & Circuitry",
		"icon": "[07]",
		"log": "Log #69: Energy relays online. Laser beams reflect off mirrored prisms. Wear protective goggles at all times."
	},
	{
		"world": 8,
		"name": "SPATIAL PORTAL NEXUS",
		"desc": "Einstein-Rosen gateway conduits preserving absolute velocity.",
		"mechanic": "Quantum Portals",
		"icon": "[08]",
		"log": "Log #81: The portals preserve momentum! Drop a bomb in one end, it shoots out the other like a cannon."
	},
	{
		"world": 9,
		"name": "GRAVITATIONAL WELL",
		"desc": "Localized anti-gravity fields and orbital deflection pads.",
		"mechanic": "Gravitational Inversion",
		"icon": "[09]",
		"log": "Log #92: Up is down, down is sideways. Gravity is completely pliable under the Core's influence."
	},
	{
		"world": 10,
		"name": "CHAOS CORE SINGULARITY",
		"desc": "The central nexus. The culmination of all combined physical systems.",
		"mechanic": "Omniverse Collider",
		"icon": "[10]",
		"log": "Log #100: The Core does not create chaos. It AMPLIFIES interactions. Whoever controls this controls the future."
	}
]


func _ready() -> void:
	custom_minimum_size = Vector2(1920, 1080)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_display()
	# Apply spring-physics micro-animations to all buttons
	UIAnimations.setup_all_buttons(self)


func _refresh_display() -> void:
	if _coins_label and get_node_or_null("/root/SaveManager"):
		_coins_label.text = "COINS: %d" % SaveManager.get_coins()
	if _stars_label and get_node_or_null("/root/SaveManager"):
		_stars_label.text = "STARS: %d / 300" % SaveManager.get_total_stars()
	if _lab_level_label and get_node_or_null("/root/SaveManager"):
		var total_stars: int = SaveManager.get_total_stars()
		var level: int = maxi(1, int(total_stars / 10) + 1)
		_lab_level_label.text = "FACILITY LVL %d" % level


func _build_ui() -> void:
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	# --- TOP BAR ---
	var top_panel := PanelContainer.new()
	top_panel.custom_minimum_size.y = 68
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.06, 0.09, 0.14, 0.95)
	top_style.border_width_bottom = 1
	top_style.border_color = Color(0.2, 0.4, 0.65, 0.4)
	top_style.content_margin_left = 32
	top_style.content_margin_right = 32
	top_panel.add_theme_stylebox_override("panel", top_style)
	vbox.add_child(top_panel)

	var top_h := HBoxContainer.new()
	top_panel.add_child(top_h)

	var back_btn := Button.new()
	back_btn.text = "BACK TO MENU"
	back_btn.custom_minimum_size = Vector2(160, 42)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
		closed.emit()
	)
	top_h.add_child(back_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(spacer)

	var title := Label.new()
	title.text = "RESEARCH FACILITY // SECTOR RESTORATION"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_CYAN)
	top_h.add_child(title)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(spacer2)

	_lab_level_label = Label.new()
	_lab_level_label.text = "FACILITY LVL 1"
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

	# --- SECTORS SCROLL CONTAINER ---
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1800, 880)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content_box := VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 18)
	scroll.add_child(content_box)

	# Audio Log Floating Popup Banner (Initially hidden)
	_audio_log_panel = PanelContainer.new()
	_audio_log_panel.custom_minimum_size = Vector2(1740, 100)
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = Color(0.06, 0.12, 0.22, 0.95)
	log_style.border_width_left = 3
	log_style.border_width_top = 1
	log_style.border_width_right = 1
	log_style.border_width_bottom = 1
	log_style.border_color = COLOR_CYAN
	log_style.corner_radius_top_left = 8
	log_style.corner_radius_top_right = 8
	log_style.corner_radius_bottom_left = 8
	log_style.corner_radius_bottom_right = 8
	log_style.content_margin_left = 24
	log_style.content_margin_right = 24
	log_style.content_margin_top = 12
	log_style.content_margin_bottom = 12
	_audio_log_panel.add_theme_stylebox_override("panel", log_style)
	_audio_log_panel.visible = false
	content_box.add_child(_audio_log_panel)

	var log_v := VBoxContainer.new()
	_audio_log_panel.add_child(log_v)

	_log_title_label = Label.new()
	_log_title_label.text = "DR. NOVA'S AUDIO LOG"
	_log_title_label.add_theme_font_size_override("font_size", 13)
	_log_title_label.add_theme_color_override("font_color", COLOR_CYAN)
	log_v.add_child(_log_title_label)

	_log_content_label = Label.new()
	_log_content_label.text = ""
	_log_content_label.add_theme_font_size_override("font_size", 14)
	_log_content_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_log_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_v.add_child(_log_content_label)

	# 10 World Sector Cards Grid
	var sectors_grid := GridContainer.new()
	sectors_grid.columns = 2
	sectors_grid.add_theme_constant_override("h_separation", 24)
	sectors_grid.add_theme_constant_override("v_separation", 18)
	content_box.add_child(sectors_grid)

	for sector in SECTORS_DATA:
		var card := _create_sector_card(sector)
		sectors_grid.add_child(card)


func _create_sector_card(data: Dictionary) -> PanelContainer:
	var world_id: int = data.get("world", 1)
	var world_stars: int = 0
	if get_node_or_null("/root/SaveManager"):
		world_stars = SaveManager.get_world_stars(world_id)

	var is_unlocked: bool = (world_id == 1) or (world_stars > 0)
	if get_node_or_null("/root/SaveManager"):
		is_unlocked = SaveManager.is_world_unlocked(world_id)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(850, 150)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.09, 0.14, 0.92) if is_unlocked else Color(0.04, 0.05, 0.08, 0.6)
	card_style.border_width_bottom = 2
	card_style.border_width_top = 1
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.4) if is_unlocked else Color(0.2, 0.25, 0.3, 0.4)
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.corner_radius_bottom_right = 10
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 14
	card_style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", card_style)

	var h_box := HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 18)
	card.add_child(h_box)

	# Icon
	var icon_lbl := Label.new()
	icon_lbl.text = "[%02d]" % world_id
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.add_theme_color_override("font_color", COLOR_CYAN if is_unlocked else Color(0.4, 0.45, 0.5))
	h_box.add_child(icon_lbl)

	# Info
	var v_info := VBoxContainer.new()
	v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_info.add_theme_constant_override("separation", 3)
	h_box.add_child(v_info)

	var title_lbl := Label.new()
	title_lbl.text = "SECTOR %02d: %s" % [world_id, data.get("name", "")]
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", COLOR_CYAN if is_unlocked else Color(0.5, 0.55, 0.6))
	v_info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.8) if is_unlocked else Color(0.4, 0.45, 0.5))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v_info.add_child(desc_lbl)

	var status_h := HBoxContainer.new()
	v_info.add_child(status_h)

	var stars_lbl := Label.new()
	stars_lbl.text = "STARS: %d / 30" % world_stars
	stars_lbl.add_theme_font_size_override("font_size", 12)
	stars_lbl.add_theme_color_override("font_color", COLOR_GOLD if is_unlocked else Color(0.4, 0.45, 0.5))
	status_h.add_child(stars_lbl)

	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 16
	status_h.add_child(sep)

	var mech_lbl := Label.new()
	mech_lbl.text = "System: %s" % data.get("mechanic", "")
	mech_lbl.add_theme_font_size_override("font_size", 12)
	mech_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.75) if is_unlocked else Color(0.4, 0.45, 0.5))
	status_h.add_child(mech_lbl)

	# Action: Audio Log Button
	if is_unlocked:
		var log_btn := Button.new()
		log_btn.text = "PLAY LOG"
		log_btn.custom_minimum_size = Vector2(100, 36)
		log_btn.focus_mode = Control.FOCUS_NONE
		log_btn.add_theme_font_size_override("font_size", 11)
		log_btn.pressed.connect(func():
			_show_audio_log(data.get("name", ""), data.get("log", ""))
		)
		h_box.add_child(log_btn)
	else:
		var lock_lbl := Label.new()
		lock_lbl.text = "[ LOCKED ]"
		lock_lbl.add_theme_font_size_override("font_size", 12)
		lock_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		h_box.add_child(lock_lbl)

	return card


func _show_audio_log(sector_name: String, log_text: String) -> void:
	if _audio_log_panel:
		_audio_log_panel.visible = true
		if _log_title_label:
			_log_title_label.text = "DR. NOVA'S LOG // %s" % sector_name
		if _log_content_label:
			_log_content_label.text = '"%s"' % log_text
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_ui_click()
