## ImpactSpark — procedural micro-spark burst spawned at physical collision contacts.
## Gives tactile feedback to kinetic collisions and object bounces.
class_name ImpactSpark
extends Node2D

static var active_count: int = 0
const MAX_ACTIVE_SPARKS: int = 24

var _sparks: Array[Dictionary] = []
var _duration: float = 0.25
var _time: float = 0.0


static func create_at(pos: Vector2, parent: Node, color: Color = Color(1.0, 0.85, 0.3), count: int = 12) -> ImpactSpark:
	if active_count >= MAX_ACTIVE_SPARKS:
		return null
	var spark := ImpactSpark.new()
	spark.global_position = pos
	spark._init_sparks(color, count)
	parent.add_child(spark)
	active_count += 1
	spark.tree_exited.connect(func(): active_count = maxi(0, active_count - 1))
	return spark


func _init_sparks(color: Color, count: int) -> void:
	z_index = 60
	for i in count:
		var angle := randf() * TAU
		var speed := randf_range(80.0, 320.0)
		_sparks.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color,
			"size": randf_range(2.0, 4.0),
			"life": 1.0
		})


func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		queue_free()
		return

	var progress := _time / _duration
	for s in _sparks:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.9  # Drag
		s["vel"].y += 300.0 * delta  # Gravity
		s["life"] = 1.0 - progress

	queue_redraw()


func _draw() -> void:
	for s in _sparks:
		var col: Color = s["color"]
		col.a = s["life"]
		var sz: float = s["size"] * s["life"]
		draw_circle(s["pos"], sz, col)
