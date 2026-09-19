## Target — sci-fi laboratory bullseye target sensor.
## Goal objective. Reacts with spring wobble on graze, shatters on high-speed kinetic impact.
class_name TargetObject
extends StaticBody2D

signal target_hit(target: TargetObject)
signal target_destroyed(target: TargetObject)

@export var object_name: String = "Target"
@export var target_radius: float = 30.0
@export var min_hit_velocity: float = 35.0

var is_hit: bool = false
var is_destroyed: bool = false

var _visual: Node2D = null
var _detection_area: Area2D = null
var _wobble_tween: Tween = null
var _pulse_time: float = 0.0


func _ready() -> void:
	add_to_group("game_objects")
	add_to_group("targets")

	collision_layer = 0b00100  # Layer 3
	collision_mask = 0

	_create_visual()
	_create_collision()
	_create_detection_area()

	GameManager.state_changed.connect(_on_game_state_changed)


func _process(delta: float) -> void:
	if not is_destroyed:
		_pulse_time += delta * 3.0
		if _visual and is_hit:
			_visual.queue_redraw()


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_target.bind(_visual))
	_visual.queue_redraw()


func _draw_target(node: Node2D) -> void:
	if is_destroyed:
		# Shattered holographic static
		var ghost_col := Color(0.2, 0.5, 0.7, 0.25)
		var s := target_radius * 0.7
		node.draw_line(Vector2(-s, -s), Vector2(s, s), ghost_col, 2.0)
		node.draw_line(Vector2(-s, s), Vector2(s, -s), ghost_col, 2.0)
		node.draw_arc(Vector2.ZERO, target_radius, 0, TAU, 16, ghost_col, 1.0, true)
		return

	# Drop shadow
	node.draw_circle(Vector2(2, 3), target_radius, Color(0.02, 0.05, 0.1, 0.45))

	# Outer sci-fi ring base (deep navy/slate)
	node.draw_circle(Vector2.ZERO, target_radius, Color(0.1, 0.15, 0.22))

	# Concentric scoring bands
	var ring_colors: Array[Color] = [
		Color(0.95, 0.25, 0.25),  # Crimson ring
		Color(0.95, 0.95, 0.98),  # Pure white
		Color(0.95, 0.25, 0.25),  # Crimson mid ring
		Color(0.95, 0.95, 0.98),  # Pure white
		Color(1.0, 0.85, 0.1)     # Golden bullseye core
	]
	var radii: Array[float] = [
		target_radius * 0.88,
		target_radius * 0.68,
		target_radius * 0.48,
		target_radius * 0.28,
		target_radius * 0.14
	]

	for i in range(radii.size()):
		node.draw_circle(Vector2.ZERO, radii[i], ring_colors[i])

	# Sci-fi outer neon boundary with authentic Kenney crosshair reticle
	var rim_color := Color(0.0, 0.9, 1.0, 0.85) if not is_hit else Color(0.2, 1.0, 0.4, 0.95)
	var reticle_path := "res://assets/sprites/ui/crosshair_cyan.png"
	if ResourceLoader.exists(reticle_path):
		var reticle_tex := load(reticle_path) as Texture2D
		var r_sz := target_radius * 2.3
		node.draw_texture_rect(reticle_tex, Rect2(-r_sz * 0.5, -r_sz * 0.5, r_sz, r_sz), false, rim_color)
	else:
		node.draw_arc(Vector2.ZERO, target_radius, 0, TAU, 36, rim_color, 2.5, true)
		# 4 Crosshair tech ticks
		var tick_len := 6.0
		node.draw_line(Vector2(-target_radius - tick_len, 0), Vector2(-target_radius, 0), rim_color, 2.0)
		node.draw_line(Vector2(target_radius, 0), Vector2(target_radius + tick_len, 0), rim_color, 2.0)
		node.draw_line(Vector2(0, -target_radius - tick_len), Vector2(0, -target_radius), rim_color, 2.0)
		node.draw_line(Vector2(0, target_radius), Vector2(0, target_radius + tick_len), rim_color, 2.0)

	# Active green verified badge if target is completed
	if is_hit:
		var check_bg := Color(0.1, 0.85, 0.35)
		var offset := Vector2(target_radius * 0.55, -target_radius * 0.55)
		node.draw_circle(offset, 9.0, check_bg)
		node.draw_arc(offset, 9.0, 0, TAU, 20, Color.WHITE, 1.5, true)
		var check_path := "res://assets/sprites/ui/icon_checkmark.png"
		if ResourceLoader.exists(check_path):
			var check_tex := load(check_path) as Texture2D
			node.draw_texture_rect(check_tex, Rect2(offset - Vector2(6, 6), Vector2(12, 12)), false, Color.WHITE)
		else:
			node.draw_line(offset + Vector2(-4, 0), offset + Vector2(-1, 3.5), Color.WHITE, 2.5)
			node.draw_line(offset + Vector2(-1, 3.5), offset + Vector2(4.5, -3.5), Color.WHITE, 2.5)


