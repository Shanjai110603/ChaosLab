## BreakableWall — Destructible barrier apparatus.
## Placed as environment obstacle or player-placed item.
## Fractures into 6-8 physics debris shards on high-velocity or explosive impact.
## Emits wall_broken signal, contributing to chain reaction score.
class_name BreakableWall
extends StaticBody2D

## Emitted when the wall fractures completely.
signal wall_broken(wall: BreakableWall)

# -------------------------------------------------------------------------
# Export parameters (configurable per level JSON)
# -------------------------------------------------------------------------

## Material type — determines HP, fracture velocity, and visual appearance.
@export_enum("glass", "concrete", "composite") var material: String = "glass"
## Override HP (0 = use material default).
@export var health_override: float = 0.0
## Wall width in pixels.
@export var wall_width: float = 12.0
## Wall height in pixels.
@export var wall_height: float = 120.0
## Rotation in degrees (for angled walls).
@export var wall_angle_deg: float = 0.0
## Number of shards to spawn on fracture.
@export_range(4, 12) var shard_count: int = 7
## Player can place this in the object tray (false = environment-only obstacle).
@export var is_player_placeable: bool = false

# -------------------------------------------------------------------------
# Material Definitions
# -------------------------------------------------------------------------

## Per-material properties: hp, fracture_velocity (px/s), colors.
const MATERIAL_PARAMS: Dictionary = {
	"glass": {
		"hp":            60.0,
		"fracture_vel":  280.0,
		"wobble_vel":    100.0,
		"color":         Color(0.6, 0.9, 1.0, 0.65),
		"outline":       Color(0.0, 0.85, 1.0, 0.9),
		"shard_color":   Color(0.75, 0.95, 1.0, 0.8),
		"label":         "GLASS",
	},
	"concrete": {
		"hp":            150.0,
		"fracture_vel":  450.0,
		"wobble_vel":    200.0,
		"color":         Color(0.42, 0.44, 0.48),
		"outline":       Color(0.28, 0.30, 0.34),
		"shard_color":   Color(0.48, 0.50, 0.54),
		"label":         "CONCRETE",
	},
	"composite": {
		"hp":            100.0,
		"fracture_vel":  350.0,
		"wobble_vel":    150.0,
		"color":         Color(0.28, 0.55, 0.38),
		"outline":       Color(0.18, 0.75, 0.40),
		"shard_color":   Color(0.35, 0.65, 0.45),
		"label":         "COMPOSITE",
	},
}

# -------------------------------------------------------------------------
# Debris Physics Constants
# -------------------------------------------------------------------------

const DEBRIS_IMPULSE_MIN: float = 180.0
const DEBRIS_IMPULSE_MAX: float = 420.0
const DEBRIS_ANGULAR_MIN: float = -18.0
const DEBRIS_ANGULAR_MAX: float = 18.0
const DEBRIS_LIFETIME: float = 0.8
## Physics layer 8 (0b10000000) — debris does not collide with targets/objects.
const DEBRIS_COLLISION_LAYER: int = 128

# -------------------------------------------------------------------------
# Explosion Damage Constants
# -------------------------------------------------------------------------

## Bomb shockwave within this radius applies explosion damage.
const EXPLOSION_DAMAGE_RADIUS: float = 150.0
## HP damage applied by a bomb explosion at point-blank range.
const EXPLOSION_DAMAGE_AMOUNT: float = 80.0

# -------------------------------------------------------------------------
# State
# -------------------------------------------------------------------------

var _current_hp: float = 0.0
var _max_hp: float = 0.0
var _fracture_velocity: float = 0.0
var _wobble_velocity: float = 0.0
var _is_fractured: bool = false
var _damage_flash_tween: Tween = null

var _visual: Node2D = null
var _damage_ratio: float = 0.0   # 0.0 = full health, 1.0 = about to shatter


