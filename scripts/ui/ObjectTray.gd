## ObjectTray — bottom inventory dock for spawning and placing experiment components.
## Glassmorphic panel with interactive object cards and remaining counts.
class_name ObjectTray
extends PanelContainer

signal object_spawn_requested(object_type: String, world_position: Vector2)

## Inventory counts dictionary: {"ball": 2, "box": 1, "barrel": 1, "bomb": 1, "rocket": 1, "ramp": 2}
var inventory: Dictionary = {}

var _card_container: HBoxContainer = null
var _cards: Dictionary = {}


func _ready() -> void:
	# Custom glassmorphism styling
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.16, 0.88)
	style.border_color = Color(0.0, 0.8, 1.0, 0.4)
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(12)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	_card_container = HBoxContainer.new()
	_card_container.add_theme_constant_override("separation", 16)
	_card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_card_container)

	GameManager.state_changed.connect(_on_game_state_changed)

	# Populate default sandbox inventory if empty
	if inventory.is_empty():
		set_inventory({
			"ball": 5,
			"box": 4,
			"barrel": 3,
			"bomb": 3,
			"rocket": 2,
			"ramp": 3
		})


## Set inventory quantities and rebuild cards.
func set_inventory(items: Dictionary) -> void:
	inventory = items.duplicate()
	_rebuild_cards()


## Add quantity to an inventory item and rebuild cards.
func add_item(item_type: String, amount: int = 1) -> void:
	var current: int = inventory.get(item_type, 0)
	if current >= 0:
		inventory[item_type] = current + amount
	else:
		inventory[item_type] = amount
	_rebuild_cards()


func _rebuild_cards() -> void:
	if not _card_container:
		return

	for child in _card_container.get_children():
		child.queue_free()
	_cards.clear()

	var item_order := ["ball", "box", "barrel", "bomb", "rocket", "ramp", "magnet", "portal", "gravity_pad", "laser"]
	for item_type in item_order:
		if inventory.has(item_type):
			var count: int = inventory[item_type]
			_create_item_card(item_type, count)


func _create_item_card(item_type: String, count: int) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(84, 78)
	card.focus_mode = Control.FOCUS_NONE

	# Button styling
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.15, 0.24, 0.9)
	btn_style.border_color = Color(0.0, 0.7, 0.9, 0.35)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("normal", btn_style)

	var hover_style := btn_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.14, 0.22, 0.35, 0.95)
	hover_style.border_color = Color(0.0, 1.0, 0.85, 0.8)
	card.add_theme_stylebox_override("hover", hover_style)

	# VBox for icon and text
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	const SPRITE_MAP: Dictionary = {
		"ball": "res://assets/sprites/objects/ball_metal.png",
		"box": "res://assets/sprites/objects/crate_wood.png",
		"barrel": "res://assets/sprites/objects/barrel_explosive.png",
		"bomb": "res://assets/sprites/objects/bomb_spiked.png",
		"ramp": "res://assets/sprites/objects/ramp_wood.png",
	}

	var icon_path: String = SPRITE_MAP.get(item_type.to_lower(), "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(icon_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(34, 34)
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(tex_rect)
	else:
		var icon_label := Label.new()
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 22)
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		match item_type.to_lower():
			"rocket":
				icon_label.text = "▲"
				icon_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
			"magnet":
				icon_label.text = "U"
				icon_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.4))
			"portal":
				icon_label.text = "◎"
				icon_label.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
			"gravity_pad":
				icon_label.text = "▲"
				icon_label.add_theme_color_override("font_color", Color(0.0, 0.95, 0.75))
			"laser":
				icon_label.text = "—"
				icon_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.35))
			_:
				icon_label.text = "◆"
				icon_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(icon_label)

	# Name + Count label
	var count_label := Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.text = "%s ×%d" % [item_type.capitalize(), count] if count >= 0 else "%s ∞" % item_type.capitalize()
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.85))
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(count_label)

	card.pressed.connect(func():
		_on_card_clicked(item_type)
	)

	_card_container.add_child(card)
	_cards[item_type] = {"card": card, "count_label": count_label, "count": count}


func _on_card_clicked(item_type: String) -> void:
	if GameManager.current_state != GameManager.GameState.PLACING:
		return

	var count: int = inventory.get(item_type, 0)
	if count <= 0 and count != -1:  # -1 = infinite
		return

	# Decrement count if not infinite
	if count > 0:
		inventory[item_type] = count - 1
		_update_card_display(item_type)

	# Spawn into the arena at screen center
	var viewport := get_viewport()
	var center := viewport.get_visible_rect().size * 0.5
	var canvas_transform := viewport.get_canvas_transform()
	var world_pos: Vector2 = canvas_transform.affine_inverse() * center

	object_spawn_requested.emit(item_type, world_pos)


func _update_card_display(item_type: String) -> void:
	if not _cards.has(item_type):
		return
	var data: Dictionary = _cards[item_type]
	var count: int = inventory.get(item_type, 0)
	var count_label: Label = data["count_label"]
	var card: Button = data["card"]

	if count >= 0:
		count_label.text = "%s ×%d" % [item_type.capitalize(), count]
		card.disabled = (count == 0)
		card.modulate = Color(0.5, 0.5, 0.5, 0.5) if count == 0 else Color.WHITE
	else:
		count_label.text = "%s ∞" % item_type.capitalize()


func _on_game_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	match new:
		GameManager.GameState.SIMULATING:
			# Animate tray sliding down / dimming
			var tween := create_tween()
			tween.tween_property(self, "modulate:a", 0.25, 0.25)
		GameManager.GameState.PLACING:
			var tween := create_tween()
			tween.tween_property(self, "modulate:a", 1.0, 0.25)
