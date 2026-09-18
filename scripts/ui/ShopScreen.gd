## ShopScreen — Laboratory Armory and Customization Store.
## Allows players to spend coins to unlock and equip procedural skins and arena themes.
class_name ShopScreen
extends Control

signal closed()

const SLOT_SUPPLIES: String = "supplies"

var current_slot: String = CosmeticManager.SLOT_BOMB
var _coins_label: Label = null
var _tab_bombs: Button = null
var _tab_balls: Button = null
var _tab_themes: Button = null
var _tab_supplies: Button = null
var _cards_container: HBoxContainer = null
var _restore_btn: Button = null

const COLOR_BG := Color(0.03, 0.05, 0.08, 0.98)
const COLOR_GOLD := Color(1.0, 0.85, 0.25)
const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_GREEN := Color(0.2, 0.9, 0.4)
const COLOR_PURPLE := Color(0.75, 0.35, 1.0)

const IAP_PRODUCTS: Array = [
	{
		"id": "coin_pack_small",
		"name": "Beaker of Coins",
		"icon": "🪙",
		"color": Color(1.0, 0.85, 0.25),
		"amount": "+500 COINS",
		"desc": "Quick injection of research capital for immediate laboratory unlocks.",
		"price_tag": "$0.99",
	},
	{
		"id": "coin_pack_medium",
		"name": "Flask of Coins",
		"icon": "🧪",
		"color": Color(0.0, 0.85, 1.0),
		"amount": "+1,500 COINS",
		"desc": "Generous research grant for high-grade apparatus & skins.",
		"price_tag": "$2.49",
	},
	{
		"id": "coin_pack_large",
		"name": "Quantum Vault",
		"icon": "⚡",
		"color": Color(0.8, 0.4, 1.0),
		"amount": "+5,000 COINS",
		"desc": "Massive corporate laboratory treasury reserve.",
		"price_tag": "$4.99",
	},
	{
		"id": "remove_ads",
		"name": "Remove Ads",
		"icon": "🚫",
		"color": Color(0.95, 0.35, 0.35),
		"amount": "NO INTERSTITIALS",
		"desc": "Permanently eliminates all interstitial advertisements forever.",
		"price_tag": "$1.99",
	},
	{
		"id": "vip_pass",
		"name": "VIP Scientist Pass",
		"icon": "👑",
		"color": Color(1.0, 0.82, 0.15),
		"amount": "2X COINS FOREVER",
		"desc": "Permanent 2x coins on all levels + Ad-Free + Atomic & Quantum skins + 1,000 bonus coins!",
		"price_tag": "$4.99",
	},
]


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
	vbox.add_theme_constant_override("separation", 20)
	vbox.offset_left = 50
	vbox.offset_right = -50
	vbox.offset_top = 24
	vbox.offset_bottom = -24
	add_child(vbox)

	# Top Navigation Bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	vbox.add_child(top_bar)

	var back_btn := Button.new()
	back_btn.text = "← BACK"
	back_btn.custom_minimum_size = Vector2(120, 44)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func():
		AudioManager.play_ui_blip("select")
		closed.emit()
	)
	top_bar.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "LABORATORY ARMORY & STORE"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Coins pill
	var coin_panel := PanelContainer.new()
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = Color(0.1, 0.14, 0.22, 0.8)
	coin_style.set_corner_radius_all(16)
	coin_style.content_margin_left = 18
	coin_style.content_margin_right = 18
	coin_style.content_margin_top = 6
	coin_style.content_margin_bottom = 6
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
	tabs_box.add_theme_constant_override("separation", 16)
	vbox.add_child(tabs_box)

	_tab_bombs = Button.new()
	_tab_bombs.text = "💣 BOMBS"
	_tab_bombs.custom_minimum_size = Vector2(170, 44)
	_tab_bombs.add_theme_font_size_override("font_size", 15)
	_tab_bombs.focus_mode = Control.FOCUS_NONE
	_tab_bombs.pressed.connect(func(): _select_category(CosmeticManager.SLOT_BOMB))
	tabs_box.add_child(_tab_bombs)

	_tab_balls = Button.new()
	_tab_balls.text = "⚽ SPHERES"
	_tab_balls.custom_minimum_size = Vector2(170, 44)
	_tab_balls.add_theme_font_size_override("font_size", 15)
	_tab_balls.focus_mode = Control.FOCUS_NONE
	_tab_balls.pressed.connect(func(): _select_category(CosmeticManager.SLOT_BALL))
	tabs_box.add_child(_tab_balls)

	_tab_themes = Button.new()
	_tab_themes.text = "🔬 THEMES"
	_tab_themes.custom_minimum_size = Vector2(170, 44)
	_tab_themes.add_theme_font_size_override("font_size", 15)
	_tab_themes.focus_mode = Control.FOCUS_NONE
	_tab_themes.pressed.connect(func(): _select_category(CosmeticManager.SLOT_THEME))
	tabs_box.add_child(_tab_themes)

	_tab_supplies = Button.new()
	_tab_supplies.text = "💎 SUPPLIES"
	_tab_supplies.custom_minimum_size = Vector2(180, 44)
	_tab_supplies.add_theme_font_size_override("font_size", 15)
	_tab_supplies.focus_mode = Control.FOCUS_NONE
	_tab_supplies.pressed.connect(func(): _select_category(SLOT_SUPPLIES))
	tabs_box.add_child(_tab_supplies)

	# Cards Container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_cards_container = HBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 20)
	scroll.add_child(_cards_container)

	# Bottom Bar (Restore Purchases)
	var bottom_bar := HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom_bar)

	_restore_btn = Button.new()
	_restore_btn.text = "↺ RESTORE PURCHASES"
	_restore_btn.custom_minimum_size = Vector2(220, 36)
	_restore_btn.add_theme_font_size_override("font_size", 13)
	_restore_btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 0.8))
	_restore_btn.focus_mode = Control.FOCUS_NONE
	_restore_btn.flat = true
	_restore_btn.pressed.connect(_on_restore_purchases_pressed)
	bottom_bar.add_child(_restore_btn)


