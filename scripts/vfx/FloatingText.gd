## FloatingText — world-space animated text popup for points, combos, and chaotic events.
## Spawns at impact point, springs upward, and fades out cleanly.
class_name FloatingText
extends Node2D

static var active_count: int = 0
const MAX_ACTIVE_TEXTS: int = 16

var label: Label = null


static func spawn(parent: Node, text: String, world_pos: Vector2, color: Color = Color(1.0, 0.85, 0.2), font_size: int = 22) -> FloatingText:
	if active_count >= MAX_ACTIVE_TEXTS:
		return null
	var ft := FloatingText.new()
	ft.global_position = world_pos
	parent.add_child(ft)
	active_count += 1
	ft.tree_exited.connect(func(): active_count = maxi(0, active_count - 1))
	ft._animate(text, color, font_size)
	return ft


func _animate(text: String, color: Color, font_size: int) -> void:
	z_index = 50  # Render above physics objects

	label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

	# Drop shadow for legibility over any background
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 5)

	# Center anchor
	label.position = -Vector2(120, 20)
	label.custom_minimum_size = Vector2(240, 40)
	add_child(label)

	# --- Elastic scale punch: pop from 1.4x and spring to 1.0 ---
	const SCALE_PUNCH: float = 1.4
	const FLOAT_DISTANCE: float = -120.0
	const FLOAT_DURATION: float = 0.9
	const FADE_DELAY: float = 0.6   # Start fading at 0.6s

	scale = Vector2(SCALE_PUNCH, SCALE_PUNCH)

	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
	# Elastic spring settle from 1.4 to 1.0
	tween.tween_property(self, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Float upward -120px over full lifetime
	tween.parallel().tween_property(self, "position:y", position.y + FLOAT_DISTANCE, FLOAT_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Delayed alpha fade (visible for 0.6s, then fades over 0.3s)
	tween.parallel().tween_property(self, "modulate:a", 0.0, FLOAT_DURATION - FADE_DELAY) \
		.set_delay(FADE_DELAY)
	# Cleanup
	tween.tween_callback(queue_free)
