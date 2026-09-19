## Animated boot loading screen.
## Displays rotating quantum reactor rings + typewriter status log + progress bar.
## Replaces the static splash screen on first launch.
class_name LoadingScreen
extends Control

# -------------------------------------------------------------------------
# Boot sequence messages
# -------------------------------------------------------------------------

const BOOT_MESSAGES: Array[String] = [
	"> INITIALIZING QUANTUM CORE...",
	"> CALIBRATING KINETIC SENSORS...",
	"> LOADING APPARATUS BLUEPRINTS...",
	"> COMPILING REACTION PROTOCOLS...",
	"> CHARGING CHAOS CAPACITORS...",
	"> CALIBRATION COMPLETE.",
	"> CHAOS LAB ACTIVE.",
]

# -------------------------------------------------------------------------
# Animation constants
# -------------------------------------------------------------------------

const TYPEWRITER_CHAR_SPEED: float = 0.025   # seconds per character
const MESSAGE_DELAY: float = 0.50            # seconds between messages

const RING_RADII: Array[float]     = [72.0, 110.0, 148.0]
const RING_SPEEDS: Array[float]    = [50.0, -32.0, 22.0]  # deg/sec
const RING_SEGMENT_COUNTS: Array[int] = [12, 24, 36]
const RING_ALPHAS: Array[float]    = [1.0, 0.6, 0.35]
const RING_WIDTHS: Array[float]    = [3.0, 2.0, 1.5]

const NEON_CYAN: Color = Color(0.0, 0.9, 1.0)
const BG_COLOR: Color  = Color(0.04, 0.06, 0.10)
const BAR_COLOR: Color = Color(0.0, 0.9, 1.0)
const BAR_BG_COLOR: Color = Color(0.08, 0.12, 0.18)

# -------------------------------------------------------------------------
# Nodes
# -------------------------------------------------------------------------

var _ring_layer: Node2D = null
var _log_label: RichTextLabel = null
var _progress_bar: ColorRect = null
var _progress_bar_fill: ColorRect = null
var _title_label: Label = null
var _tagline_label: Label = null

var _ring_angles: Array[float] = [0.0, 0.0, 0.0]
var _progress: float = 0.0           # 0.0 → 1.0
var _log_text: String = ""
var _is_complete: bool = false

var _total_boot_time: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	# Calculate total boot time based on messages
	_total_boot_time = (BOOT_MESSAGES.size() * MESSAGE_DELAY) + 0.8

	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_start_boot_sequence()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	_title_label = Label.new()
	_title_label.text = "CHAOS LAB"
	_title_label.add_theme_font_size_override("font_size", 72)
	_title_label.add_theme_color_override("font_color", NEON_CYAN)
	_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_label.position = Vector2(-220, 100)
	_title_label.modulate.a = 0.0
	add_child(_title_label)

	# Tagline
	_tagline_label = Label.new()
	_tagline_label.text = "Build it. Trigger it. Cause chaos."
	_tagline_label.add_theme_font_size_override("font_size", 22)
	_tagline_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	_tagline_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_tagline_label.position = Vector2(-200, 188)
	_tagline_label.modulate.a = 0.0
	add_child(_tagline_label)

	# Rotating rings layer — centered
	_ring_layer = Node2D.new()
	_ring_layer.name = "RingLayer"
	_ring_layer.position = Vector2(960, 480)
	_ring_layer.draw.connect(_draw_rings.bind(_ring_layer))
	add_child(_ring_layer)

	# Log label (typewriter output)
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_log_label.position = Vector2(80, -260)
	_log_label.size = Vector2(900, 220)
	_log_label.add_theme_font_size_override("normal_font_size", 16)
	_log_label.add_theme_color_override("default_color", Color(0.5, 0.85, 0.5))
	add_child(_log_label)

	# Progress bar background
	_progress_bar = ColorRect.new()
	_progress_bar.color = BAR_BG_COLOR
	_progress_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_progress_bar.position = Vector2(0, -18)
	_progress_bar.size.y = 8.0
	add_child(_progress_bar)

	# Progress bar fill
	_progress_bar_fill = ColorRect.new()
	_progress_bar_fill.color = BAR_COLOR
	_progress_bar_fill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_progress_bar_fill.position = Vector2(0, -18)
	_progress_bar_fill.size = Vector2(0, 8)
	add_child(_progress_bar_fill)


