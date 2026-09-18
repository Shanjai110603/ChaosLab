## Laser — high-intensity photon beam projector apparatus.
## Projects continuous energy beam that ignites explosives, triggers targets, and reflects off surfaces.
class_name LaserObject
extends PhysicalObject

## Maximum raycast distance per segment.
@export var max_range: float = 1800.0
## Maximum number of surface reflections / bounces.
@export var max_bounces: int = 3
## Laser beam color.
@export var beam_color: Color = Color(1.0, 0.15, 0.25)

var housing_width: float = 36.0
var housing_height: float = 48.0

var _beam_points: PackedVector2Array = []
var _spark_timer: float = 0.0


func _init() -> void:
	object_name = "Laser"
	object_type = "laser"
	object_mass = 4.0
	object_friction = 0.7
	object_bounce = 0.1
	object_gravity_scale = 1.0
	object_color = Color(0.16, 0.18, 0.24)
	outline_color = Color(1.0, 0.2, 0.3)
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()


func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING or freeze:
		if not _beam_points.is_empty():
			_beam_points.clear()
			if _visual:
				_visual.queue_redraw()
		return

	_calculate_beam()
	_spark_timer += delta
	if _visual:
		_visual.queue_redraw()


func _calculate_beam() -> void:
	_beam_points.clear()

	var space_state := get_world_2d().direct_space_state
	var start_local := Vector2(0, -housing_height * 0.5)
	var curr_pos := global_position + Vector2.UP.rotated(global_rotation) * (housing_height * 0.5)
	var curr_dir := Vector2.UP.rotated(global_rotation)

	_beam_points.append(start_local)

	var exclude: Array[RID] = [get_rid()]

	for _b in range(max_bounces + 1):
		var target_pos := curr_pos + curr_dir * max_range
		var query := PhysicsRayQueryParameters2D.create(curr_pos, target_pos)
		query.collision_mask = 0b00111  # Walls (1), objects (2), targets (3)
		query.exclude = exclude

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			# Reached max range without collision
			_beam_points.append(to_local(target_pos))
			break

		var hit_pos: Vector2 = result["position"]
		var hit_normal: Vector2 = result["normal"]
		var collider: Object = result["collider"]

		_beam_points.append(to_local(hit_pos))

		# Interactive triggers on laser contact
		if collider is BombObject:
			if not collider.has_exploded and not collider.is_fuse_active:
				collider.call_deferred("activate")
		elif collider is BarrelObject and collider.is_explosive:
			if not collider.has_exploded:
				collider.call_deferred("explode")
		elif collider is TargetObject:
			if not collider.is_hit:
				collider.call_deferred("_register_hit", self)

		# Spawn contact sparks occasionally
		if _spark_timer > 0.08 and get_parent():
			_spark_timer = 0.0
			ImpactSpark.create_at(hit_pos, get_parent())

		# Check for reflection
		if collider is RampObject or collider is StaticBody2D:
			curr_dir = curr_dir.bounce(hit_normal)
			curr_pos = hit_pos + curr_dir * 1.5
			if collider is CollisionObject2D:
				exclude.append(collider.get_rid())
		else:
			# Absorbed by object
			break


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_laser.bind(_visual))
	_visual.queue_redraw()


func _draw_laser(node: Node2D) -> void:
	var hw := housing_width * 0.5
	var hh := housing_height * 0.5

	# Draw Projected Laser Beam
	if _beam_points.size() >= 2:
		for i in range(_beam_points.size() - 1):
			var p1 := _beam_points[i]
			var p2 := _beam_points[i + 1]
			# Outer bloom line
			node.draw_line(p1, p2, Color(beam_color.r, beam_color.g, beam_color.b, 0.45), 7.0)
			# Core white-hot energy beam
			node.draw_line(p1, p2, Color(1.0, 0.9, 0.95), 2.2)

		# Laser termination flare
		var last_p := _beam_points[-1]
		node.draw_circle(last_p, 7.0, Color(beam_color.r, beam_color.g, beam_color.b, 0.6))
		node.draw_circle(last_p, 3.5, Color.WHITE)

	# Shadow
	node.draw_rect(Rect2(-hw + 2, -hh + 3, housing_width, housing_height), Color(0.02, 0.04, 0.08, 0.45))

	# Heavy Optics Chassis Body
	var body_rect := Rect2(-hw, -hh + 8, housing_width, housing_height - 8)
	node.draw_rect(body_rect, Color(0.18, 0.2, 0.26))
	node.draw_rect(body_rect, Color(0.08, 0.1, 0.14), false, 2.0)

	# Optics Aperture Lens Collar
	var lens_rect := Rect2(-hw + 4, -hh, housing_width - 8, 8)
	node.draw_rect(lens_rect, Color(0.75, 0.6, 0.2))
	node.draw_rect(lens_rect, Color(0.3, 0.25, 0.1), false, 1.5)

	# Laser Crystal Diode Core
	node.draw_circle(Vector2(0, -hh + 4), 4.5, beam_color)
	node.draw_circle(Vector2(0, -hh + 4), 2.0, Color.WHITE)

	# Cooling Heatsink Fins
	for fin in 3:
		var fy: float = -hh + 16 + fin * 8
		node.draw_line(Vector2(-hw + 4, fy), Vector2(hw - 4, fy), Color(0.3, 0.35, 0.45), 2.0)

	# Status indicator LED
	var led_col: Color = Color.GREEN if GameManager.current_state == GameManager.GameState.SIMULATING else Color.RED
	node.draw_circle(Vector2(0, hh - 8), 3.0, led_col)


func _create_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(housing_width, housing_height)
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
		var r := Rect2(-housing_width * 0.5 - 6, -housing_height * 0.5 - 6, housing_width + 12, housing_height + 12)
		_highlight.draw_rect(r, col, false, 3.0)
		_highlight.draw_rect(r, Color(col.r, col.g, col.b, 0.15))
		# Show trajectory guide line during placement
		_highlight.draw_line(Vector2(0, -housing_height * 0.5), Vector2(0, -180.0), Color(col.r, col.g, col.b, 0.4), 1.5)
	)
	_highlight.queue_redraw()


func _on_reset() -> void:
	super._on_reset()
	_beam_points.clear()
	if _visual:
		_visual.queue_redraw()
