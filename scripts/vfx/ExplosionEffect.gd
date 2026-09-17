## Explosion visual effect — procedural particle-like burst.
## Spawned at explosion locations. Self-destructs after animation completes.
class_name ExplosionEffect
extends Node2D

## Explosion visual radius.
@export var radius: float = 100.0
## Duration of the effect.
@export var duration: float = 0.6
## Color of the explosion.
@export var explosion_color: Color = Color(1, 0.6, 0.1)
## Secondary color (smoke).
@export var smoke_color: Color = Color(0.3, 0.3, 0.3, 0.5)

## Internal state.
var _time: float = 0.0
var _particles: Array[Dictionary] = []
var _is_active: bool = false


func _ready() -> void:
	z_index = 100
	_spawn_particles()
	_is_active = true


func _process(delta: float) -> void:
	if not _is_active:
		return

	_time += delta
	if _time >= duration:
		queue_free()
		return

	# Update particles
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.95  # Drag
		p["vel"].y += 200.0 * delta  # Gravity on particles
		p["life"] -= delta
		p["size"] *= 0.97

	queue_redraw()


func _draw() -> void:
	var progress: float = _time / duration

	# Flash ring
	if progress < 0.15:
		var flash_alpha: float = 1.0 - (progress / 0.15)
		var flash_radius: float = radius * (progress / 0.15)
		draw_arc(Vector2.ZERO, flash_radius, 0, TAU, 24, Color(1, 1, 0.8, flash_alpha), 4.0, true)

	# Shockwave ring
	if progress < 0.4:
		var ring_progress: float = progress / 0.4
		var ring_radius: float = radius * ring_progress
		var ring_alpha: float = 1.0 - ring_progress
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(1, 0.7, 0.2, ring_alpha * 0.6), 3.0, true)

	# Particles
	for p in _particles:
		if p["life"] > 0:
			var alpha: float = clampf(p["life"] / p["max_life"], 0.0, 1.0)
			var color: Color = p["color"]
			color.a = alpha
			var size: float = maxf(p["size"], 1.0)
			draw_circle(p["pos"], size, color)

	# Center glow
	if progress < 0.3:
		var glow_alpha: float = (1.0 - progress / 0.3) * 0.7
		var glow_size: float = radius * 0.3 * (1.0 - progress / 0.3)
		draw_circle(Vector2.ZERO, glow_size, Color(1, 0.9, 0.5, glow_alpha))


func _spawn_particles() -> void:
	var particle_count := 20
	for i in particle_count:
		var angle: float = randf() * TAU
		var speed: float = randf_range(100, 400)
		var life: float = randf_range(0.2, duration * 0.9)
		var size: float = randf_range(3, 8)

		# Mix between fire and smoke colors
		var color: Color
		if randf() < 0.6:
			color = explosion_color.lerp(Color(1, 0.2, 0.05), randf())
		else:
			color = smoke_color

		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": life,
			"max_life": life,
			"size": size,
			"color": color,
		})


## Convenience factory method.
static func create_at(pos: Vector2, parent: Node, size: float = 100.0) -> ExplosionEffect:
	var effect := ExplosionEffect.new()
	effect.radius = size
	effect.global_position = pos
	parent.add_child(effect)
	return effect
