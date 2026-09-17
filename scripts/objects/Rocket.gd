## Rocket — directional thrust object.
## Ignites on activation, applies continuous force in facing direction.
## Optionally explodes on collision after ignition.
class_name RocketObject
extends PhysicalObject

## Thrust force applied per physics frame when ignited.
@export var thrust_force: float = 600.0
## Duration of thrust in seconds.
@export var thrust_duration: float = 2.0
## Whether the rocket explodes on collision after ignition.
@export var explodes_on_impact: bool = true
## Explosion radius if it explodes.
@export var explosion_radius: float = 120.0
## Explosion force.
@export var explosion_force: float = 600.0

## Whether this rocket is currently thrusting.
var is_ignited: bool = false
## Whether this rocket has already exploded.
var has_exploded: bool = false
## Remaining thrust time.
var _thrust_remaining: float = 0.0

## Rocket visual dimensions.
var rocket_width: float = 16.0
var rocket_height: float = 48.0

## Blast zone.
var _blast_area: Area2D = null
## Thrust direction (based on rotation).
var _thrust_direction: Vector2 = Vector2.UP


func _init() -> void:
	object_name = "Rocket"
	object_type = "rocket"
	object_mass = 0.8
	object_friction = 0.3
	object_bounce = 0.1
	object_gravity_scale = 1.0
	object_color = Color(0.8, 0.2, 0.2)  # Red
	outline_color = Color(0.5, 0.1, 0.1)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	if explodes_on_impact:
		_create_blast_zone()


func _physics_process(delta: float) -> void:
	if not is_ignited or has_exploded:
		return

	# Apply thrust in the rocket's facing direction (up in local space)
	_thrust_direction = -transform.y.normalized()  # Godot 2D: -Y is "up"
	apply_central_force(_thrust_direction * thrust_force)

	_thrust_remaining -= delta
	if _thrust_remaining <= 0:
		is_ignited = false
		# Rocket burns out but continues moving with momentum


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_rocket.bind(_visual))
	_visual.queue_redraw()


func _draw_rocket(node: Node2D) -> void:
	var hw := rocket_width * 0.5
	var hh := rocket_height * 0.5

	# Main body (elongated rectangle)
	var body_rect := Rect2(-hw, -hh, rocket_width, rocket_height * 0.75)
	node.draw_rect(body_rect, object_color)

	# Nose cone (triangle at the top / -Y)
	var nose := PackedVector2Array([
		Vector2(0, -hh - 10),
		Vector2(-hw, -hh),
		Vector2(hw, -hh),
	])
	node.draw_colored_polygon(nose, Color(0.9, 0.3, 0.3))

	# Fins at the bottom
	var fin_color := Color(0.6, 0.15, 0.15)
	var fin_left := PackedVector2Array([
		Vector2(-hw, hh * 0.25),
		Vector2(-hw - 6, hh * 0.5),
		Vector2(-hw, hh * 0.5),
	])
	var fin_right := PackedVector2Array([
		Vector2(hw, hh * 0.25),
		Vector2(hw + 6, hh * 0.5),
		Vector2(hw, hh * 0.5),
	])
	node.draw_colored_polygon(fin_left, fin_color)
	node.draw_colored_polygon(fin_right, fin_color)

	# Window/porthole
	var port_pos := Vector2(0, -hh + rocket_height * 0.3)
	node.draw_circle(port_pos, 4, Color(0.6, 0.85, 1.0))
	node.draw_arc(port_pos, 4, 0, TAU, 12, outline_color, 1.0, true)

	# Exhaust flame when ignited
	if is_ignited:
		var flame_base_y := hh * 0.5
		var flame_colors := [Color(1, 0.7, 0.1, 0.9), Color(1, 0.3, 0.05, 0.7)]
		var flame_height := randf_range(15, 25)
		var flame := PackedVector2Array([
			Vector2(-hw * 0.6, flame_base_y),
			Vector2(0, flame_base_y + flame_height),
			Vector2(hw * 0.6, flame_base_y),
		])
		node.draw_colored_polygon(flame, flame_colors[0])

	# Outline
	node.draw_rect(body_rect, outline_color, false, outline_width)


func _create_collision() -> void:
	# Capsule shape oriented vertically
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


## Ignite the rocket. Starts thrust.
func ignite() -> void:
	if is_ignited or has_exploded:
		return
	is_ignited = true
	_thrust_remaining = thrust_duration
	gravity_scale = 0.3  # Reduce gravity while thrusting
	chain_event.emit("launch", null)

	# Redraw to show flame
	if _visual:
		# Continuously redraw for flame animation
		_start_flame_animation()


func _start_flame_animation() -> void:
	if not is_ignited:
		return
	if _visual and is_inside_tree():
		_visual.queue_redraw()
		get_tree().create_timer(0.05).timeout.connect(_start_flame_animation)


## Explode the rocket.
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
				var direction: Vector2 = (body.global_position - global_position).normalized()
				var distance: float = global_position.distance_to(body.global_position)
				var force_factor: float = clampf(1.0 - (distance / explosion_radius), 0.0, 1.0)
				body.apply_central_impulse(direction * explosion_force * force_factor)

			if body is BarrelObject and body.is_explosive and not body.has_exploded:
				body.call_deferred("explode")
			elif body is BombObject and not body.has_exploded:
				body.call_deferred("activate")

		_blast_area.monitoring = false

	chain_event.emit("explosion", null)
	if _visual:
		_visual.visible = false
	var timer := get_tree().create_timer(0.1)
	timer.timeout.connect(func(): visible = false)


## Collision handling — explode on impact when ignited.
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if not is_ignited or has_exploded:
		return

	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	if explodes_on_impact and body is StaticBody2D:
		# Explode on wall collision
		explode()
	elif explodes_on_impact and body is GameObject:
		# Explode on hitting another game object
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
		var hw := rocket_width * 0.5 + 4
		var hh := rocket_height * 0.5 + 4
		var rect := Rect2(-hw, -hh, hw * 2, hh * 2)
		_highlight.draw_rect(rect, highlight_color, false, 3.0)
	)
	_highlight.queue_redraw()
