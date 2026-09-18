## ShopScreen — Laboratory Armory and Customization Store.
## Allows players to spend coins to unlock and equip procedural skins and arena themes.
class_name ShopScreen
extends Control

signal closed()

var current_slot: String = CosmeticManager.SLOT_BOMB
var _coins_label: Label = null
var _tab_bombs: Button = null
var _tab_balls: Button = null
var _tab_themes: Button = null
var _cards_container: HBoxContainer = null

const COLOR_BG := Color(0.03, 0.05, 0.08, 0.98)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_GREEN := Color(0.2, 0.9, 0.4)


func _ready() -> void:
	_create_ui()
	_refresh_display()


func _create_ui() -> void:
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
	vbox.add_theme_constant_override("separation", 24)
	vbox.offset_left = 60
	vbox.offset_right = -60
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
	title_lbl.text = "LABORATORY ARMORY & SKINS"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Coins pill
	var coin_panel := PanelContainer.new()
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = Color(0.1, 0.14, 0.22, 0.8)
	coin_style.corner_radius_top_left = 16
	coin_style.corner_radius_top_right = 16
	coin_style.corner_radius_bottom_left = 16
	coin_style.corner_radius_bottom_right = 16
	coin_style.content_margin_left = 18
	coin_style.content_margin_right = 18
	coin_style.content_margin_top = 8
	coin_style.content_margin_bottom = 8
	coin_panel.add_theme_stylebox_override("panel", coin_style)

	_coins_label = Label.new()
	_coins_label.text = "🪙 0"
	_coins_label.add_theme_font_size_override("font_size", 20)
	_coins_label.add_theme_color_override("font_color", COLOR_GOLD)
	coin_panel.add_child(_coins_label)
	top_bar.add_child(coin_panel)

	# Category Tabs
	var tabs_box := HBoxContainer.new()
	tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_box.add_theme_constant_override("separation", 24)
	vbox.add_child(tabs_box)

	_tab_bombs = Button.new()
	_tab_bombs.text = "💣 BOMBS"
	_tab_bombs.custom_minimum_size = Vector2(220, 48)
	_tab_bombs.add_theme_font_size_override("font_size", 16)
	_tab_bombs.focus_mode = Control.FOCUS_NONE
	_tab_bombs.pressed.connect(func(): _select_category(CosmeticManager.SLOT_BOMB))
	tabs_box.add_child(_tab_bombs)

	_tab_balls = Button.new()
	_tab_balls.text = "⚽ SPHERES"
	_tab_balls.custom_minimum_size = Vector2(220, 48)
	_tab_balls.add_theme_font_size_override("font_size", 16)
	_tab_balls.focus_mode = Control.FOCUS_NONE
	_tab_balls.pressed.connect(func(): _select_category(CosmeticManager.SLOT_BALL))
	tabs_box.add_child(_tab_balls)

	_tab_themes = Button.new()
	_tab_themes.text = "🔬 ARENA THEMES"
	_tab_themes.custom_minimum_size = Vector2(220, 48)
	_tab_themes.add_theme_font_size_override("font_size", 16)
	_tab_themes.focus_mode = Control.FOCUS_NONE
	_tab_themes.pressed.connect(func(): _select_category(CosmeticManager.SLOT_THEME))
	tabs_box.add_child(_tab_themes)

	# Cards Container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_cards_container = HBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 24)
	scroll.add_child(_cards_container)


func _select_category(slot: String) -> void:
	current_slot = slot
	AudioManager.play_ui_blip("select")
	_refresh_display()


func _refresh_display() -> void:
	# Update coin label
	if _coins_label:
		_coins_label.text = "🪙 %d" % SaveManager.get_coins()

	# Highlight active tab
	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color(0.0, 0.45, 0.75, 0.85)
	active_style.border_color = COLOR_CYAN
	active_style.border_width_bottom = 3
	active_style.corner_radius_top_left = 8
	active_style.corner_radius_top_right = 8

	var inactive_style := StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.08, 0.12, 0.18, 0.6)
	inactive_style.corner_radius_top_left = 8
	inactive_style.corner_radius_top_right = 8

	_tab_bombs.add_theme_stylebox_override("normal", active_style if current_slot == CosmeticManager.SLOT_BOMB else inactive_style)
	_tab_balls.add_theme_stylebox_override("normal", active_style if current_slot == CosmeticManager.SLOT_BALL else inactive_style)
	_tab_themes.add_theme_stylebox_override("normal", active_style if current_slot == CosmeticManager.SLOT_THEME else inactive_style)

	# Clear and rebuild cards
	for child in _cards_container.get_children():
		child.queue_free()

	var catalog: Array = CosmeticManager.get_catalog(current_slot)
	var equipped_id: String = CosmeticManager.get_equipped(current_slot)
	var player_coins: int = SaveManager.get_coins()

	for item in catalog:
		var card := _create_skin_card(item, equipped_id, player_coins)
		_cards_container.add_child(card)


