## Portal — linked quantum wormhole teleportation apparatus.
## Transfers physics momentum across spacetime coordinates.
class_name PortalObject
extends PhysicalObject

## Unique identifier for this portal (e.g. "portal_a" or "portal_b").
@export var portal_tag: String = "portal_a"
## Tag of target portal to teleport to (if empty, automatically links to counterpart).
@export var target_portal_tag: String = ""
## Color channel theme for this portal (cyan for alpha, orange/magenta for beta).
@export var portal_color: Color = Color(0.0, 0.85, 1.0)

var portal_radius_x: float = 48.0
var portal_radius_y: float = 24.0

var _horizon_area: Area2D = null
var _vortex_angle: float = 0.0
var _teleport_cooldowns: Dictionary = {}  # Body -> timestamp_ms


func _init() -> void:
	object_name = "Portal"
	object_type = "portal"
	object_mass = 10.0
	object_friction = 0.5
	object_bounce = 0.0
	object_gravity_scale = 0.0
	object_color = Color(0.08, 0.1, 0.16)
	outline_color = Color(0.0, 0.85, 1.0)
	valid_highlight_color = Color(0.0, 1.0, 0.85, 0.8)


func _ready() -> void:
	super._ready()
	_create_visual()
	_create_collision()
	_create_horizon_area()


func _process(delta: float) -> void:
	_vortex_angle += delta * 4.0
	if _visual:
		_visual.queue_redraw()


func _physics_process(_delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING or freeze:
		return

	# Clean up cooldowns
	var now := Time.get_ticks_msec()
	var to_remove := []
	for body in _teleport_cooldowns:
		if now - _teleport_cooldowns[body] > 400:
			to_remove.append(body)
	for b in to_remove:
		_teleport_cooldowns.erase(b)


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_portal.bind(_visual))
	_visual.queue_redraw()


func _draw_portal(node: Node2D) -> void:
	var col := portal_color

	# Outer glowing aura
	node.draw_circle(Vector2.ZERO, portal_radius_x + 6.0, Color(col.r, col.g, col.b, 0.15))

	# Metallic Emitter Ring Chassis
	var frame_rect := Rect2(-portal_radius_x - 8, -portal_radius_y - 6, (portal_radius_x + 8) * 2, (portal_radius_y + 6) * 2)
	node.draw_rect(frame_rect, Color(0.12, 0.14, 0.2), false, 4.0)

	# Emitter nodes at poles
	node.draw_circle(Vector2(-portal_radius_x - 6, 0), 7.0, col)
	node.draw_circle(Vector2(portal_radius_x + 6, 0), 7.0, col)

	# Event Horizon Swirling Vortex
	node.draw_rect(Rect2(-portal_radius_x, -portal_radius_y, portal_radius_x * 2, portal_radius_y * 2), Color(0.02, 0.04, 0.08, 0.95))

	# Rotating spiral rings
	for i in 4:
		var a: float = _vortex_angle + (i * PI * 0.5)
		var inner_rad := 12.0 + i * 7.0
		var pos1 := Vector2(cos(a) * inner_rad * 1.5, sin(a) * inner_rad * 0.8)
		var pos2 := Vector2(cos(a + 0.8) * (inner_rad + 8) * 1.5, sin(a + 0.8) * (inner_rad + 8) * 0.8)
		node.draw_line(pos1, pos2, Color(col.r, col.g, col.b, 0.7), 2.5)

	# Luminous Core Singularity
	node.draw_circle(Vector2.ZERO, 10.0, Color.WHITE)
	node.draw_circle(Vector2.ZERO, 6.0, col)

	# Boundary Energy Ring
	node.draw_rect(Rect2(-portal_radius_x, -portal_radius_y, portal_radius_x * 2, portal_radius_y * 2), col, false, 2.5)


func _create_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(portal_radius_x * 2.0 + 12.0, portal_radius_y * 2.0 + 8.0)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _create_horizon_area() -> void:
	_horizon_area = Area2D.new()
	_horizon_area.name = "EventHorizon"
	_horizon_area.collision_layer = 0
	_horizon_area.collision_mask = 0b00010  # Layer 2: objects

	var shape := RectangleShape2D.new()
	shape.size = Vector2(portal_radius_x * 1.8, portal_radius_y * 1.8)
	var col := CollisionShape2D.new()
	col.shape = shape
	_horizon_area.add_child(col)
	_horizon_area.body_entered.connect(_on_horizon_body_entered)
	add_child(_horizon_area)


func _on_horizon_body_entered(body: Node2D) -> void:
	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return
	if not (body is RigidBody2D) or body == self:
		return

	var now := Time.get_ticks_msec()
	if _teleport_cooldowns.has(body) and (now - _teleport_cooldowns[body] < 400):
		return

	# Locate linked portal
	var target_portal := _find_linked_portal()
	if not target_portal or target_portal == self:
		return

	# Register cooldown on both entrance and exit portals
	_teleport_cooldowns[body] = now
	target_portal._teleport_cooldowns[body] = now

	# Compute entry and exit trajectories
	var speed: float = 250.0
	if body is RigidBody2D:
		speed = (body as RigidBody2D).linear_velocity.length()
	elif "linear_velocity" in body:
		speed = body.linear_velocity.length()
	var exit_forward := Vector2.UP.rotated(target_portal.global_rotation)
	var exit_pos := target_portal.global_position + exit_forward * 45.0
	var exit_velocity := exit_forward * maxf(speed, 250.0)

	body.global_position = exit_pos
	if body is RigidBody2D:
		(body as RigidBody2D).linear_velocity = exit_velocity
	elif "linear_velocity" in body:
		body.linear_velocity = exit_velocity

	# Audio and VFX
	AudioManager.play_ui_blip("select")
	if get_parent():
		ImpactSpark.create_at(global_position, get_parent())
		ImpactSpark.create_at(target_portal.global_position, get_parent())
	PlatformService.haptic_medium()
	chain_event.emit("teleport", target_portal)


func _find_linked_portal() -> PortalObject:
	var portals := get_tree().get_nodes_in_group("portals")
	for p in portals:
		if p is PortalObject and p != self:
			if not target_portal_tag.is_empty():
				if p.portal_tag == target_portal_tag:
					return p
			else:
				return p
	return null


func _create_highlight() -> void:
	_highlight = Node2D.new()
	_highlight.name = "Highlight"
	_highlight.visible = false
	add_child(_highlight)
	_highlight.draw.connect(func():
		var col := valid_highlight_color if is_placement_valid else invalid_highlight_color
		var r := Rect2(-portal_radius_x - 10, -portal_radius_y - 10, (portal_radius_x + 10) * 2, (portal_radius_y + 10) * 2)
		_highlight.draw_rect(r, col, false, 3.0)
		_highlight.draw_rect(r, Color(col.r, col.g, col.b, 0.15))
	)
	_highlight.queue_redraw()
	add_to_group("portals")


func _on_reset() -> void:
	super._on_reset()
	_teleport_cooldowns.clear()
	_vortex_angle = 0.0
