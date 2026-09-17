## Box — heavy stable physics obstacle.
## Higher mass, moderate bounce. Used as a building block and obstacle.
class_name BoxObject
extends PhysicalObject

## Box half-width and half-height.
@export var half_size: Vector2 = Vector2(30, 30)


func _init() -> void:
	object_name = "Box"
	object_type = "box"
	object_mass = 2.0
	object_friction = 0.6
	object_bounce = 0.2
	object_gravity_scale = 1.0
	object_color = Color(0.85, 0.65, 0.35)  # Warm wood brown
	outline_color = Color(0.5, 0.35, 0.15)


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
	# Main body
	node.draw_rect(rect, object_color)
	# Outline
	node.draw_rect(rect, outline_color, false, outline_width)
	# Inner cross pattern for visual interest
	var inner := half_size * 0.7
	var line_color := Color(outline_color, 0.3)
	node.draw_line(Vector2(-inner.x, 0), Vector2(inner.x, 0), line_color, 1.0)
	node.draw_line(Vector2(0, -inner.y), Vector2(0, inner.y), line_color, 1.0)


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
		var rect := Rect2(-half_size - Vector2(4, 4), (half_size + Vector2(4, 4)) * 2)
		_highlight.draw_rect(rect, highlight_color, false, 3.0)
	)
	_highlight.queue_redraw()
