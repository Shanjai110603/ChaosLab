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
	
	# Shadow / Outline
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 4)
	
	# Center anchor
	label.position = -Vector2(100, 20)
	label.custom_minimum_size = Vector2(200, 40)
	add_child(label)

	# Initial scale pop
	scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	# Pop in
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	# Float upward
	tween.parallel().tween_property(self, "position:y", position.y - 65.0, 0.75).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.35)
	# Clean up
	tween.tween_callback(queue_free)
