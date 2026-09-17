## Box — heavy reinforced physics obstacle and structural element.
## High stability, moderate friction, corner-weighted. Used for ramps, dominoes, and barriers.
class_name BoxObject
extends PhysicalObject

## Box half-width and half-height.
@export var half_size: Vector2 = Vector2(30, 30)


func _init() -> void:
	object_name = "Box"
	object_type = "box"
	object_mass = 2.5
	object_friction = 0.65
	object_bounce = 0.18
	object_gravity_scale = 1.0
	object_color = Color(0.78, 0.52, 0.28)      # Warm treated cedar
	outline_color = Color(0.38, 0.22, 0.1)      # Dark timber rim
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_box.bind(_visual))
	_visual.queue_redraw()


func _draw_box(node: Node2D) -> void:
	var rect := Rect2(-half_size, half_size * 2)
	
	# Drop shadow
	node.draw_rect(Rect2(-half_size + Vector2(2, 3), half_size * 2), Color(0.02, 0.05, 0.1, 0.45))
	
	# Main crate plank body
	node.draw_rect(rect, object_color)
	
	# Inner beveled frame
	var inner_rect := rect.grow(-4.0)
	node.draw_rect(inner_rect, Color(object_color.r * 0.9, object_color.g * 0.9, object_color.b * 0.9))
	
	# Diagonal cross braces (X-pattern)
	var brace_color := Color(object_color.r * 0.8, object_color.g * 0.78, object_color.b * 0.75)
	node.draw_line(inner_rect.position, inner_rect.end, brace_color, 4.0)
	node.draw_line(Vector2(inner_rect.position.x, inner_rect.end.y), Vector2(inner_rect.end.x, inner_rect.position.y), brace_color, 4.0)
	
	# Metallic corner reinforcements (riveted metal brackets)
	var bracket_len := 12.0
	var metal_color := Color(0.45, 0.5, 0.58)
	var rivet_color := Color(0.85, 0.9, 0.95)
	
	var c_tl := -half_size
	var c_tr := Vector2(half_size.x, -half_size.y)
	var c_bl := Vector2(-half_size.x, half_size.y)
	var c_br := half_size
	
	# Draw brackets
	node.draw_line(c_tl, c_tl + Vector2(bracket_len, 0), metal_color, 3.5)
	node.draw_line(c_tl, c_tl + Vector2(0, bracket_len), metal_color, 3.5)
	node.draw_circle(c_tl + Vector2(4, 4), 1.5, rivet_color)
	
	node.draw_line(c_tr, c_tr + Vector2(-bracket_len, 0), metal_color, 3.5)
	node.draw_line(c_tr, c_tr + Vector2(0, bracket_len), metal_color, 3.5)
	node.draw_circle(c_tr + Vector2(-4, 4), 1.5, rivet_color)
	
	node.draw_line(c_bl, c_bl + Vector2(bracket_len, 0), metal_color, 3.5)
	node.draw_line(c_bl, c_bl + Vector2(0, -bracket_len), metal_color, 3.5)
	node.draw_circle(c_bl + Vector2(4, -4), 1.5, rivet_color)
	
	node.draw_line(c_br, c_br + Vector2(-bracket_len, 0), metal_color, 3.5)
	node.draw_line(c_br, c_br + Vector2(0, -bracket_len), metal_color, 3.5)
	node.draw_circle(c_br + Vector2(-4, -4), 1.5, rivet_color)
	
	# Outer border outline
	node.draw_rect(rect, outline_color, false, outline_width)


func _create_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = half_size * 2
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_highlight() -> void:
	_highlight = Node2D.new()
	_highlight.name = "Highlight"
	_highlight.visible = false
	add_child(_highlight)
	_highlight.draw.connect(func():
		var col := valid_highlight_color if is_placement_valid else invalid_highlight_color
		var rect := Rect2(-half_size - Vector2(6, 6), (half_size + Vector2(6, 6)) * 2)
		_highlight.draw_rect(rect, col, false, 3.5)
		_highlight.draw_rect(rect, Color(col.r, col.g, col.b, 0.15))
	)
	_highlight.queue_redraw()
