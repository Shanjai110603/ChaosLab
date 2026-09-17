## Bomb — major chain reaction trigger with fuse timer.
## Activates on impact or manually. Fuse countdown, then large explosion.
class_name BombObject
extends PhysicalObject

## Fuse duration in seconds before explosion.
@export var fuse_time: float = 1.5
## Explosion radius.
@export var explosion_radius: float = 200.0
## Explosion force applied to nearby bodies.
@export var explosion_force: float = 1200.0

## Whether this bomb is currently counting down.
var is_fuse_active: bool = false
## Whether this bomb has already exploded.
var has_exploded: bool = false
## Time remaining on the fuse.
var _fuse_remaining: float = 0.0
## Visual fuse flash timer.
var _flash_timer: float = 0.0
## Whether the visual is in the "flash" state.
var _flash_on: bool = false

## Blast zone Area2D.
var _blast_area: Area2D = null
## Bomb radius for visuals.
var bomb_radius: float = 20.0


func _init() -> void:
	object_name = "Bomb"
	object_type = "bomb"
	object_mass = 1.0
	object_friction = 0.5
	object_bounce = 0.1
	object_gravity_scale = 1.0
	object_color = Color(0.15, 0.15, 0.15)  # Dark grey/black
	outline_color = Color(0.4, 0.1, 0.1)


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

	# Flash effect speeds up as fuse gets shorter
	var flash_rate: float = lerpf(0.3, 0.05, 1.0 - (_fuse_remaining / fuse_time))
	if _flash_timer <= 0:
		_flash_on = not _flash_on
		_flash_timer = flash_rate
		if _visual:
			_visual.queue_redraw()

	if _fuse_remaining <= 0:
		explode()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_bomb.bind(_visual))
	_visual.queue_redraw()


func _draw_bomb(node: Node2D) -> void:
	# Main body — dark circle
	var color: Color = Color.RED if _flash_on else object_color
	node.draw_circle(Vector2.ZERO, bomb_radius, color)
	node.draw_arc(Vector2.ZERO, bomb_radius, 0, TAU, 32, outline_color, outline_width, true)

	# Fuse wick at top
	if not has_exploded:
		var fuse_start := Vector2(0, -bomb_radius)
		var fuse_end := Vector2(4, -bomb_radius - 12)
		var fuse_color: Color = Color.ORANGE if is_fuse_active else Color(0.5, 0.4, 0.2)
		node.draw_line(fuse_start, fuse_end, fuse_color, 2.0)

		# Spark at fuse tip when active
		if is_fuse_active:
			var spark_color := Color(1, 0.8, 0.2, 0.9)
			node.draw_circle(fuse_end, 4, spark_color)

	# Skull/danger symbol — simplified X
	var sym_color := Color(0.6, 0.6, 0.6) if not _flash_on else Color.WHITE
	var s := bomb_radius * 0.35
	node.draw_line(Vector2(-s, -s), Vector2(s, s), sym_color, 2.0)
	node.draw_line(Vector2(-s, s), Vector2(s, -s), sym_color, 2.0)


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
	_blast_area.collision_mask = 0b00110  # Objects + targets
	_blast_area.monitoring = false

	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_blast_area.add_child(col)
	add_child(_blast_area)


## Activate the bomb fuse. Called on impact or manually.
func activate() -> void:
	if is_fuse_active or has_exploded:
		return
	is_fuse_active = true
	_fuse_remaining = fuse_time
	_flash_timer = 0.3
	chain_event.emit("ignition", null)


## Trigger the explosion immediately.
func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	is_fuse_active = false

	# Enable blast zone to detect nearby objects
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
				var impulse: Vector2 = direction * explosion_force * force_factor
				body.apply_central_impulse(impulse)

			# Chain trigger other explosives
			if body is BarrelObject and body.is_explosive and not body.has_exploded:
				body.call_deferred("explode")
			elif body is BombObject and not body.has_exploded:
				body.call_deferred("activate")
			elif body is RocketObject and not body.is_ignited:
				body.call_deferred("ignite")

		_blast_area.monitoring = false

	chain_event.emit("explosion", null)

	# Hide the bomb
	if _visual:
		_visual.visible = false

	var timer := get_tree().create_timer(0.1)
	timer.timeout.connect(func(): visible = false)


## React to collisions — activate fuse on impact.
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)

	if has_exploded or is_fuse_active:
		return

	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	# Activate on any collision during simulation
	if body is RigidBody2D:
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
		_highlight.draw_arc(Vector2.ZERO, bomb_radius + 4, 0, TAU, 32, highlight_color, 3.0, true)
	)
	_highlight.queue_redraw()
