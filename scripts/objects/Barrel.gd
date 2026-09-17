## Barrel — rolling cylindrical object with optional explosive capability.
## Key chain-reaction object. Can be configured as flammable/explosive.
class_name BarrelObject
extends PhysicalObject

## Barrel dimensions.
@export var barrel_radius: float = 22.0
@export var barrel_height: float = 50.0

## Explosive properties.
@export_group("Explosive")
@export var is_explosive: bool = true
@export var explosion_radius: float = 150.0
@export var explosion_force: float = 800.0
## Whether this barrel has already exploded.
var has_exploded: bool = false

## Blast zone Area2D for detecting nearby objects.
var _blast_area: Area2D = null


func _init() -> void:
	object_name = "Barrel"
	object_type = "barrel"
	object_mass = 1.5
	object_friction = 0.4
	object_bounce = 0.15
	object_gravity_scale = 1.0
	object_color = Color(0.7, 0.25, 0.1)  # Dark red-orange
	outline_color = Color(0.4, 0.12, 0.05)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	if is_explosive:
		_create_blast_zone()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_barrel.bind(_visual))
	_visual.queue_redraw()


func _draw_barrel(node: Node2D) -> void:
	var half_h := barrel_height * 0.5
	var rect := Rect2(-barrel_radius, -half_h, barrel_radius * 2, barrel_height)

	# Main body (rounded rectangle effect)
	node.draw_rect(rect, object_color)

	# Horizontal stripes (barrel bands)
	var band_color := outline_color
	var band_y_positions := [-half_h + 6, 0, half_h - 6]
	for by in band_y_positions:
		node.draw_line(
			Vector2(-barrel_radius, by),
			Vector2(barrel_radius, by),
			band_color, 2.5
		)

	# Outline
	node.draw_rect(rect, outline_color, false, outline_width)

	# Explosive warning symbol if explosive
	if is_explosive and not has_exploded:
		var warn_color := Color(1.0, 0.8, 0.0)
		# Small warning triangle
		var tri_size := 10.0
		var tri := PackedVector2Array([
			Vector2(0, -tri_size),
			Vector2(-tri_size * 0.7, tri_size * 0.5),
			Vector2(tri_size * 0.7, tri_size * 0.5),
		])
		node.draw_colored_polygon(tri, warn_color)
		node.draw_string(ThemeDB.fallback_font, Vector2(-3, tri_size * 0.3), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.BLACK)


func _create_collision() -> void:
	# Use capsule for rolling behavior
	var shape := CapsuleShape2D.new()
	shape.radius = barrel_radius
	shape.height = barrel_height
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_blast_zone() -> void:
	_blast_area = Area2D.new()
	_blast_area.name = "BlastZone"
	_blast_area.collision_layer = 0  # Doesn't collide as a layer
	_blast_area.collision_mask = 0b00110  # Detect objects and targets
	_blast_area.monitoring = false  # Only enabled during explosion

	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_blast_area.add_child(col)
	add_child(_blast_area)


## Trigger explosion. Applies force to nearby bodies.
func explode() -> void:
	if has_exploded:
		return
	has_exploded = true

	# Enable blast zone briefly to detect nearby objects
	if _blast_area:
		_blast_area.monitoring = true
		# Wait one physics frame for detection
		await get_tree().physics_frame

		var bodies := _blast_area.get_overlapping_bodies()
		for body in bodies:
			if body == self:
				continue
			if body is RigidBody2D:
				var direction: Vector2 = (body.global_position - global_position).normalized()
				var distance: float = global_position.distance_to(body.global_position)
				var force_factor: float = clampf(1.0 - (distance / explosion_radius), 0.0, 1.0)
				var impulse: Vector2 = direction * explosion_force * force_factor
				body.apply_central_impulse(impulse)

			# If the body is another explosive barrel, trigger it
			if body is BarrelObject and body.is_explosive and not body.has_exploded:
				body.call_deferred("explode")
			elif body is BombObject and not body.has_exploded:
				body.call_deferred("activate")

		_blast_area.monitoring = false

	# Emit chain event
	chain_event.emit("explosion", null)

	# Spawn VFX (handled by the arena/VFX system)
	# For now, just remove the barrel visually
	if _visual:
		_visual.visible = false

	# Queue removal after a short delay
	var timer := get_tree().create_timer(0.1)
	timer.timeout.connect(func(): visible = false)


## React to collisions during simulation — explode on strong impact.
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if not is_explosive or has_exploded:
		return

	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	# Explode on significant impact
	if body is RigidBody2D:
		var relative_velocity: float = linear_velocity.length()
		if relative_velocity > 100.0:  # Minimum impact velocity
			explode()
	elif body is BombObject:
		explode()


func _on_reset() -> void:
	has_exploded = false
	visible = true
	if _visual:
		_visual.visible = true
		_visual.queue_redraw()
	if _blast_area:
		_blast_area.monitoring = false


func _create_highlight() -> void:
	_highlight = Node2D.new()
	_highlight.name = "Highlight"
	_highlight.visible = false
	add_child(_highlight)
	_highlight.draw.connect(func():
		var half_h := barrel_height * 0.5
		var rect := Rect2(-barrel_radius - 4, -half_h - 4, (barrel_radius + 4) * 2, barrel_height + 8)
		_highlight.draw_rect(rect, highlight_color, false, 3.0)
	)
	_highlight.queue_redraw()