func _ready() -> void:
	add_to_group("game_objects")
	add_to_group("breakable_walls")

	# Layer 1 (walls) for static collision
	collision_layer = 0b00001
	collision_mask = 0b00010   # Detect objects on layer 2

	var params: Dictionary = MATERIAL_PARAMS.get(material, MATERIAL_PARAMS["glass"])
	_max_hp = health_override if health_override > 0.0 else params["hp"]
	_current_hp = _max_hp
	_fracture_velocity = fracture_velocity_override if fracture_velocity_override > 0.0 else params["fracture_vel"]
	_wobble_velocity = params["wobble_vel"]

	rotation_degrees = wall_angle_deg

	_create_visual()
	_create_collision()
	_connect_signals()

	print("[BreakableWall] Ready — material=%s hp=%.0f fracture_vel=%.0f" % [material, _max_hp, _fracture_velocity])


@export var fracture_velocity_override: float = 0.0


func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.draw.connect(_draw_wall.bind(_visual))
	_visual.queue_redraw()


func _draw_wall(node: Node2D) -> void:
	if _is_fractured:
		return

	var params: Dictionary = MATERIAL_PARAMS.get(material, MATERIAL_PARAMS["glass"])
	var wall_color: Color = params["color"]
	var outline_col: Color = params["outline"]

	# Damage tinting — shift toward red as HP drops
	wall_color = wall_color.lerp(Color(0.9, 0.2, 0.1, wall_color.a), _damage_ratio * 0.5)

	var hw: float = wall_width * 0.5
	var hh: float = wall_height * 0.5
	var rect := Rect2(-hw, -hh, wall_width, wall_height)

	# Drop shadow
	node.draw_rect(Rect2(-hw + 2, -hh + 3, wall_width, wall_height), Color(0.0, 0.0, 0.0, 0.3))

	# Main body
	node.draw_rect(rect, wall_color)

	# Interior cracks based on damage
	if _damage_ratio > 0.3:
		var crack_color := Color(outline_col.r, outline_col.g, outline_col.b, 0.6 * _damage_ratio)
		var crack_count: int = int(_damage_ratio * 4)
		for i in crack_count:
			var cx: float = randf_range(-hw * 0.8, hw * 0.8)
			var cy_start: float = randf_range(-hh * 0.5, 0.0)
			var cy_end: float = randf_range(0.0, hh * 0.5)
			node.draw_line(Vector2(cx, cy_start), Vector2(cx + randf_range(-4, 4), cy_end), crack_color, 1.0)

	# Material-specific detail
	match material:
		"glass":
			# Diagonal specular sheen
			node.draw_line(Vector2(-hw + 2, -hh + 4), Vector2(-hw + 2, hh - 4),
				Color(1.0, 1.0, 1.0, 0.25), 2.0)
		"concrete":
			# Horizontal construction lines
			for i in 3:
				var y: float = -hh + (wall_height / 4.0) * (i + 1)
				node.draw_line(Vector2(-hw, y), Vector2(hw, y),
					Color(0.55, 0.57, 0.60, 0.4), 1.0)
		"composite":
			# Diagonal weave pattern hint
			node.draw_line(Vector2(-hw, -hh), Vector2(hw, hh),
				Color(0.4, 0.8, 0.5, 0.2), 1.5)
			node.draw_line(Vector2(hw, -hh), Vector2(-hw, hh),
				Color(0.4, 0.8, 0.5, 0.2), 1.5)

	# Outline
	node.draw_rect(rect, outline_col, false, 1.5)

	# Health bar strip at top of wall (thin, 3px)
	var bar_width: float = wall_width * (1.0 - _damage_ratio)
	var hp_color: Color = Color(0.2, 1.0, 0.4) if _damage_ratio < 0.5 else Color(1.0, 0.6, 0.1)
	node.draw_rect(Rect2(-hw, -hh - 5, bar_width, 3), hp_color)


func _create_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(wall_width, wall_height)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.name = "CollisionShape"
	add_child(col)


func _connect_signals() -> void:
	body_entered.connect(_on_body_entered)


# -------------------------------------------------------------------------
# Damage & Fracture Logic
# -------------------------------------------------------------------------

## Apply damage from an explosion shockwave.
func take_explosion_damage(amount: float, origin_position: Vector2) -> void:
	if _is_fractured:
		return
	_apply_damage(amount, origin_position)


