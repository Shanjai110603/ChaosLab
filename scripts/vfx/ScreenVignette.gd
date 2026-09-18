## ScreenVignette — full-screen edge vignette and dynamic impact flash overlay.
## Punctuates major chain reaction explosions and bullseye hits with chromatic bursts.
class_name ScreenVignette
extends CanvasLayer

static var instance: ScreenVignette = null

var _color_rect: ColorRect = null
var _tween: Tween = null


func _ready() -> void:
	instance = self
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS

	_color_rect = ColorRect.new()
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.color = Color(0, 0, 0, 0)
	add_child(_color_rect)


## Flash a warm fiery orange chromatic tint on bomb/barrel explosions.
static func flash_explosion(intensity: float = 0.45) -> void:
	if instance:
		instance._trigger_flash(Color(1.0, 0.4, 0.05, intensity), 0.22)


## Flash an electric cyan tint on target bullseye hits.
static func flash_bullseye(intensity: float = 0.35) -> void:
	if instance:
		instance._trigger_flash(Color(0.0, 0.85, 1.0, intensity), 0.18)


## Flash white on extreme multi-chain events.
static func flash_chaos(intensity: float = 0.6) -> void:
	if instance:
		instance._trigger_flash(Color(1.0, 1.0, 1.0, intensity), 0.28)


func _trigger_flash(color: Color, duration: float) -> void:
	if not _color_rect:
		return
	if _tween and _tween.is_valid():
		_tween.kill()

	_color_rect.color = color
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)
