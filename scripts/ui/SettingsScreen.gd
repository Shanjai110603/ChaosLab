## SettingsScreen — Laboratory Audio, Graphics, and Gameplay Preferences.
## Configures SFX, Music, Haptic vibration, Screen Shake, Graphics Quality presets,
## and local save data reset.
class_name SettingsScreen
extends Control

signal closed()

var _btn_sfx: CheckButton = null
var _btn_music: CheckButton = null
var _btn_haptics: CheckButton = null
var _shake_slider: HSlider = null
var _shake_val_label: Label = null
var _quality_buttons: Dictionary = {}
var _confirm_reset_panel: PanelContainer = null

const COLOR_BG := Color(0.04, 0.06, 0.09, 0.98)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)


func _ready() -> void:
	custom_minimum_size = Vector2(1920, 1080)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_settings()


func _load_settings() -> void:
	if not get_node_or_null("/root/SaveManager"):
		return
	var s: Dictionary = SaveManager.data.get("settings", {})
	if _btn_sfx:
		_btn_sfx.set_pressed_no_signal(s.get("sfx_enabled", true))
	if _btn_music:
		_btn_music.set_pressed_no_signal(s.get("music_enabled", true))
	if _btn_haptics:
		_btn_haptics.set_pressed_no_signal(s.get("haptics_enabled", true))

	var quality: String = s.get("graphics_quality", "medium")
	_highlight_quality(quality)


