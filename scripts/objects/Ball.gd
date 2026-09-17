## Ball — basic physics momentum object.
## Light weight, high bounce. The fundamental building block.
class_name BallObject
extends PhysicalObject

## Ball radius in pixels.
@export var radius: float = 24.0


func _init() -> void:
	object_name = "Ball"
	object_type = "ball"
	object_mass = 0.5
	object_friction = 0.3
	object_bounce = 0.7
	object_gravity_scale = 1.0
	object_color = Color(0.3, 0.7, 1.0)  # Soft blue
	outline_color = Color(0.15, 0.4, 0.7)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_ball.bind(_visual))
	_visual.queue_redraw()


func _draw_ball(node: Node2D) -> void:
	# Main circle
	node.draw_circle(Vector2.ZERO, radius, object_color)
	# Outline
	node.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, outline_color, outline_width, true)
	# Shine highlight
	var shine_pos := Vector2(-radius * 0.3, -radius * 0.3)
	var shine_color := Color(1, 1, 1, 0.35)
	node.draw_circle(shine_pos, radius * 0.25, shine_color)


func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
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
		_highlight.draw_arc(Vector2.ZERO, radius + 4, 0, TAU, 32, highlight_color, 3.0, true)
	)
	_highlight.queue_redraw()