func _create_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = target_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_detection_area() -> void:
	_detection_area = Area2D.new()
	_detection_area.name = "DetectionArea"
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 0b00010  # Objects (layer 2)
	_detection_area.monitoring = false

	var shape := CircleShape2D.new()
	shape.radius = target_radius * 1.25
	var col := CollisionShape2D.new()
	col.shape = shape
	_detection_area.add_child(col)
	_detection_area.body_entered.connect(_on_body_entered_detection)
	add_child(_detection_area)


func _on_body_entered_detection(body: Node) -> void:
	if is_destroyed:
		return
	if body is RigidBody2D:
		_register_hit(body)


func _register_hit(body: Node2D) -> void:
	if not is_hit:
		is_hit = true
		target_hit.emit(self)
		
		# Spring wobble juice
		if _wobble_tween and _wobble_tween.is_valid():
			_wobble_tween.kill()
		_wobble_tween = create_tween()
		_wobble_tween.tween_property(self, "scale", Vector2(1.25, 0.8), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_wobble_tween.tween_property(self, "scale", Vector2(0.9, 1.15), 0.1).set_trans(Tween.TRANS_QUAD)
		_wobble_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		if _visual:
			_visual.queue_redraw()

		ScreenVignette.flash_bullseye(0.3)
		PlatformService.haptic_medium()

	if body is RigidBody2D:
		var vel: float = body.linear_velocity.length()
		if vel > min_hit_velocity * 2.8:
			_destroy()


func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	target_destroyed.emit(self)

	# Neon shard burst
	_spawn_shatter_shards()

	# Trigger slow-motion if this is the final target in the scene
	var remaining_targets := get_tree().get_nodes_in_group("targets")
	var all_hit := remaining_targets.all(func(t): return t.is_hit or t.is_destroyed)
	if all_hit:
		SlowMotionController.trigger()

	ScreenVignette.flash_bullseye(0.5)
	CameraShake.hit_stop(0.05)  # More climactic: 0.05s vs previous 0.035s
	PlatformService.haptic_heavy()

	if _visual:
		_visual.queue_redraw()

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.01)


## Spawn 8 neon polygon shards that burst outward from the target center.
func _spawn_shatter_shards() -> void:
	const SHARD_COUNT: int = 8
	const SHARD_LIFETIME: float = 0.6
	const SHARD_SPEED_MIN: float = 130.0
	const SHARD_SPEED_MAX: float = 300.0
	const SHARD_SIZE: float = 8.0

	var parent := get_parent()
	if not parent:
		return

	# Neon cyan shards for all materials (matches target sci-fi aesthetic)
	var shard_color := Color(0.0, 0.95, 1.0, 0.9)

	for i in SHARD_COUNT:
		var angle: float = (TAU / SHARD_COUNT) * i + randf_range(-0.15, 0.15)
		var speed: float = randf_range(SHARD_SPEED_MIN, SHARD_SPEED_MAX)
		var vel := Vector2.from_angle(angle) * speed

		var shard := Node2D.new()
		shard.global_position = global_position + Vector2.from_angle(angle) * target_radius * 0.3

		var sv_color := shard_color
		var sv_size := randf_range(SHARD_SIZE * 0.6, SHARD_SIZE * 1.4)
		shard.draw.connect(func():
			shard.draw_rect(Rect2(-sv_size * 0.5, -sv_size * 0.5, sv_size, sv_size), sv_color)
		)
		parent.add_child(shard)

		# Animate shard flying outward then fading
		var t := shard.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		t.tween_property(shard, "position", shard.position + vel * SHARD_LIFETIME, SHARD_LIFETIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(shard, "modulate:a", 0.0, SHARD_LIFETIME * 0.7) \
			.set_delay(SHARD_LIFETIME * 0.3)
		t.tween_callback(shard.queue_free)


func _on_game_state_changed(_old: GameManager.GameState, new: GameManager.GameState) -> void:
	match new:
		GameManager.GameState.SIMULATING:
			if _detection_area:
				_detection_area.monitoring = true
		GameManager.GameState.PLACING:
			if _detection_area:
				_detection_area.monitoring = false


func reset() -> void:
	is_hit = false
	is_destroyed = false
	scale = Vector2.ONE
	modulate.a = 1.0
	if _detection_area:
		_detection_area.monitoring = false
	if _visual:
		_visual.queue_redraw()
