## Rocket — directional thrust projectile with impact trigger and explosive warhead.
## Propels itself forward when ignited, trailing flames, and detonates on obstacle collision.
class_name RocketObject
extends PhysicalObject

## Thrust force applied continuously while ignited.
@export var thrust_force: float = 750.0
## Duration of thrust in seconds.
@export var thrust_duration: float = 2.4
## Explosion radius on impact.
@export var explosion_radius: float = 140.0
## Explosion force on impact.
@export var explosion_force: float = 800.0

## State.
var is_ignited: bool = false
var has_exploded: bool = false
var _thrust_remaining: float = 0.0
var _flame_flicker: float = 0.0

## Dimensions.
var rocket_width: float = 18.0
var rocket_height: float = 52.0

## Blast zone.
var _blast_area: Area2D = null


func _init() -> void:
	object_name = "Rocket"
	object_type = "rocket"
	object_mass = 0.9
	object_friction = 0.25
	object_bounce = 0.12
	object_gravity_scale = 1.0
	object_color = Color(0.92, 0.28, 0.24)      # Crimson racer
	outline_color = Color(0.4, 0.1, 0.1)
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	_create_blast_zone()


func _physics_process(delta: float) -> void:
	if not is_ignited or has_exploded:
		return

	_flame_flicker += delta * 30.0

	# Apply thrust in rocket's facing direction (local -Y)
	var thrust_dir := -transform.y.normalized()
	apply_central_force(thrust_dir * thrust_force)

	_thrust_remaining -= delta
	if _visual:
		_visual.queue_redraw()

	if _thrust_remaining <= 0.0:
		is_ignited = false
		gravity_scale = object_gravity_scale
		if _visual:
			_visual.queue_redraw()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_rocket.bind(_visual))
	_visual.queue_redraw()


func _draw_rocket(node: Node2D) -> void:
	var hw := rocket_width * 0.5
	var hh := rocket_height * 0.5

	# Drop shadow
	node.draw_rect(Rect2(-hw + 2, -hh + 3, rocket_width, rocket_height), Color(0.02, 0.05, 0.1, 0.35))

	# Aerodynamic cylindrical body
	var body_rect := Rect2(-hw, -hh + 10, rocket_width, rocket_height - 18)
	node.draw_rect(body_rect, Color(0.95, 0.95, 0.98))  # Sleek white lab hull

	# Center red racing stripe
	node.draw_rect(Rect2(-hw * 0.4, -hh + 10, hw * 0.8, rocket_height - 18), object_color)

	# Nose cone (aerodynamic metallic point at -Y)
	var nose := PackedVector2Array([
		Vector2(0, -hh - 8),
		Vector2(-hw, -hh + 10),
		Vector2(hw, -hh + 10)
	])
	node.draw_colored_polygon(nose, object_color)
	# Nose tip highlight
	node.draw_circle(Vector2(0, -hh - 4), 2.5, Color(1.0, 0.85, 0.85))

	# Delta stabilizing fins
	var fin_color := Color(0.75, 0.18, 0.18)
	var fin_left := PackedVector2Array([
		Vector2(-hw, hh - 22),
		Vector2(-hw - 8, hh - 4),
		Vector2(-hw, hh - 4)
	])
	var fin_right := PackedVector2Array([
		Vector2(hw, hh - 22),
		Vector2(hw + 8, hh - 4),
		Vector2(hw, hh - 4)
	])
	node.draw_colored_polygon(fin_left, fin_color)
	node.draw_colored_polygon(fin_right, fin_color)

	# Metallic exhaust bell nozzle at base
	var nozzle := PackedVector2Array([
		Vector2(-hw * 0.7, hh - 8),
		Vector2(-hw * 0.9, hh),
		Vector2(hw * 0.9, hh),
		Vector2(hw * 0.7, hh - 8)
	])
	node.draw_colored_polygon(nozzle, Color(0.3, 0.35, 0.4))

	# Cockpit glass porthole
	var port_y := -hh + 20
	node.draw_circle(Vector2(0, port_y), 4.5, Color(0.1, 0.8, 1.0, 0.85))
	node.draw_arc(Vector2(0, port_y), 4.5, 0, TAU, 16, Color(0.2, 0.4, 0.6), 1.2, true)
	node.draw_circle(Vector2(-1.5, port_y - 1.5), 1.5, Color.WHITE)

	# Animated jet flame exhaust when ignited
	if is_ignited:
		var flame_y := hh
		var flame_len := 22.0 + sin(_flame_flicker) * 7.0
		
		# Outer red/orange plume
		var flame_outer := PackedVector2Array([
			Vector2(-hw * 0.8, flame_y),
			Vector2(0, flame_y + flame_len),
			Vector2(hw * 0.8, flame_y)
		])
		node.draw_colored_polygon(flame_outer, Color(1.0, 0.35, 0.05, 0.85))

		# Inner bright yellow jet
		var flame_inner := PackedVector2Array([
			Vector2(-hw * 0.45, flame_y),
			Vector2(0, flame_y + flame_len * 0.65),
			Vector2(hw * 0.45, flame_y)
		])
		node.draw_colored_polygon(flame_inner, Color(1.0, 0.9, 0.2, 0.95))

		# Core white-hot ignition point
		node.draw_circle(Vector2(0, flame_y + 3), 3.5, Color(1.0, 1.0, 1.0, 0.9))

	# Crisp outlines
	node.draw_rect(body_rect, outline_color, false, 1.5)