## Apply damage from kinetic impact. Called internally from body_entered.
func _apply_damage(amount: float, impact_world_pos: Vector2) -> void:
	if _is_fractured:
		return

	_current_hp -= amount
	_damage_ratio = 1.0 - clampf(_current_hp / _max_hp, 0.0, 1.0)

	if _visual:
		_visual.queue_redraw()

	if _current_hp <= 0.0:
		_fracture(impact_world_pos - global_position)
	else:
		# Visual tremor wobble for sub-threshold hits
		_wobble()


func _wobble() -> void:
	if _damage_flash_tween and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(self, "position:x", position.x + 3.0, 0.04)
	_damage_flash_tween.tween_property(self, "position:x", position.x - 3.0, 0.04)
	_damage_flash_tween.tween_property(self, "position:x", position.x, 0.05)


func _fracture(impact_direction: Vector2) -> void:
	if _is_fractured:
		return
	_is_fractured = true

	wall_broken.emit(self)

	# Audio & Screen feedback
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_break()
	CameraShake.shake(0.35, 0.2)
	PlatformService.haptic_medium()

	# Spawn debris shards if budget allows
	var granted := DebrisManager.request(shard_count)
	if granted:
		_spawn_debris(impact_direction)

	# Spawn fragment VFX (lightweight particles even if debris denied)
	if get_parent():
		_spawn_fracture_flash()

	# Hide the wall instantly
	if _visual:
		_visual.visible = false

	# Remove collision so objects pass through the hole
	var col := get_node_or_null("CollisionShape")
	if col:
		col.set_deferred("disabled", true)

	# Clean up after debris lifetime
	var cleanup_timer := get_tree().create_timer(DEBRIS_LIFETIME + 0.5, false)
	cleanup_timer.timeout.connect(queue_free)


func _spawn_debris(impact_dir: Vector2) -> void:
	var parent := get_parent()
	if not parent:
		return

	var params: Dictionary = MATERIAL_PARAMS.get(material, MATERIAL_PARAMS["glass"])
	var shard_col: Color = params["shard_color"]

	for i in shard_count:
		var shard := RigidBody2D.new()
		shard.collision_layer = DEBRIS_COLLISION_LAYER
		shard.collision_mask = 0   # Debris doesn't collide with anything
		shard.gravity_scale = 1.2
		shard.linear_damp = 0.1
		shard.angular_damp = 0.05

		# Polygon shape (roughly wall-shard proportions, random slight variance)
		var sw: float = randf_range(wall_width * 0.8, wall_width * 1.8)
		var sh: float = randf_range((wall_height / shard_count) * 0.6, (wall_height / shard_count) * 1.6)
		var poly_shape := ConvexPolygonShape2D.new()
		poly_shape.set_point_cloud(PackedVector2Array([
			Vector2(-sw * 0.5 + randf_range(-2, 2), -sh * 0.5 + randf_range(-2, 2)),
			Vector2( sw * 0.5 + randf_range(-2, 2), -sh * 0.5 + randf_range(-2, 2)),
			Vector2( sw * 0.5 + randf_range(-2, 2),  sh * 0.5 + randf_range(-2, 2)),
			Vector2(-sw * 0.5 + randf_range(-2, 2),  sh * 0.5 + randf_range(-2, 2)),
		]))
		var col := CollisionShape2D.new()
		col.shape = poly_shape
		shard.add_child(col)

		# Shard visual: use authentic Kenney debris sprite when available
		var tex_prefix := "debrisGlass"
		match material:
			"concrete":
				tex_prefix = "debrisStone"
			"composite":
				tex_prefix = "debrisWood"
		var tex_idx := randi_range(1, 3)
		var tex_path := "res://assets/sprites/debris/%s_%d.png" % [tex_prefix, tex_idx]

		var shard_visual: Node2D = null
		if ResourceLoader.exists(tex_path):
			var sprite := Sprite2D.new()
			sprite.texture = load(tex_path)
			sprite.scale = Vector2(sw / 28.0, sh / 28.0)
			sprite.modulate = shard_col.lerp(Color.WHITE, 0.35)
			shard.add_child(sprite)
			shard_visual = sprite
		else:
			shard_visual = Node2D.new()
			var sv_sw := sw
			var sv_sh := sh
			var sv_col := shard_col
			shard_visual.draw.connect(func():
				shard_visual.draw_rect(Rect2(-sv_sw * 0.5, -sv_sh * 0.5, sv_sw, sv_sh), sv_col)
			)
			shard.add_child(shard_visual)

		# Position: spread across the wall's bounds
		var spawn_offset := Vector2(
			randf_range(-wall_width * 0.4, wall_width * 0.4),
			randf_range(-wall_height * 0.4, wall_height * 0.4)
		)
		shard.global_position = global_position + spawn_offset

		# Impulse: radially outward from impact with random spread
		var base_angle: float = impact_dir.angle() if impact_dir.length() > 0.1 else 0.0
		var scatter_angle: float = base_angle + randf_range(-0.8, 0.8)
		var speed: float = randf_range(DEBRIS_IMPULSE_MIN, DEBRIS_IMPULSE_MAX)
		shard.linear_velocity = Vector2.from_angle(scatter_angle) * speed
		shard.angular_velocity = randf_range(DEBRIS_ANGULAR_MIN, DEBRIS_ANGULAR_MAX)

		parent.add_child(shard)

		# Lifetime: fade alpha then free
		_schedule_debris_cleanup(shard, shard_visual)


