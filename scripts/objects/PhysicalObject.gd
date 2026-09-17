## Physical object with configurable physics material.
## Extends GameObject with reusable physics properties.
## Most game objects extend this rather than GameObject directly.
class_name PhysicalObject
extends GameObject

## Physics material properties (exported for per-instance tuning)
@export_group("Physics Material")
@export var object_mass: float = 1.0
@export var object_friction: float = 0.5
@export var object_bounce: float = 0.3
@export_range(0.0, 1.0) var object_gravity_scale: float = 1.0
@export_range(0.0, 5.0) var object_linear_damping: float = 0.1
@export_range(0.0, 5.0) var object_angular_damping: float = 0.1

## Visual properties
@export_group("Visuals")
@export var object_color: Color = Color.WHITE
@export var outline_color: Color = Color.BLACK
@export var outline_width: float = 2.0
@export var highlight_color: Color = Color(1.0, 0.9, 0.2, 0.5)

## The main visual sprite/shape for this object.
var _visual: Node2D = null


func _ready() -> void:
	# Apply physics material
	mass = object_mass
	gravity_scale = object_gravity_scale
	linear_damp = object_linear_damping
	angular_damp = object_angular_damping

	# Create physics material with friction and bounce
	var phys_mat := PhysicsMaterial.new()
	phys_mat.friction = object_friction
	phys_mat.bounce = object_bounce
	physics_material_override = phys_mat

	# Start frozen (PLACING state)
	freeze = true

	super._ready()


## Override to create custom highlight.
func _create_highlight() -> void:
	# The highlight will be created by subclasses based on their shape
	pass


## Override for custom per-object reset.
func _on_reset() -> void:
	# Restore physics material (in case it was modified during simulation)
	mass = object_mass
	gravity_scale = object_gravity_scale
