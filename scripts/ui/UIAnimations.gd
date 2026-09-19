## UIAnimations — Global UI animation utility autoload.
## Provides spring-physics micro-animations for buttons, cards, and panels.
## Usage: UIAnimations.setup_button(btn) in any screen's _ready().
class_name UIAnimations
extends Node

static var instance: UIAnimations = null

# Button animation constants
const HOVER_SCALE: float = 1.035
const PRESS_SCALE: float = 0.935
const BOUNCE_SCALE: float = 1.065
const HOVER_IN_DURATION: float = 0.12
const HOVER_OUT_DURATION: float = 0.15
const PRESS_DURATION: float = 0.07
const BOUNCE_DURATION: float = 0.09
const SETTLE_DURATION: float = 0.12

# Card stagger constants
const CARD_STAGGER_DELAY: float = 0.04   # 40ms per card
const CARD_IN_DURATION: float = 0.20
const CARD_IN_SCALE_FROM: float = 0.82
const CARD_IN_SCALE_TO: float = 1.0

# Panel slide constants
const PANEL_SLIDE_DURATION: float = 0.22


func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------------------
# Button Spring Physics
# ---------------------------------------------------------------------------

## Apply hover + press + release spring-physics to any BaseButton.
## Set click_sound=false to suppress the press blip (e.g. toggle switches).
static func setup_button(btn: BaseButton, click_sound: bool = true) -> void:
	if not btn or not is_instance_valid(btn):
		return

	# Pivot must be centered for scale to animate from center
	if btn is Control:
		(btn as Control).pivot_offset = (btn as Control).size / 2.0

	# Reconnect safely — avoid duplicate connections if called twice
	_safe_connect(btn.mouse_entered, func():
		if not is_instance_valid(btn):
			return
		_tween_scale(btn, Vector2(HOVER_SCALE, HOVER_SCALE), HOVER_IN_DURATION, Tween.TRANS_QUAD, Tween.EASE_OUT)
	)

	_safe_connect(btn.mouse_exited, func():
		if not is_instance_valid(btn) or btn.button_pressed:
			return
		_tween_scale(btn, Vector2.ONE, HOVER_OUT_DURATION, Tween.TRANS_QUAD, Tween.EASE_OUT)
	)

	_safe_connect(btn.button_down, func():
		if not is_instance_valid(btn):
			return
		_tween_scale(btn, Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_DURATION, Tween.TRANS_QUAD, Tween.EASE_IN)
		if click_sound and AudioManager:
			AudioManager.play_ui_blip("press")
	)

	_safe_connect(btn.button_up, func():
		if not is_instance_valid(btn):
			return
		var t := btn.create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
		t.tween_property(btn, "scale", Vector2(BOUNCE_SCALE, BOUNCE_SCALE), BOUNCE_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2.ONE, SETTLE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)


## Apply setup_button to every BaseButton found recursively inside a container.
static func setup_all_buttons(root: Node, click_sound: bool = true) -> void:
	if not root:
		return
	for child in root.get_children():
		if child is BaseButton:
			setup_button(child as BaseButton, click_sound)
		if child.get_child_count() > 0:
			setup_all_buttons(child, click_sound)


# ---------------------------------------------------------------------------
# Card Staggered Pop-In
# ---------------------------------------------------------------------------

## Animate children of `container` popping in with a staggered cascade delay.
## Recommended: call after populating the container with cards/items.
static func animate_cards_in(container: Node, start_delay: float = 0.0) -> void:
	if not container:
		return
	var delay := start_delay
	for child in container.get_children():
		if not child is Control:
			continue
		var ctrl := child as Control
		ctrl.pivot_offset = ctrl.size / 2.0
		ctrl.scale = Vector2(CARD_IN_SCALE_FROM, CARD_IN_SCALE_FROM)
		ctrl.modulate.a = 0.0

		var t := ctrl.create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
		t.tween_interval(delay)
		t.tween_property(ctrl, "scale", Vector2(CARD_IN_SCALE_TO, CARD_IN_SCALE_TO), CARD_IN_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(ctrl, "modulate:a", 1.0, CARD_IN_DURATION) \
			.set_trans(Tween.TRANS_QUAD)

		delay += CARD_STAGGER_DELAY


# ---------------------------------------------------------------------------
# Panel Slide-In / Slide-Out
# ---------------------------------------------------------------------------

## Slide a panel in from off-screen-left, hold, then slide out.
static func banner_slide(panel: Control, hold_duration: float = 1.8) -> void:
	if not panel:
		return
	const SLIDE_DISTANCE: float = 600.0
	const SLIDE_IN_DURATION: float = 0.3
	const SLIDE_OUT_DURATION: float = 0.2

	panel.position.x = -SLIDE_DISTANCE
	panel.visible = true
	panel.modulate.a = 1.0

	var t := panel.create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
	t.tween_property(panel, "position:x", 0.0, SLIDE_IN_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold_duration)
	t.tween_property(panel, "position:x", -SLIDE_DISTANCE, SLIDE_OUT_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): panel.visible = false)


## Punch-scale an element (scale up then spring back to normal).
static func punch_scale(ctrl: Control, peak: float = 1.3, duration: float = 0.15) -> void:
	if not ctrl:
		return
	ctrl.pivot_offset = ctrl.size / 2.0
	var t := ctrl.create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
	t.tween_property(ctrl, "scale", Vector2(peak, peak), duration * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ctrl, "scale", Vector2.ONE, duration * 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Pulsing glow tween on a button — loops until stopped.
## Returns the Tween so caller can kill() it.
static func start_pulse_glow(ctrl: Control, color_a: Color, color_b: Color, period: float = 1.0) -> Tween:
	if not ctrl:
		return null
	var t := ctrl.create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_TIME)
	t.tween_property(ctrl, "modulate", color_a, period * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(ctrl, "modulate", color_b, period * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return t


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

static func _tween_scale(node: Node, target: Vector2, duration: float,
		trans: Tween.TransitionType, ease: Tween.EaseType) -> void:
	var t := node.create_tween().set_process_mode(Tween.TWEEN_PROCESS_TIME)
	t.tween_property(node, "scale", target, duration).set_trans(trans).set_ease(ease)


## Connect a signal safely without duplicating if already connected.
static func _safe_connect(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)
