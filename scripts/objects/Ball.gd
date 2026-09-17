## Ball — high-fidelity stylized physics momentum sphere.
## Light weight, high bounce, smooth rolling. Key building block of chain reactions.
class_name BallObject
extends PhysicalObject

## Ball radius in pixels.
@export var radius: float = 24.0

## Squash & stretch visual scaling.
var _squash_scale: Vector2 = Vector2.ONE


func _init() -> void:
	object_name = "Ball"
	object_type = "ball"
	object_mass = 0.6
	object_friction = 0.25
	object_bounce = 0.78
	object_gravity_scale = 1.0
	object_color = Color(0.15, 0.65, 1.0)        # Vibrant lab cyan-blue
	outline_color = Color(0.04, 0.25, 0.55)      # Deep contrast blue
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()


func _physics_process(_delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.SIMULATING and not freeze:
		var speed := linear_velocity.length()
		
		# Squash and stretch based on velocity
		if speed > 100.0:
			var stretch := clampf(1.0 + (speed / 1800.0), 1.0, 1.35)
			var squash := 1.0 / stretch
			_squash_scale = Vector2(stretch, squash)
			if _visual:
				_visual.rotation = linear_velocity.angle()
				_visual.scale = _squash_scale
				_visual.queue_redraw()
		else:
			if _squash_scale != Vector2.ONE:
				_squash_scale = Vector2.ONE
				if _visual:
					_visual.scale = Vector2.ONE
					_visual.rotation = 0.0
					_visual.queue_redraw()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_ball.bind(_visual))
	_visual.queue_redraw()


func _draw_ball(node: Node2D) -> void:
	# Outer shadow base
	node.draw_circle(Vector2(1, 2), radius, Color(0.02, 0.08, 0.18, 0.5))
	
	# Base shaded body
	node.draw_circle(Vector2.ZERO, radius, object_color)
	
	# Dark lower crescent for 3D depth
	var dark_color := Color(object_color.r * 0.45, object_color.g * 0.45, object_color.b * 0.6)
	node.draw_arc(Vector2(0, 3), radius * 0.85, PI * 0.15, PI * 0.85, 24, dark_color, 4.0, true)
	
	# Inner illuminated glow
	var light_color := Color(object_color.r * 1.3, object_color.g * 1.3, object_color.b * 1.3, 0.4)
	node.draw_circle(Vector2(-radius * 0.2, -radius * 0.2), radius * 0.65, light_color)
	
	# Equator rotation stripe (reveals rolling spin)
	var stripe_col := Color(1.0, 1.0, 1.0, 0.35)
	node.draw_line(Vector2(-radius * 0.85, 0), Vector2(radius * 0.85, 0), stripe_col, 2.5)
	
	# Dynamic glossy specular highlight dot
	var spec_pos := Vector2(-radius * 0.35, -radius * 0.35)
	node.draw_circle(spec_pos, radius * 0.28, Color(1.0, 1.0, 1.0, 0.85))
	node.draw_circle(spec_pos + Vector2(radius * 0.1, radius * 0.1), radius * 0.12, Color(1.0, 1.0, 1.0, 0.95))
	
	# Crisp outline
	node.draw_arc(Vector2.ZERO, radius, 0, TAU, 36, outline_color, outline_width, true)


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
		var col := valid_highlight_color if is_placement_valid else invalid_highlight_color
		_highlight.draw_arc(Vector2.ZERO, radius + 6, 0, TAU, 36, col, 3.5, true)
		_highlight.draw_circle(Vector2.ZERO, radius + 6, Color(col.r, col.g, col.b, 0.15))
	)
	_highlight.queue_redraw()


func _on_reset() -> void:
	super._on_reset()
	_squash_scale = Vector2.ONE
	if _visual:
		_visual.scale = Vector2.ONE
		_visual.rotation = 0.0
		_visual.queue_redraw()
