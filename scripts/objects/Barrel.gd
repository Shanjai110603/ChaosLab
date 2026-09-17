## Barrel — rolling industrial chemical drum with explosive payload.
## Rolling capsule collision, hazard warning decals, impact threshold trigger.
class_name BarrelObject
extends PhysicalObject

## Barrel dimensions.
@export var barrel_radius: float = 22.0
@export var barrel_height: float = 52.0

## Explosive properties.
@export_group("Explosive")
@export var is_explosive: bool = true
@export var explosion_radius: float = 175.0
@export var explosion_force: float = 950.0
@export var min_impact_velocity: float = 90.0

## State flags.
var has_exploded: bool = false
var is_primed_to_explode: bool = false
var _detonation_delay: float = 0.08

## Blast zone Area2D for detecting nearby objects.
var _blast_area: Area2D = null


func _init() -> void:
	object_name = "Barrel"
	object_type = "barrel"
	object_mass = 1.8
	object_friction = 0.35
	object_bounce = 0.22
	object_gravity_scale = 1.0
	object_color = Color(0.85, 0.22, 0.12)      # Hazard crimson red
	outline_color = Color(0.35, 0.08, 0.04)     # Deep industrial red
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


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

	# Drop shadow
	node.draw_rect(Rect2(-barrel_radius + 2, -half_h + 3, barrel_radius * 2, barrel_height), Color(0.02, 0.05, 0.1, 0.4))

	# Main drum body
	node.draw_rect(rect, object_color)

	# 3D shading — subtle gradient highlight across vertical cylindrical axis
	var highlight_rect := Rect2(-barrel_radius * 0.5, -half_h, barrel_radius * 0.6, barrel_height)
	node.draw_rect(highlight_rect, Color(1.0, 1.0, 1.0, 0.12))

	# Heavy reinforced steel bands
	var steel_col := Color(0.2, 0.22, 0.26)
	var band_positions := [-half_h + 8, -half_h * 0.35, half_h * 0.35, half_h - 8]
	for by in band_positions:
		node.draw_line(Vector2(-barrel_radius, by), Vector2(barrel_radius, by), steel_col, 3.5)
		node.draw_line(Vector2(-barrel_radius, by - 1), Vector2(barrel_radius, by - 1), Color(0.5, 0.55, 0.6, 0.6), 1.0)

	# Center hazard tape banner
	if is_explosive and not has_exploded:
		var banner_h := 14.0
		var banner_rect := Rect2(-barrel_radius, -banner_h * 0.5, barrel_radius * 2, banner_h)
		node.draw_rect(banner_rect, Color(0.95, 0.8, 0.0))
		
		# Hazard diagonal black stripes
		var stripe_w := 6.0
		var sx := -barrel_radius
		while sx < barrel_radius:
			var pts := PackedVector2Array([
				Vector2(sx, -banner_h * 0.5),
				Vector2(sx + stripe_w * 0.6, -banner_h * 0.5),
				Vector2(sx + stripe_w * 1.2, banner_h * 0.5),
				Vector2(sx + stripe_w * 0.6, banner_h * 0.5)
			])
			node.draw_colored_polygon(pts, Color(0.1, 0.1, 0.12))
			sx += stripe_w * 1.4

	# Outer outline
	node.draw_rect(rect, outline_color, false, outline_width)


func _create_collision() -> void:
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
	_blast_area.collision_layer = 0
	_blast_area.collision_mask = 0b00110  # Objects (2) and targets (3)
	_blast_area.monitoring = false

	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_blast_area.add_child(col)
	add_child(_blast_area)


## Trigger explosion with quadratic distance falloff impulse.
func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	is_primed_to_explode = false

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
				
				# Quadratic shockwave falloff: (1 - d/R)^2
				var normalized_dist := clampf(distance / explosion_radius, 0.0, 1.0)
				var force_factor := (1.0 - normalized_dist) * (1.0 - normalized_dist)
				var impulse: Vector2 = direction * explosion_force * force_factor
				body.apply_central_impulse(impulse)

			# Cascading chain reaction
			if body is BarrelObject and body.is_explosive and not body.has_exploded:
				body.call_deferred("explode")
			elif body is BombObject and not body.has_exploded:
				body.call_deferred("activate")
			elif body is RocketObject and not body.is_ignited:
				body.call_deferred("ignite")

		_blast_area.monitoring = false

	# Emit chain reaction event with position
	chain_event.emit("explosion", null)

	# Spawn explosion VFX
	if get_parent():
		ExplosionEffect.create_at(global_position, get_parent(), explosion_radius)

	# Trigger camera shake & floating boom text
	CameraShake.shake(0.6, 0.25)

	# Visual hide & reset ready
	if _visual:
		_visual.visible = false
	visible = false


## Collision detection for impact detonation.
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if not is_explosive or has_exploded:
		return

	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	if body is RigidBody2D:
		var rel_speed := (linear_velocity - body.linear_velocity).length()
		if rel_speed >= min_impact_velocity:
			explode()
	elif body is BombObject:
		explode()


func _on_reset() -> void:
	has_exploded = false
	is_primed_to_explode = false
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
		var half_h := barrel_height * 0.5
		var rect := Rect2(-barrel_radius - 5, -half_h - 5, (barrel_radius + 5) * 2, barrel_height + 10)
		_highlight.draw_rect(rect, col, false, 3.5)
		_highlight.draw_rect(rect, Color(col.r, col.g, col.b, 0.15))
	)
	_highlight.queue_redraw()
