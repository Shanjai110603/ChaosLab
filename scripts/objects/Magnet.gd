## Magnet — high-intensity laboratory electromagnet apparatus.
## Emits radial magnetic flux attracting or repelling metallic physics bodies.
class_name MagnetObject
extends PhysicalObject

## Effective radius of the magnetic field in pixels.
@export var magnetic_radius: float = 320.0
## Peak magnetic force applied to nearby bodies.
@export var magnetic_force: float = 950.0
## If true, repels bodies away from the magnet instead of pulling them.
@export var is_repel: bool = false

var magnet_width: float = 64.0
var magnet_height: float = 54.0

var _field_area: Area2D = null
var _flux_pulse: float = 0.0


func _init() -> void:
	object_name = "Magnet"
	object_type = "magnet"
	object_mass = 5.0
	object_friction = 0.8
	object_bounce = 0.1
	object_gravity_scale = 1.0
	object_color = Color(0.2, 0.22, 0.28)
	outline_color = Color(0.08, 0.1, 0.14)
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	_create_magnetic_field()


func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.SIMULATING:
		_flux_pulse = wrapf(_flux_pulse + delta * 3.5, 0.0, 1.0)
		if _visual:
			_visual.queue_redraw()


func _physics_process(_delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING or freeze:
		return

	if not _field_area:
		return

	var bodies := _field_area.get_overlapping_bodies()
	for body in bodies:
		if body == self or not (body is RigidBody2D):
			continue

		var delta_pos: Vector2 = body.global_position - global_position
		var dist := delta_pos.length()
		if dist <= 0.001 or dist > magnetic_radius:
			continue

		var dir := delta_pos.normalized()
		var force_dir: Vector2 = dir if is_repel else -dir
		
		# Non-linear magnetic attenuation: (1 - d/R)^1.4
		var norm_dist := clampf(dist / magnetic_radius, 0.0, 1.0)
		var attenuation := pow(1.0 - norm_dist, 1.4)
		var impulse := force_dir * (magnetic_force * attenuation)
		body.apply_central_force(impulse)


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_magnet.bind(_visual))
	_visual.queue_redraw()


func _draw_magnet(node: Node2D) -> void:
	# Magnetic flux lines aura during simulation
	if GameManager.current_state == GameManager.GameState.SIMULATING:
		var flux_col := Color(1.0, 0.3, 0.3, 0.25) if is_repel else Color(0.0, 0.85, 1.0, 0.25)
		for ring in 3:
			var ring_progress := wrapf(_flux_pulse + float(ring) / 3.0, 0.0, 1.0)
			var r_rad := lerpf(40.0, magnetic_radius * 0.75, ring_progress)
			var alpha := sin(ring_progress * PI) * 0.35
			node.draw_arc(Vector2.ZERO, r_rad, -PI * 0.75, PI * 0.75, 24, Color(flux_col.r, flux_col.g, flux_col.b, alpha), 2.0, true)

	# Shadow
	node.draw_rect(Rect2(-magnet_width * 0.5 + 2, -magnet_height * 0.5 + 4, magnet_width, magnet_height), Color(0.02, 0.04, 0.08, 0.45), true)

	# U-Shape Base (Dark cast steel)
	var hw := magnet_width * 0.5
	var hh := magnet_height * 0.5
	node.draw_rect(Rect2(-hw, hh - 18, magnet_width, 18), Color(0.25, 0.28, 0.35))

	# Left Prong (North Pole - Vibrant Red)
	var prong_w := 18.0
	node.draw_rect(Rect2(-hw, -hh + 12, prong_w, hh * 2.0 - 26), Color(0.85, 0.2, 0.2))
	# Left Silver Cap
	node.draw_rect(Rect2(-hw, -hh, prong_w, 12), Color(0.88, 0.92, 0.96))
	# 'N' Glyph
	node.draw_line(Vector2(-hw + 5, -hh + 24), Vector2(-hw + 5, -hh + 36), Color.WHITE, 2.0)
	node.draw_line(Vector2(-hw + 5, -hh + 24), Vector2(-hw + 13, -hh + 36), Color.WHITE, 2.0)
	node.draw_line(Vector2(-hw + 13, -hh + 24), Vector2(-hw + 13, -hh + 36), Color.WHITE, 2.0)

	# Right Prong (South Pole - Vibrant Blue)
	node.draw_rect(Rect2(hw - prong_w, -hh + 12, prong_w, hh * 2.0 - 26), Color(0.15, 0.45, 0.9))
	# Right Silver Cap
	node.draw_rect(Rect2(hw - prong_w, -hh, prong_w, 12), Color(0.88, 0.92, 0.96))
	# 'S' Glyph
	node.draw_line(Vector2(hw - 6, -hh + 24), Vector2(hw - 13, -hh + 24), Color.WHITE, 2.0)
	node.draw_line(Vector2(hw - 13, -hh + 24), Vector2(hw - 13, -hh + 30), Color.WHITE, 2.0)
	node.draw_line(Vector2(hw - 13, -hh + 30), Vector2(hw - 6, -hh + 30), Color.WHITE, 2.0)
	node.draw_line(Vector2(hw - 6, -hh + 30), Vector2(hw - 6, -hh + 36), Color.WHITE, 2.0)
	node.draw_line(Vector2(hw - 6, -hh + 36), Vector2(hw - 13, -hh + 36), Color.WHITE, 2.0)

	# Center Copper Coils
	var coil_rect := Rect2(-hw + prong_w + 3, hh - 22, magnet_width - (prong_w * 2.0) - 6, 14)
	node.draw_rect(coil_rect, Color(0.85, 0.52, 0.2))
	for c in 4:
		var cx: float = coil_rect.position.x + 3 + c * 5
		node.draw_line(Vector2(cx, coil_rect.position.y), Vector2(cx, coil_rect.end.y), Color(0.55, 0.3, 0.1), 1.5)

	# Outlines
	node.draw_rect(Rect2(-hw, -hh, magnet_width, magnet_height), outline_color, false, 2.0)


func _create_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(magnet_width, magnet_height)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_magnetic_field() -> void:
	_field_area = Area2D.new()
	_field_area.name = "MagneticField"
	_field_area.collision_layer = 0
	_field_area.collision_mask = 0b00010  # Layer 2: objects

	var shape := CircleShape2D.new()
	shape.radius = magnetic_radius
	var col := CollisionShape2D.new()
	col.shape = shape
	_field_area.add_child(col)
	add_child(_field_area)


func _create_highlight() -> void:
	_highlight = Node2D.new()
	_highlight.name = "Highlight"
	_highlight.visible = false
	add_child(_highlight)
	_highlight.draw.connect(func():
		var col := valid_highlight_color if is_placement_valid else invalid_highlight_color
		var r := Rect2(-magnet_width * 0.5 - 6, -magnet_height * 0.5 - 6, magnet_width + 12, magnet_height + 12)
		_highlight.draw_rect(r, col, false, 3.0)
		_highlight.draw_rect(r, Color(col.r, col.g, col.b, 0.15))
		# Show magnetic field boundary during placement
		_highlight.draw_arc(Vector2.ZERO, magnetic_radius, 0, TAU, 36, Color(col.r, col.g, col.b, 0.3), 1.5, true)
	)
	_highlight.queue_redraw()


func _on_reset() -> void:
	super._on_reset()
	_flux_pulse = 0.0
	if _visual:
		_visual.queue_redraw()
