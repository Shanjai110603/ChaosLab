## GravityPad — localized anti-gravity and upward thrust field emitter.
## Inverts downward gravity, launching or floating physics bodies skyward.
class_name GravityPadObject
extends PhysicalObject

## Width of the emitter platform and vertical force beam.
@export var pad_width: float = 88.0
## Height of the upward anti-gravity field column.
@export var field_height: float = 240.0
## Upward acceleration force per unit mass.
@export var upward_acceleration: float = 1600.0

var pad_height: float = 20.0
var _field_area: Area2D = null
var _particle_timer: float = 0.0


func _init() -> void:
	object_name = "Anti-Grav Pad"
	object_type = "gravity_pad"
	object_mass = 8.0
	object_friction = 0.85
	object_bounce = 0.05
	object_gravity_scale = 1.0
	object_color = Color(0.12, 0.16, 0.22)
	outline_color = Color(0.0, 0.9, 0.7)
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	_create_field_area()


func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.SIMULATING:
		_particle_timer = wrapf(_particle_timer + delta * 2.5, 0.0, 1.0)
		if _visual:
			_visual.queue_redraw()


func _physics_process(_delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING or freeze:
		return

	if not _field_area:
		return

	var bodies := _field_area.get_overlapping_bodies()
	for body in bodies:
		if body == self or not (body is RigidBody2D):
			continue

		# Apply upward force against arena gravity
		var up_dir: Vector2 = Vector2.UP.rotated(global_rotation)
		var lift_force: Vector2 = up_dir * (upward_acceleration * body.mass)
		body.apply_central_force(lift_force)


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_pad.bind(_visual))
	_visual.queue_redraw()


func _draw_pad(node: Node2D) -> void:
	var hw := pad_width * 0.5
	var hh := pad_height * 0.5

	# Active anti-gravity vertical beam aura
	if GameManager.current_state == GameManager.GameState.SIMULATING:
		var beam_rect := Rect2(-hw + 6, -field_height, pad_width - 12, field_height)
		node.draw_rect(beam_rect, Color(0.0, 0.95, 0.75, 0.08))
		node.draw_line(Vector2(-hw + 6, -field_height), Vector2(-hw + 6, 0), Color(0.0, 0.95, 0.75, 0.4), 1.5)
		node.draw_line(Vector2(hw - 6, -field_height), Vector2(hw - 6, 0), Color(0.0, 0.95, 0.75, 0.4), 1.5)

		# Upward floating ion chevrons
		for i in 4:
			var progress := wrapf(_particle_timer + float(i) / 4.0, 0.0, 1.0)
			var y_pos := lerpf(0.0, -field_height, progress)
			var alpha := sin(progress * PI) * 0.7
			var chev_col := Color(0.0, 1.0, 0.8, alpha)
			var p1 := Vector2(-16, y_pos + 8)
			var p2 := Vector2(0, y_pos)
			var p3 := Vector2(16, y_pos + 8)
			node.draw_line(p1, p2, chev_col, 2.5)
			node.draw_line(p2, p3, chev_col, 2.5)

	# Shadow
	node.draw_rect(Rect2(-hw + 2, -hh + 3, pad_width, pad_height), Color(0.02, 0.04, 0.08, 0.45))

	# Heavy Metallic Base
	var base_rect := Rect2(-hw, -hh, pad_width, pad_height)
	node.draw_rect(base_rect, Color(0.18, 0.22, 0.3))
	node.draw_rect(base_rect, outline_color, false, 2.0)

	# Center Ion Emitter Grid Grille
	var grill_rect := Rect2(-hw + 10, -hh + 3, pad_width - 20, pad_height - 6)
	node.draw_rect(grill_rect, Color(0.0, 0.85, 0.7, 0.85))
	for g in 5:
		var gx: float = grill_rect.position.x + 4 + g * 12
		node.draw_line(Vector2(gx, grill_rect.position.y), Vector2(gx, grill_rect.end.y), Color(0.05, 0.1, 0.15), 2.0)

	# Hazard warning brackets on sides
	node.draw_line(Vector2(-hw + 3, -hh + 4), Vector2(-hw + 7, hh - 4), Color(1.0, 0.8, 0.1), 2.0)
	node.draw_line(Vector2(hw - 7, -hh + 4), Vector2(hw - 3, hh - 4), Color(1.0, 0.8, 0.1), 2.0)


func _create_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(pad_width, pad_height)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_field_area() -> void:
	_field_area = Area2D.new()
	_field_area.name = "GravityField"
	_field_area.collision_layer = 0
	_field_area.collision_mask = 0b00010  # Layer 2: objects

	var shape := RectangleShape2D.new()
	shape.size = Vector2(pad_width - 8, field_height)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -field_height * 0.5)
	_field_area.add_child(col)
	add_child(_field_area)


func _create_highlight() -> void:
	_highlight = Node2D.new()
	_highlight.name = "Highlight"
	_highlight.visible = false
	add_child(_highlight)
	_highlight.draw.connect(func():
		var col := valid_highlight_color if is_placement_valid else invalid_highlight_color
		var r := Rect2(-pad_width * 0.5 - 6, -pad_height * 0.5 - 6, pad_width + 12, pad_height + 12)
		_highlight.draw_rect(r, col, false, 3.0)
		_highlight.draw_rect(r, Color(col.r, col.g, col.b, 0.15))
		# Show upward field bounds during placement
		var f_rect := Rect2(-pad_width * 0.5 + 4, -field_height, pad_width - 8, field_height)
		_highlight.draw_rect(f_rect, Color(col.r, col.g, col.b, 0.15), true)
		_highlight.draw_rect(f_rect, col, false, 1.5)
	)
	_highlight.queue_redraw()


func _on_reset() -> void:
	super._on_reset()
	_particle_timer = 0.0
	if _visual:
		_visual.queue_redraw()