func _create_collision() -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = rocket_width * 0.5
	shape.height = rocket_height
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_blast_zone() -> void:
	_blast_area = Area2D.new()
	_blast_area.name = "BlastZone"
	_blast_area.collision_layer = 0
	_blast_area.collision_mask = 0b00110
	_blast_area.monitoring = false

	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_blast_area.add_child(col)
	add_child(_blast_area)


## Ignite rocket engines.
func ignite() -> void:
	if is_ignited or has_exploded:
		return
	is_ignited = true
	_thrust_remaining = thrust_duration
	gravity_scale = 0.25  # Streamlined flight
	chain_event.emit("launch", null)
	if _visual:
		_visual.queue_redraw()


## Detonate rocket warhead.
func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	is_ignited = false

	if _blast_area:
		_blast_area.monitoring = true
		await get_tree().physics_frame

		var bodies := _blast_area.get_overlapping_bodies()
		for body in bodies:
			if body == self:
				continue
			if body is RigidBody2D:
				var delta_pos: Vector2 = body.global_position - global_position
				var distance: float = delta_pos.length()
				var direction: Vector2 = delta_pos.normalized() if distance > 0.001 else Vector2.UP
				var normalized_dist := clampf(distance / explosion_radius, 0.0, 1.0)
				var force_factor := (1.0 - normalized_dist) * (1.0 - normalized_dist)
				body.apply_central_impulse(direction * explosion_force * force_factor)

			if body is BarrelObject and body.is_explosive and not body.has_exploded:
				body.call_deferred("explode")
			elif body is BombObject and not body.has_exploded:
				body.call_deferred("activate")

		_blast_area.monitoring = false

	chain_event.emit("explosion", null)

	# Spawn explosion VFX
	if get_parent():
		ExplosionEffect.create_at(global_position, get_parent(), explosion_radius)

	CameraShake.shake(0.55, 0.2)

	if _visual:
		_visual.visible = false
	visible = false


func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if has_exploded:
		return

	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	# Rocket hits a BreakableWall — guaranteed fracture regardless of velocity
	if body is BreakableWall:
		body.take_explosion_damage(999.0, global_position)  # Instant fracture
		return

	# If not yet ignited, impact will trigger ignition!
	if not is_ignited:
		if body is RigidBody2D or body is GameObject:
			ignite()
		return

	# If already ignited and cruising, hitting walls or solid objects causes detonation
	if is_ignited:
		explode()


func _on_reset() -> void:
	is_ignited = false
	has_exploded = false
	_thrust_remaining = 0.0
	gravity_scale = object_gravity_scale
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
		var col := valid_highlight_color if is_placement_valid else invalid_highlight_color
		var hw := rocket_width * 0.5 + 6
		var hh := rocket_height * 0.5 + 8
		var rect := Rect2(-hw, -hh, hw * 2, hh * 2)
		_highlight.draw_rect(rect, col, false, 3.5)
		_highlight.draw_rect(rect, Color(col.r, col.g, col.b, 0.15))
	)
	_highlight.queue_redraw()
