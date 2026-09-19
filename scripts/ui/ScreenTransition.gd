## Universal scene transition controller.
## Mounted as CanvasLayer 100 in Main.tscn — always on top of everything.
## Usage (from anywhere):
##   ScreenTransition.fade_to(func(): get_tree().change_scene_to_file("res://..."))
class_name ScreenTransition
extends CanvasLayer

static var instance: ScreenTransition = null

## Duration of each half of the transition (fade-out + fade-in).
@export var wipe_duration: float = 0.25
## Background fill color (default: deep lab navy).
@export var bg_color: Color = Color(0.04, 0.06, 0.10, 0.0)

## Neon edge glow color drawn at the iris seam.
const EDGE_COLOR: Color = Color(0.0, 0.9, 1.0)

var _panel: ColorRect = null
var _edge_flash: ColorRect = null
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Full-screen darkening panel
	_panel = ColorRect.new()
	_panel.color = bg_color
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	# Thin neon edge flash strip (simulates iris seam glow)
	_edge_flash = ColorRect.new()
	_edge_flash.color = Color(EDGE_COLOR.r, EDGE_COLOR.g, EDGE_COLOR.b, 0.0)
	_edge_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_edge_flash)


## Fade to dark, call transition_func (scene change), then fade back in.
## transition_func must be a callable (e.g., a lambda or func reference).
static func fade_to(transition_func: Callable) -> void:
	if not instance:
		transition_func.call()
		return
	if instance._is_transitioning:
		# Queue the call but don't nest transitions
		transition_func.call()
		return
	instance._do_fade(transition_func)


## Instant cut with no animation (use for initial scene, not for player-facing transitions).
static func instant_clear() -> void:
	if instance:
		instance._panel.color = Color(instance.bg_color.r, instance.bg_color.g, instance.bg_color.b, 0.0)
		instance._edge_flash.color = Color(EDGE_COLOR.r, EDGE_COLOR.g, EDGE_COLOR.b, 0.0)
		instance._is_transitioning = false
		instance._panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _do_fade(transition_func: Callable) -> void:
	_is_transitioning = true
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)

	# --- Fade OUT (darken to black) ---
	tween.tween_property(_panel, "color:a", 1.0, wipe_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Neon edge flare at peak darkness
	tween.parallel().tween_property(_edge_flash, "color:a", 0.6, wipe_duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		# Execute the scene change while screen is fully dark
		transition_func.call()
		_edge_flash.color = Color(EDGE_COLOR.r, EDGE_COLOR.g, EDGE_COLOR.b, 0.6)
	)

	# Brief hold at black so the new scene has time to load
	tween.tween_interval(0.05)

	# --- Fade IN (reveal new scene) ---
	tween.tween_property(_panel, "color:a", 0.0, wipe_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_edge_flash, "color:a", 0.0, wipe_duration * 0.5).set_trans(Tween.TRANS_QUAD)

	tween.tween_callback(func():
		_is_transitioning = false
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
