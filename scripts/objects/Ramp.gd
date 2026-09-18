## Ramp — inclined track for guiding, accelerating, and launching physics objects.
## Stays anchored in place as a static surface during simulation.
class_name RampObject
extends GameObject

## Ramp dimensions (width along base, height of incline).
@export var ramp_width: float = 120.0
@export var ramp_height: float = 60.0
## Friction coefficient along incline.
@export var ramp_friction: float = 0.08
## Bounce coefficient.
@export var ramp_bounce: float = 0.25


func _init() -> void:
	object_name = "Ramp"
	object_type = "ramp"
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC


func _ready() -> void:
	super._ready()
	freeze = true  # Ramps stay fixed in place during simulation

	var phys_mat := PhysicsMaterial.new()
	phys_mat.friction = ramp_friction
	phys_mat.bounce = ramp_bounce
	physics_material_override = phys_mat

	_create_visual()
	_create_collision()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_ramp.bind(_visual))
	_visual.queue_redraw()


func _draw_ramp(node: Node2D) -> void:
	# Right triangle: Base from (-ramp_width/2, ramp_height/2) to (ramp_width/2, ramp_height/2)
	# Peak at (-ramp_width/2, -ramp_height/2)
	var hw := ramp_width * 0.5
	var hh := ramp_height * 0.5

	var p_bottom_left := Vector2(-hw, hh)
	var p_bottom_right := Vector2(hw, hh)
	var p_top_left := Vector2(-hw, -hh)

	var poly := PackedVector2Array([p_bottom_left, p_bottom_right, p_top_left])

	# Drop shadow
	var shadow_poly := PackedVector2Array([
		p_bottom_left + Vector2(2, 3),
		p_bottom_right + Vector2(2, 3),
		p_top_left + Vector2(2, 3)
	])
	node.draw_colored_polygon(shadow_poly, Color(0.02, 0.05, 0.1, 0.4))

	# Solid lab steel body
	node.draw_colored_polygon(poly, Color(0.2, 0.28, 0.38))

	# Incline sliding strip (neon cyan low-friction rail)
	node.draw_line(p_top_left, p_bottom_right, Color(0.0, 0.85, 1.0, 0.95), 3.5)

	# Directional accelerator chevrons along slope
	var steps := 3
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps + 1)
		var pt: Vector2 = p_top_left.lerp(p_bottom_right, t)
		var norm := Vector2(1, -1).normalized() * 4.0
		node.draw_circle(pt, 2.0, Color(0.0, 1.0, 0.85, 0.8))

	# Base support line
	node.draw_line(p_bottom_left, p_bottom_right, Color(0.1, 0.15, 0.22), 2.5)
	node.draw_line(p_bottom_left, p_top_left, Color(0.1, 0.15, 0.22), 2.5)


func _create_collision() -> void:
	var hw := ramp_width * 0.5
	var hh := ramp_height * 0.5

	var shape := ConvexPolygonShape2D.new()
	shape.points = PackedVector2Array([
		Vector2(-hw, hh),
		Vector2(hw, hh),
		Vector2(-hw, -hh)
	])

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
		var hw := ramp_width * 0.5 + 4
		var hh := ramp_height * 0.5 + 4
		var col := Color(0.0, 1.0, 0.85, 0.8) if is_placement_valid else Color(1.0, 0.2, 0.2, 0.8)
		_highlight.draw_line(Vector2(-hw, hh), Vector2(hw, hh), col, 3.0)
		_highlight.draw_line(Vector2(hw, hh), Vector2(-hw, -hh), col, 3.0)
		_highlight.draw_line(Vector2(-hw, -hh), Vector2(-hw, hh), col, 3.0)
	)
	_highlight.queue_redraw()
