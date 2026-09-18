## Explosion visual effect — 4-layer procedural kinetic and particle burst.
## Flash core, shockwave ring, incandescent shrapnel sparks, and rising smoke puffs.
class_name ExplosionEffect
extends Node2D

@export var radius: float = 140.0
@export var duration: float = 0.65
@export var explosion_color: Color = Color(1.0, 0.55, 0.1)

var _time: float = 0.0
var _sparks: Array[Dictionary] = []
var _smoke: Array[Dictionary] = []
var _is_active: bool = false


func _ready() -> void:
	z_index = 80
	_spawn_particles()
	_is_active = true

	# Trigger screen flash
	ScreenVignette.flash_explosion(0.4)


func _process(delta: float) -> void:
	if not _is_active:
		return

	_time += delta
	if _time >= duration:
		queue_free()
		return

	# Update sparks (fast, gravity-affected)
	for s in _sparks:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.92  # Air drag
		s["vel"].y += 280.0 * delta  # Gravity
		s["life"] = maxf(s["life"] - delta / duration, 0.0)

	# Update smoke (slower, drifting upward)
	for sm in _smoke:
		sm["pos"] += sm["vel"] * delta
		sm["vel"].y -= 45.0 * delta  # Upward buoyancy
		sm["size"] += delta * 18.0  # Expanding puff
		sm["life"] = maxf(sm["life"] - delta / duration, 0.0)

	queue_redraw()


func _draw() -> void:
	var progress: float = _time / duration

	# 1. Flash Core (first 15% of duration)
	if progress < 0.15:
		var flash_progress := progress / 0.15
		var flash_alpha := 1.0 - flash_progress
		var flash_r := radius * 0.45 * (1.0 + flash_progress * 0.5)
		draw_circle(Vector2.ZERO, flash_r, Color(1.0, 0.95, 0.85, flash_alpha * 0.9))
		draw_circle(Vector2.ZERO, flash_r * 0.5, Color(1.0, 1.0, 1.0, flash_alpha))

	# 2. Expanding Shockwave Ring (first 45% of duration)
	if progress < 0.5:
		var ring_progress := progress / 0.5
		var ring_radius := radius * 1.1 * ring_progress
		var ring_alpha := (1.0 - ring_progress) * 0.75
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 36, Color(1.0, 0.75, 0.2, ring_alpha), 3.5, true)
		draw_arc(Vector2.ZERO, ring_radius * 0.85, 0, TAU, 28, Color(1.0, 0.95, 0.5, ring_alpha * 0.5), 1.5, true)

	# 3. Volumetric Rising Smoke Puffs
	for sm in _smoke:
		var alpha: float = sm["life"] * 0.35
		var col: Color = sm["color"]
		col.a = alpha
		draw_circle(sm["pos"], sm["size"], col)

	# 4. Incandescent Shrapnel Sparks
	for s in _sparks:
		var alpha: float = s["life"]
		var col: Color = s["color"]
		col.a = alpha
		var sz: float = s["size"] * alpha
		draw_circle(s["pos"], sz, col)


func _spawn_particles() -> void:
	# Sparks (incandescent hot embers)
	var spark_count := 26
	for i in spark_count:
		var angle := randf() * TAU
		var speed := randf_range(160.0, 520.0)
		var spark_color := Color(1.0, randf_range(0.6, 0.9), 0.1) if randf() < 0.7 else Color(1.0, 0.3, 0.05)
		_sparks.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(2.5, 5.5),
			"color": spark_color,
			"life": 1.0
		})

	# Volumetric Smoke
	var smoke_count := 12
	for i in smoke_count:
		var angle := randf() * TAU
		var dist := randf_range(5.0, 30.0)
		_smoke.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"vel": Vector2(randf_range(-30, 30), randf_range(-20, 20)),
			"size": randf_range(12.0, 24.0),
			"color": Color(0.2, 0.22, 0.26),
			"life": 1.0
		})


static func create_at(pos: Vector2, parent: Node, size: float = 140.0) -> ExplosionEffect:
	var effect := ExplosionEffect.new()
	effect.radius = size
	effect.global_position = pos
	parent.add_child(effect)
	return effect