func _create_skin_card(item: Dictionary, equipped_id: String, player_coins: int) -> Control:
	var skin_id: String = item["id"]
	var is_unlocked: bool = CosmeticManager.is_unlocked(skin_id)
	var is_equipped: bool = (skin_id == equipped_id)
	var price: int = item.get("price", 0)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 420)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.09, 0.14, 0.95)
	card_style.corner_radius_top_left = 14
	card_style.corner_radius_top_right = 14
	card_style.corner_radius_bottom_left = 14
	card_style.corner_radius_bottom_right = 14
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18

	if is_equipped:
		card_style.border_color = COLOR_CYAN
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.border_width_top = 2
		card_style.border_width_bottom = 2
	else:
		card_style.border_color = Color(0.15, 0.22, 0.32, 0.6)
		card_style.border_width_left = 1
		card_style.border_width_right = 1
		card_style.border_width_top = 1
		card_style.border_width_bottom = 1

	card.add_theme_stylebox_override("panel", card_style)

	var cvbox := VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 14)
	card.add_child(cvbox)

	# Preview Drawing Canvas
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(220, 160)
	preview.draw.connect(_draw_preview.bind(preview, item))
	cvbox.add_child(preview)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = item.get("name", "Skin")
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = item.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(220, 50)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cvbox.add_child(spacer)

	# Action Button
	var act_btn := Button.new()
	act_btn.custom_minimum_size = Vector2(220, 44)
	act_btn.focus_mode = Control.FOCUS_NONE

	if is_equipped:
		act_btn.text = "✓ EQUIPPED"
		act_btn.disabled = true
		var eq_style := StyleBoxFlat.new()
		eq_style.bg_color = Color(0.0, 0.35, 0.5, 0.4)
		eq_style.border_color = COLOR_CYAN
		eq_style.border_width_left = 1
		eq_style.border_width_right = 1
		eq_style.border_width_top = 1
		eq_style.border_width_bottom = 1
		eq_style.corner_radius_top_left = 8
		eq_style.corner_radius_top_right = 8
		eq_style.corner_radius_bottom_left = 8
		eq_style.corner_radius_bottom_right = 8
		act_btn.add_theme_stylebox_override("disabled", eq_style)
		act_btn.add_theme_color_override("font_disabled_color", COLOR_CYAN)
	elif is_unlocked:
		act_btn.text = "EQUIP"
		act_btn.pressed.connect(func():
			CosmeticManager.equip_skin(current_slot, skin_id)
			AudioManager.play_ui_blip("select")
			_refresh_display()
		)
	else:
		act_btn.text = "BUY 🪙 %d" % price
		var can_buy := (player_coins >= price)
		if can_buy:
			var buy_style := StyleBoxFlat.new()
			buy_style.bg_color = Color(0.7, 0.55, 0.1, 0.9)
			buy_style.corner_radius_top_left = 8
			buy_style.corner_radius_top_right = 8
			buy_style.corner_radius_bottom_left = 8
			buy_style.corner_radius_bottom_right = 8
			act_btn.add_theme_stylebox_override("normal", buy_style)
			act_btn.pressed.connect(func():
				if CosmeticManager.unlock_skin(skin_id):
					CosmeticManager.equip_skin(current_slot, skin_id)
					AudioManager.play_fanfare()
					_refresh_display()
			)
		else:
			act_btn.modulate.a = 0.55
			act_btn.pressed.connect(func():
				AudioManager.play_ui_blip("error")
			)

	cvbox.add_child(act_btn)
	return card


func _draw_preview(canvas: Control, item: Dictionary) -> void:
	var center := canvas.size * 0.5
	var slot := current_slot

	# Preview background badge
	canvas.draw_circle(center, 58.0, Color(0.02, 0.04, 0.07, 0.8))
	canvas.draw_arc(center, 58.0, 0, TAU, 32, Color(0.15, 0.25, 0.35, 0.5), 1.5, true)

	if slot == CosmeticManager.SLOT_BOMB:
		var p_col: Color = item.get("primary_color", Color.BLACK)
		var a_col: Color = item.get("accent_color", Color.RED)
		var s_col: Color = item.get("spark_color", Color.YELLOW)
		
		# Bomb body
		canvas.draw_circle(center + Vector2(0, 8), 34.0, p_col)
		canvas.draw_arc(center + Vector2(0, 8), 34.0, 0, TAU, 32, a_col, 2.0, true)
		# Fuse & spark
		canvas.draw_line(center + Vector2(0, -26), center + Vector2(10, -42), Color(0.65, 0.55, 0.4), 2.5)
		canvas.draw_circle(center + Vector2(10, -42), 6.0, s_col)
		# Emblem
		canvas.draw_circle(center + Vector2(0, 8), 8.0, a_col)

	elif slot == CosmeticManager.SLOT_BALL:
		var p_col: Color = item.get("primary_color", Color.WHITE)
		var a_col: Color = item.get("accent_color", Color.CYAN)
		var g_col: Color = item.get("glow_color", Color(1, 1, 1, 0.3))

		# Ball glow & body
		canvas.draw_circle(center, 40.0, g_col)
		canvas.draw_circle(center, 34.0, p_col)
		canvas.draw_arc(center, 34.0, 0, TAU, 32, a_col, 2.5, true)
		# Specular
		canvas.draw_circle(center - Vector2(10, 10), 9.0, Color(1, 1, 1, 0.8))

	elif slot == CosmeticManager.SLOT_THEME:
		var bg_c: Color = item.get("bg_color", Color.BLACK)
		var br_c: Color = item.get("border_color", Color.CYAN)
		var bk_c: Color = item.get("bracket_color", Color.WHITE)

		var mini_rect := Rect2(center - Vector2(50, 35), Vector2(100, 70))
		canvas.draw_rect(mini_rect, bg_c)
		canvas.draw_rect(mini_rect, br_c, false, 2.0)
		# Corner brackets
		canvas.draw_line(mini_rect.position, mini_rect.position + Vector2(14, 0), bk_c, 2.5)
		canvas.draw_line(mini_rect.position, mini_rect.position + Vector2(0, 14), bk_c, 2.5)
		canvas.draw_line(mini_rect.end, mini_rect.end - Vector2(14, 0), bk_c, 2.5)
		canvas.draw_line(mini_rect.end, mini_rect.end - Vector2(0, 14), bk_c, 2.5)