func _draw_rings(node: Node2D) -> void:
	for i in RING_RADII.size():
		var r: float = RING_RADII[i]
		var segments: int = RING_SEGMENT_COUNTS[i]
		var alpha: float = RING_ALPHAS[i]
		var width: float = RING_WIDTHS[i]
		var angle_offset_rad: float = deg_to_rad(_ring_angles[i])

		# Draw arc segments with gaps
		for s in segments:
			var arc_start: float = angle_offset_rad + (TAU / segments) * s
			var arc_end: float = arc_start + (TAU / segments) * 0.72  # 72% of segment = gap

			var p1 := Vector2(cos(arc_start), sin(arc_start)) * r
			var p2 := Vector2(cos(arc_end), sin(arc_end)) * r
			node.draw_line(p1, p2, Color(NEON_CYAN.r, NEON_CYAN.g, NEON_CYAN.b, alpha), width, true)

		# Inner dot at each segment boundary
		if i == 0:
			for s in segments:
				var dot_angle: float = angle_offset_rad + (TAU / segments) * s
				var dot_pos := Vector2(cos(dot_angle), sin(dot_angle)) * (r - 6.0)
				node.draw_circle(dot_pos, 2.5, Color(NEON_CYAN.r, NEON_CYAN.g, NEON_CYAN.b, 0.9))

	# Center glow
	node.draw_circle(Vector2.ZERO, 8.0, NEON_CYAN)
	node.draw_circle(Vector2.ZERO, 16.0, Color(NEON_CYAN.r, NEON_CYAN.g, NEON_CYAN.b, 0.25))


func _process(delta: float) -> void:
	if _is_complete:
		return

	_elapsed += delta

	# Rotate rings
	for i in RING_SPEEDS.size():
		_ring_angles[i] += RING_SPEEDS[i] * delta
	if _ring_layer:
		_ring_layer.queue_redraw()

	# Progress bar fill
	_progress = clampf(_elapsed / _total_boot_time, 0.0, 1.0)
	if _progress_bar_fill and _progress_bar:
		_progress_bar_fill.size.x = _progress_bar.size.x * _progress


func _start_boot_sequence() -> void:
	# Fade in title
	var title_tween := create_tween()
	title_tween.tween_property(_title_label, "modulate:a", 1.0, 0.5)
	title_tween.parallel().tween_property(_tagline_label, "modulate:a", 0.7, 0.8).set_delay(0.2)

	# Typewriter messages
	var delay := 0.4
	for msg in BOOT_MESSAGES:
		_schedule_typewriter(msg, delay)
		delay += MESSAGE_DELAY

	# On completion, transition to main menu
	var finish_timer := get_tree().create_timer(delay + 0.3, true, false, true)
	finish_timer.timeout.connect(_on_boot_complete)


func _schedule_typewriter(message: String, start_delay: float) -> void:
	var timer := get_tree().create_timer(start_delay, true, false, true)
	timer.timeout.connect(func():
		if not is_inside_tree():
			return
		_type_message(message)
	)


func _type_message(message: String) -> void:
	var full_text := _log_text
	var char_index := 0

	var char_timer_cb: Callable
	char_timer_cb = func():
		if char_index >= message.length():
			_log_text = full_text + message + "\n"
			if _log_label:
				_log_label.text = _log_text
			return
		full_text += message[char_index]
		char_index += 1
		if _log_label:
			_log_label.text = full_text + "_"
		var ct := get_tree().create_timer(TYPEWRITER_CHAR_SPEED, true, false, true)
		ct.timeout.connect(char_timer_cb)

	var start_timer := get_tree().create_timer(0.01, true, false, true)
	start_timer.timeout.connect(char_timer_cb)


func _on_boot_complete() -> void:
	if _is_complete:
		return
	_is_complete = true

	# Fill bar fully
	if _progress_bar_fill and _progress_bar:
		var t := create_tween()
		t.tween_property(_progress_bar_fill, "size:x", _progress_bar.size.x, 0.15)

	# Transition to main scene
	var transition_timer := get_tree().create_timer(0.3, true, false, true)
	transition_timer.timeout.connect(func():
		ScreenTransition.fade_to(func():
			get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
		)
	)