func _build_ui() -> void:
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	var center_vbox := VBoxContainer.new()
	center_vbox.set_anchors_preset(Control.PRESET_CENTER)
	center_vbox.custom_minimum_size = Vector2(720, 780)
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 24)
	add_child(center_vbox)

	# Title
	var title := Label.new()
	title.text = "⚙️ SETTINGS & PREFERENCES"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", COLOR_CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_vbox.add_child(title)

	# Settings Panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 520)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.06, 0.09, 0.14, 0.95)
	p_style.border_width_bottom = 2
	p_style.border_width_top = 1
	p_style.border_width_left = 1
	p_style.border_width_right = 1
	p_style.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.35)
	p_style.corner_radius_top_left = 12
	p_style.corner_radius_top_right = 12
	p_style.corner_radius_bottom_left = 12
	p_style.corner_radius_bottom_right = 12
	p_style.content_margin_left = 32
	p_style.content_margin_right = 32
	p_style.content_margin_top = 28
	p_style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", p_style)
	center_vbox.add_child(panel)

	var v_items := VBoxContainer.new()
	v_items.add_theme_constant_override("separation", 20)
	panel.add_child(v_items)

	# 1. SFX Toggle
	var h_sfx := HBoxContainer.new()
	v_items.add_child(h_sfx)
	var lbl_sfx := Label.new()
	lbl_sfx.text = "🔊 Sound Effects (SFX)"
	lbl_sfx.add_theme_font_size_override("font_size", 16)
	lbl_sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_sfx.add_child(lbl_sfx)
	_btn_sfx = CheckButton.new()
	_btn_sfx.focus_mode = Control.FOCUS_NONE
	_btn_sfx.toggled.connect(func(on: bool):
		if get_node_or_null("/root/SaveManager"):
			SaveManager.set_setting("sfx_enabled", on)
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
	)
	h_sfx.add_child(_btn_sfx)

	# 2. Music Toggle
	var h_mus := HBoxContainer.new()
	v_items.add_child(h_mus)
	var lbl_mus := Label.new()
	lbl_mus.text = "🎵 Laboratory Music"
	lbl_mus.add_theme_font_size_override("font_size", 16)
	lbl_mus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_mus.add_child(lbl_mus)
	_btn_music = CheckButton.new()
	_btn_music.focus_mode = Control.FOCUS_NONE
	_btn_music.toggled.connect(func(on: bool):
		if get_node_or_null("/root/SaveManager"):
			SaveManager.set_setting("music_enabled", on)
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
	)
	h_mus.add_child(_btn_music)

	# 3. Haptics (Vibration)
	var h_hap := HBoxContainer.new()
	v_items.add_child(h_hap)
	var lbl_hap := Label.new()
	lbl_hap.text = "📳 Haptic Feedback (Touch / Collisions)"
	lbl_hap.add_theme_font_size_override("font_size", 16)
	lbl_hap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_hap.add_child(lbl_hap)
	_btn_haptics = CheckButton.new()
	_btn_haptics.focus_mode = Control.FOCUS_NONE
	_btn_haptics.toggled.connect(func(on: bool):
		if get_node_or_null("/root/SaveManager"):
			SaveManager.set_setting("haptics_enabled", on)
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
	)
	h_hap.add_child(_btn_haptics)

	# 4. Graphics Quality Preset
	var h_qual := HBoxContainer.new()
	v_items.add_child(h_qual)
	var lbl_qual := Label.new()
	lbl_qual.text = "✨ Graphics Quality"
	lbl_qual.add_theme_font_size_override("font_size", 16)
	lbl_qual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_qual.add_child(lbl_qual)

	var q_box := HBoxContainer.new()
	q_box.add_theme_constant_override("separation", 6)
	h_qual.add_child(q_box)

	var presets := ["low", "medium", "high", "ultra"]
	for p in presets:
		var q_btn := Button.new()
		q_btn.text = p.to_upper()
		q_btn.custom_minimum_size = Vector2(62, 34)
		q_btn.focus_mode = Control.FOCUS_NONE
		q_btn.add_theme_font_size_override("font_size", 11)
		q_btn.pressed.connect(func():
			_set_quality(p)
		)
		q_box.add_child(q_btn)
		_quality_buttons[p] = q_btn

	# Separator
	var sep := HSeparator.new()
	v_items.add_child(sep)

	# 5. Data Management (Reset progress)
	var h_reset := HBoxContainer.new()
	v_items.add_child(h_reset)
	var lbl_data := Label.new()
	lbl_data.text = "🗑️ Local Save Data"
	lbl_data.add_theme_font_size_override("font_size", 16)
	lbl_data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_reset.add_child(lbl_data)

	var btn_clear := Button.new()
	btn_clear.text = "RESET PROGRESS"
	btn_clear.custom_minimum_size = Vector2(160, 36)
	btn_clear.focus_mode = Control.FOCUS_NONE
	btn_clear.add_theme_font_size_override("font_size", 12)
	btn_clear.pressed.connect(func():
		_confirm_reset_panel.visible = true
	)
	h_reset.add_child(btn_clear)

	# Confirmation Sub-panel (hidden by default)
	_confirm_reset_panel = PanelContainer.new()
	_confirm_reset_panel.visible = false
	var c_style := StyleBoxFlat.new()
	c_style.bg_color = Color(0.25, 0.08, 0.08, 0.98)
	c_style.border_width_bottom = 2
	c_style.border_color = Color(1.0, 0.3, 0.3)
	c_style.content_margin_left = 16
	c_style.content_margin_right = 16
	c_style.content_margin_top = 10
	c_style.content_margin_bottom = 10
	_confirm_reset_panel.add_theme_stylebox_override("panel", c_style)
	v_items.add_child(_confirm_reset_panel)

	var c_h := HBoxContainer.new()
	_confirm_reset_panel.add_child(c_h)
	var c_warn := Label.new()
	c_warn.text = "Reset all stars, coins, and campaign progress?"
	c_warn.add_theme_font_size_override("font_size", 12)
	c_warn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_h.add_child(c_warn)

	var btn_yes := Button.new()
	btn_yes.text = "CONFIRM"
	btn_yes.focus_mode = Control.FOCUS_NONE
	btn_yes.pressed.connect(func():
		if get_node_or_null("/root/SaveManager"):
			SaveManager.reset_data()
		_confirm_reset_panel.visible = false
	)
	c_h.add_child(btn_yes)

	var btn_no := Button.new()
	btn_no.text = "CANCEL"
	btn_no.focus_mode = Control.FOCUS_NONE
	btn_no.pressed.connect(func():
		_confirm_reset_panel.visible = false
	)
	c_h.add_child(btn_no)

	# Bottom Back Button
	var btn_back := Button.new()
	btn_back.text = "←  MAIN MENU"
	btn_back.custom_minimum_size = Vector2(260, 48)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_back.focus_mode = Control.FOCUS_NONE
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(func():
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_ui_click()
		closed.emit()
	)
	center_vbox.add_child(btn_back)


func _set_quality(p: String) -> void:
	if get_node_or_null("/root/SaveManager"):
		SaveManager.set_setting("graphics_quality", p)
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_ui_click()
	_highlight_quality(p)


func _highlight_quality(p: String) -> void:
	for q in _quality_buttons:
		var btn: Button = _quality_buttons[q]
		if q == p:
			btn.modulate = COLOR_CYAN
		else:
			btn.modulate = Color(0.6, 0.6, 0.6)