func _select_category(slot: String) -> void:
	current_slot = slot
	AudioManager.play_ui_blip("select")
	_refresh_display()


func _on_restore_purchases_pressed() -> void:
	AudioManager.play_ui_blip("click")
	PlatformService.restore_purchases(func(restored: Array):
		AudioManager.play_ui_blip("star")
		_refresh_display()
	)
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
	_tab_supplies.add_theme_stylebox_override("normal", active_style if current_slot == SLOT_SUPPLIES else inactive_style)

	# Clear and rebuild cards
	for child in _cards_container.get_children():
		child.queue_free()

	if current_slot == SLOT_SUPPLIES:
		for prod in IAP_PRODUCTS:
			var card := _create_iap_card(prod)
			_cards_container.add_child(card)
	else:
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


func _create_iap_card(product: Dictionary) -> Control:
	var prod_id: String = product["id"]
	var prod_color: Color = product.get("color", COLOR_GOLD)
	var price_tag: String = product.get("price_tag", "$0.99")
	var is_owned := false

	if prod_id == "remove_ads":
		is_owned = SaveManager.is_ads_removed()
	elif prod_id == "vip_pass":
		is_owned = SaveManager.is_vip()

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 420)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.09, 0.15, 0.96)
	card_style.set_corner_radius_all(14)
	card_style.border_color = prod_color.lerp(Color(0.2, 0.3, 0.4), 0.4)
	card_style.set_border_width_all(2 if (is_owned or prod_id == "vip_pass") else 1)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", card_style)

	var cvbox := VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 12)
	card.add_child(cvbox)

	# Product Icon Banner
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(210, 110)
	var ib_style := StyleBoxFlat.new()
	ib_style.bg_color = Color(0.03, 0.05, 0.09, 0.9)
	ib_style.set_corner_radius_all(10)
	ib_style.border_color = prod_color.darkened(0.3)
	ib_style.set_border_width_all(1)
	icon_box.add_theme_stylebox_override("panel", ib_style)
	cvbox.add_child(icon_box)

	var icon_lbl := Label.new()
	icon_lbl.text = product.get("icon", "💎")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 50)
	icon_box.add_child(icon_lbl)

	# Title & Reward Amount
	var title_lbl := Label.new()
	title_lbl.text = product.get("name", "Product")
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(title_lbl)

	var amount_lbl := Label.new()
	amount_lbl.text = product.get("amount", "")
	amount_lbl.add_theme_font_size_override("font_size", 14)
	amount_lbl.add_theme_color_override("font_color", prod_color)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(amount_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = product.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9, 0.8))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cvbox.add_child(spacer)

	# Buy / Status Button
	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(210, 44)
	buy_btn.focus_mode = Control.FOCUS_NONE

	if is_owned:
		buy_btn.text = "👑 ACTIVE VIP" if prod_id == "vip_pass" else "✓ OWNED"
		buy_btn.disabled = true
		var own_style := StyleBoxFlat.new()
		own_style.bg_color = Color(0.05, 0.35, 0.2, 0.5)
		own_style.border_color = COLOR_GREEN
		own_style.set_border_width_all(1)
		own_style.set_corner_radius_all(8)
		buy_btn.add_theme_stylebox_override("disabled", own_style)
		buy_btn.add_theme_color_override("font_disabled_color", COLOR_GREEN)
	else:
		buy_btn.text = "%s" % price_tag
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = prod_color.darkened(0.2)
		b_style.set_corner_radius_all(8)
		buy_btn.add_theme_stylebox_override("normal", b_style)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.add_theme_color_override("font_color", Color.WHITE)
		buy_btn.pressed.connect(func():
			AudioManager.play_ui_blip("click")
			PlatformService.purchase(prod_id, func(success: bool):
				if success:
					AudioManager.play_fanfare()
					_refresh_display()
				else:
					AudioManager.play_ui_blip("error")
			)
		)

	cvbox.add_child(buy_btn)
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
