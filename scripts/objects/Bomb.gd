## Bomb — core explosive catalyst with timed fuse and massive radial impulse.
## Cartoon laboratory bomb with lit fuse, pulsing core, and exponential shockwave.
class_name BombObject
extends PhysicalObject

## Fuse duration in seconds before explosion.
@export var fuse_time: float = 1.6
## Explosion radius in pixels.
@export var explosion_radius: float = 220.0
## Explosion force applied to nearby bodies.
@export var explosion_force: float = 1350.0

## Bomb visual radius.
var bomb_radius: float = 22.0

## Fuse state.
var is_fuse_active: bool = false
var has_exploded: bool = false
var _fuse_remaining: float = 0.0
var _flash_timer: float = 0.0
var _flash_on: bool = false
var _spark_flicker: float = 0.0

## Blast zone Area2D.
var _blast_area: Area2D = null


func _init() -> void:
	object_name = "Bomb"
	object_type = "bomb"
	object_mass = 1.2
	object_friction = 0.45
	object_bounce = 0.15
	object_gravity_scale = 1.0
	object_color = Color(0.12, 0.14, 0.18)      # Matte cast-iron black
	outline_color = Color(0.3, 0.08, 0.08)
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	_create_blast_zone()


func _process(delta: float) -> void:
	if not is_fuse_active or has_exploded:
		return

	_fuse_remaining -= delta
	_flash_timer -= delta
	_spark_flicker += delta * 25.0

	# Accelerating flash strobe as countdown approaches zero
	var progress := 1.0 - clampf(_fuse_remaining / fuse_time, 0.0, 1.0)
	var flash_interval := lerpf(0.28, 0.04, progress)
	
	if _flash_timer <= 0.0:
		_flash_on = not _flash_on
		_flash_timer = flash_interval

	if _visual:
		_visual.queue_redraw()

	if _fuse_remaining <= 0.0:
		explode()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_bomb.bind(_visual))
	_visual.queue_redraw()


func _draw_bomb(node: Node2D) -> void:
	# Drop shadow
	node.draw_circle(Vector2(2, 3), bomb_radius, Color(0.02, 0.04, 0.08, 0.5))

	# Cast iron body
	var body_color: Color = Color(0.9, 0.18, 0.18) if _flash_on else object_color
	node.draw_circle(Vector2.ZERO, bomb_radius, body_color)

	# 3D spherical specular highlight
	var spec_pos := Vector2(-bomb_radius * 0.35, -bomb_radius * 0.35)
	node.draw_circle(spec_pos, bomb_radius * 0.3, Color(1.0, 1.0, 1.0, 0.25 if not _flash_on else 0.6))
	node.draw_circle(spec_pos + Vector2(1, 1), bomb_radius * 0.12, Color(1.0, 1.0, 1.0, 0.6 if not _flash_on else 0.9))

	# Brass neck collar
	var neck_rect := Rect2(-5, -bomb_radius - 4, 10, 5)
	node.draw_rect(neck_rect, Color(0.75, 0.6, 0.25))
	node.draw_rect(neck_rect, Color(0.35, 0.25, 0.1), false, 1.0)

	# Curved fuse wick
	if not has_exploded:
		var progress := 1.0 - clampf(_fuse_remaining / fuse_time, 0.0, 1.0) if is_fuse_active else 0.0
		var wick_height := lerpf(14.0, 2.0, progress)
		var fuse_start := Vector2(0, -bomb_radius - 4)
		var fuse_mid := Vector2(4, -bomb_radius - 4 - wick_height * 0.5)
		var fuse_end := Vector2(3, -bomb_radius - 4 - wick_height)

		node.draw_line(fuse_start, fuse_mid, Color(0.65, 0.55, 0.4), 2.5)
		node.draw_line(fuse_mid, fuse_end, Color(0.65, 0.55, 0.4), 2.5)

		# Animated sparkling flame at fuse tip
		if is_fuse_active:
			var flame_size := 4.0 + sin(_spark_flicker) * 1.5
			# Outer yellow glow
			node.draw_circle(fuse_end, flame_size + 3.0, Color(1.0, 0.8, 0.0, 0.35))
			# Mid orange flame
			node.draw_circle(fuse_end, flame_size, Color(1.0, 0.4, 0.05, 0.9))
			# White hot core
			node.draw_circle(fuse_end, flame_size * 0.4, Color(1.0, 1.0, 0.85, 1.0))

	# Hazardous skull / cross emblem
	var emblem_col := Color(1.0, 1.0, 1.0, 0.85) if _flash_on else Color(0.65, 0.2, 0.2, 0.7)
	var es := bomb_radius * 0.35
	node.draw_line(Vector2(-es, -es), Vector2(es, es), emblem_col, 2.5)
	node.draw_line(Vector2(-es, es), Vector2(es, -es), emblem_col, 2.5)

	# Outer outline
	node.draw_arc(Vector2.ZERO, bomb_radius, 0, TAU, 36, outline_color, outline_width, true)


func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = bomb_radius
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


## Activate fuse countdown.
func activate() -> void:
	if is_fuse_active or has_exploded:
		return
	is_fuse_active = true
	_fuse_remaining = fuse_time
	_flash_timer = 0.25
	chain_event.emit("ignition", null)
	if _visual:
		_visual.queue_redraw()


## Trigger the detonation.
func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	is_fuse_active = false

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

			# Chain triggers
			if body is BarrelObject and body.is_explosive and not body.has_exploded:
				body.call_deferred("explode")
			elif body is BombObject and not body.has_exploded:
				body.call_deferred("activate")
			elif body is RocketObject and not body.is_ignited:
				body.call_deferred("ignite")

		_blast_area.monitoring = false

	chain_event.emit("explosion", null)

	# Spawn explosion VFX
	if get_parent():
		ExplosionEffect.create_at(global_position, get_parent(), explosion_radius)

	# Heavy camera shake trauma & hit-stop micro-pause
	CameraShake.shake(0.85, 0.35)
	CameraShake.hit_stop(0.045)
	PlatformService.haptic_heavy()

	if _visual:
		_visual.visible = false
	visible = false


## Collision handling — ignite fuse on impact.
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if has_exploded or is_fuse_active:
		return

	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	if body is RigidBody2D or body is StaticBody2D:
		activate()


func _on_reset() -> void:
	has_exploded = false
	is_fuse_active = false
	_fuse_remaining = 0.0
	_flash_on = false
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
		_highlight.draw_arc(Vector2.ZERO, bomb_radius + 6, 0, TAU, 36, col, 3.5, true)
		_highlight.draw_circle(Vector2.ZERO, bomb_radius + 6, Color(col.r, col.g, col.b, 0.15))
	)
	_highlight.queue_redraw()