func _schedule_debris_cleanup(shard: RigidBody2D, shard_visual: Node2D) -> void:
	var timer := get_tree().create_timer(DEBRIS_LIFETIME * 0.65, false)
	timer.timeout.connect(func():
		if not is_instance_valid(shard):
			DebrisManager.release(1)
			return
		var t := shard.create_tween()
		t.tween_property(shard_visual, "modulate:a", 0.0, DEBRIS_LIFETIME * 0.35)
		t.tween_callback(func():
			DebrisManager.release(1)
			if is_instance_valid(shard):
				shard.queue_free()
		)
	)


func _spawn_fracture_flash() -> void:
	## Lightweight flash ring at wall center — cheap VFX even on low-end devices.
	var flash := Node2D.new()
	var params: Dictionary = MATERIAL_PARAMS.get(material, MATERIAL_PARAMS["glass"])
	var flash_col: Color = params["outline"]
	var hw := wall_width * 0.5
	var hh := wall_height * 0.5
	flash.global_position = global_position

	flash.draw.connect(func():
		flash.draw_rect(
			Rect2(-hw - 4, -hh - 4, wall_width + 8, wall_height + 8),
			Color(flash_col.r, flash_col.g, flash_col.b, 0.8),
			false, 3.0
		)
	)
	get_parent().add_child(flash)

	var t := flash.create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.25)
	t.tween_callback(flash.queue_free)


# -------------------------------------------------------------------------
# Collision Detection
# -------------------------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	if _is_fractured:
		return
	if GameManager.current_state != GameManager.GameState.SIMULATING:
		return

	if body is RigidBody2D:
		var vel: float = (body as RigidBody2D).linear_velocity.length()

		if vel >= _fracture_velocity:
			var impact_dir: Vector2 = (body as RigidBody2D).linear_velocity.normalized()
			_fracture(impact_dir * (wall_width + wall_height) * 0.5)
		elif vel >= _wobble_velocity:
			# Sub-threshold: apply partial damage proportional to velocity
			var damage_fraction: float = (vel - _wobble_velocity) / (_fracture_velocity - _wobble_velocity)
			_apply_damage(_max_hp * damage_fraction * 0.35, body.global_position)


# -------------------------------------------------------------------------
# Reset (called by Arena on experiment reset)
# -------------------------------------------------------------------------

func reset() -> void:
	_is_fractured = false
	_current_hp = _max_hp
	_damage_ratio = 0.0
	visible = true

	var col := get_node_or_null("CollisionShape")
	if col:
		col.disabled = false

	if _visual:
		_visual.visible = true
		_visual.queue_redraw()
