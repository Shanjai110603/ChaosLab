## ConfettiEffect — celebratory victory particle shower for 3-star experiment clears.
## Procedural fluttering confetti quads with tumble rotation and drag.
class_name ConfettiEffect
extends CanvasLayer

var _pieces: Array[Dictionary] = []
var _duration: float = 3.2
var _time: float = 0.0

const COLORS := [
	Color(0.0, 0.85, 1.0),    # Cyan
	Color(1.0, 0.85, 0.2),    # Gold
	Color(1.0, 0.3, 0.6),     # Neon Pink
	Color(0.2, 1.0, 0.4),     # Lime Green
	Color(1.0, 0.5, 0.1),     # Orange
	Color(0.7, 0.4, 1.0),     # Purple
]


static func spawn(parent: Node) -> ConfettiEffect:
	var effect := ConfettiEffect.new()
	parent.add_child(effect)
	return effect


func _ready() -> void:
	layer = 50
	_init_confetti()


func _init_confetti() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	# Scale count with graphics quality (default 60, max 90, min 30 on low)
	var quality: String = "medium"
	if SaveManager:
		quality = SaveManager.get_setting("graphics_quality", "medium")
	var count: int = 60  # Default medium
	match quality:
		"low":   count = 30
		"high":  count = 90

	for i in count:
		_pieces.append({
			"pos": Vector2(randf_range(50, vp_size.x - 50), randf_range(-120, -10)),
			"vel": Vector2(randf_range(-40, 40), randf_range(160, 360)),
			"rot": randf() * TAU,
			"rot_speed": randf_range(-6.0, 6.0),
			"wobble": randf() * TAU,
			"size": Vector2(randf_range(8, 14), randf_range(5, 9)),
			"color": COLORS[randi() % COLORS.size()]
		})


func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		queue_free()
		return

	for p in _pieces:
		p["wobble"] += delta * 4.0
		p["pos"].x += (p["vel"].x + sin(p["wobble"]) * 45.0) * delta
		p["pos"].y += p["vel"].y * delta
		p["rot"] += p["rot_speed"] * delta

	# Force redraw on CanvasLayer child
	var canvas_item := get_child(0) as Node2D if get_child_count() > 0 else null
	if not canvas_item:
		canvas_item = Node2D.new()
		canvas_item.name = "CanvasDrawer"
		canvas_item.draw.connect(_draw_confetti.bind(canvas_item))
		add_child(canvas_item)
	canvas_item.queue_redraw()


func _draw_confetti(node: Node2D) -> void:
	var alpha := clampf(1.0 - (_time / _duration), 0.0, 1.0)
	for p in _pieces:
		var c: Color = p["color"]
		c.a = alpha
		var half: Vector2 = p["size"] * 0.5
		var pts := PackedVector2Array([
			p["pos"] + Vector2(-half.x, -half.y).rotated(p["rot"]),
			p["pos"] + Vector2(half.x, -half.y).rotated(p["rot"]),
			p["pos"] + Vector2(half.x, half.y).rotated(p["rot"]),
			p["pos"] + Vector2(-half.x, half.y).rotated(p["rot"]),
		])
		node.draw_colored_polygon(pts, c)
