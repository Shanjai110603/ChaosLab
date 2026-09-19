## NixCompanion — Laboratory Assistant AI Companion.
## Renders an animated robotic AI avatar with dynamic visor expressions
## and witty holographic speech bubble reactions during gameplay and in menus.
class_name NixCompanion
extends Control

signal speech_started(text: String)
signal speech_completed()

enum Emotion { IDLE, TALKING, CURIOUS, ALARMED, EXCITED, PROUD }

var current_emotion: Emotion = Emotion.IDLE
var _anim_time: float = 0.0
var _blink_timer: float = 0.0
var _is_blinking: bool = false
var _speech_queue: Array[Dictionary] = []
var _is_speaking: bool = false
var _typewriter_progress: float = 0.0
var _target_text: String = ""
var _display_text: String = ""
var _auto_hide_timer: float = 0.0

@onready var avatar_panel: Panel = null
@onready var speech_bubble: PanelContainer = null
@onready var name_label: Label = null
@onready var dialogue_label: Label = null
@onready var dismiss_btn: Button = null

const COLOR_CYAN := Color(0.0, 0.85, 1.0)
const COLOR_AMBER := Color(1.0, 0.7, 0.2)
const COLOR_ALERT := Color(1.0, 0.25, 0.35)
const COLOR_BG := Color(0.04, 0.07, 0.12, 0.94)

const LEVEL_GREETINGS := {
	1: "Welcome to Experiment 1! Dr. Nova's notes say: combine the ball with the barrel, and trigger chaos!",
	2: "Ah, momentum! Make sure the ramp angles the kinetic ball toward the target.",
	3: "Multiple targets detected! Remember, one well-placed bomb can solve everything.",
	4: "Watch your velocity tolerances. Precision is key, or at least very explosive.",
	5: "Rockets! Aim them right at the volatile barrels. Do try not to set off the sprinklers.",
	10: "World 1 finale! Combine everything you've learned. The laboratory Core is watching!",
}

const CHAIN_REACTIONS := [
	"A spark of genius!",
	"Chain reaction sustained! Keep it going!",
	"Chain x5! Now we are doing real science!",
	"Chain x8! The sensors are going off the charts!",
	"Chain x10! I am officially concerned!",
	"UNSTABLE ANOMALY DETECTED! That was incredible!",
]

const WIN_REACTIONS := [
	"Objective accomplished! Data successfully uploaded to the Core.",
	"Brilliant deduction! Dr. Nova would be proud.",
	"Clean, calculated chaos. Onto the next experiment!",
	"Target eliminated with extreme prejudice. Satisfactory!",
]

const FAIL_REACTIONS := [
	"Interesting... that was definitely one approach. Let's try again!",
	"Hypothesis disproven! Fortunately, lab equipment is infinitely replaceable.",
	"Slight calculation error. Check your angles and placement!",
	"BOOM! Well, that didn't work, but it certainly looked spectacular.",
]


func _ready() -> void:
	custom_minimum_size = Vector2(380, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	set_process(true)


func _build_ui() -> void:
	var h_box := HBoxContainer.new()
	h_box.name = "HBox"
	h_box.add_theme_constant_override("separation", 14)
	add_child(h_box)

	# Avatar Canvas / Custom drawing
	avatar_panel = Panel.new()
	avatar_panel.name = "AvatarPanel"
	avatar_panel.custom_minimum_size = Vector2(64, 64)
	avatar_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	avatar_panel.gui_input.connect(_on_avatar_gui_input)

	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.03, 0.06, 0.1, 0.95)
	avatar_style.border_width_bottom = 2
	avatar_style.border_width_left = 2
	avatar_style.border_width_right = 2
	avatar_style.border_width_top = 2
	avatar_style.border_color = COLOR_CYAN
	avatar_style.corner_radius_top_left = 12
	avatar_style.corner_radius_top_right = 12
	avatar_style.corner_radius_bottom_left = 12
	avatar_style.corner_radius_bottom_right = 12
	avatar_style.shadow_color = Color(COLOR_CYAN, 0.35)
	avatar_style.shadow_size = 6
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)
	avatar_panel.draw.connect(_draw_avatar)
	h_box.add_child(avatar_panel)

	# Speech Bubble
	speech_bubble = PanelContainer.new()
	speech_bubble.name = "SpeechBubble"
	speech_bubble.custom_minimum_size = Vector2(300, 80)
	speech_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = COLOR_BG
	bubble_style.border_width_bottom = 1
	bubble_style.border_width_left = 1
	bubble_style.border_width_right = 1
	bubble_style.border_width_top = 1
	bubble_style.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.45)
	bubble_style.corner_radius_top_left = 10
	bubble_style.corner_radius_top_right = 10
	bubble_style.corner_radius_bottom_left = 10
	bubble_style.corner_radius_bottom_right = 10
	bubble_style.content_margin_left = 12
	bubble_style.content_margin_right = 12
	bubble_style.content_margin_top = 8
	bubble_style.content_margin_bottom = 8
	speech_bubble.add_theme_stylebox_override("panel", bubble_style)
	h_box.add_child(speech_bubble)

	var v_box := VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 3)
	speech_bubble.add_child(v_box)

	# Header Bar
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	v_box.add_child(header)

	name_label = Label.new()
	name_label.text = "[AI] NIX // LAB ASSISTANT"
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", COLOR_CYAN)
	header.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	dismiss_btn = Button.new()
	dismiss_btn.text = "X"
	dismiss_btn.custom_minimum_size = Vector2(18, 16)
	dismiss_btn.add_theme_font_size_override("font_size", 9)
	dismiss_btn.focus_mode = Control.FOCUS_NONE
	dismiss_btn.pressed.connect(hide_speech)
	header.add_child(dismiss_btn)

	dialogue_label = Label.new()
	dialogue_label.text = ""
	dialogue_label.add_theme_font_size_override("font_size", 11)
	dialogue_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size.x = 270
	v_box.add_child(dialogue_label)

	speech_bubble.visible = false


func _process(delta: float) -> void:
	_anim_time += delta
	_blink_timer += delta

	# Blinking logic
	if _blink_timer > 3.5:
		_is_blinking = true
		if _blink_timer > 3.7:
			_is_blinking = false
			_blink_timer = 0.0

	# Avatar redraw for visor animation
	if avatar_panel:
		avatar_panel.queue_redraw()

	# Typewriter speech
	if _is_speaking:
		_typewriter_progress += delta * 32.0
		var char_count: int = int(_typewriter_progress)
		if char_count < _target_text.length():
			_display_text = _target_text.substr(0, char_count)
		else:
			_display_text = _target_text
			_is_speaking = false
			speech_completed.emit()
		if dialogue_label:
			dialogue_label.text = _display_text

	# Auto hide timer
	if _auto_hide_timer > 0.0 and not _is_speaking:
		_auto_hide_timer -= delta
		if _auto_hide_timer <= 0.0:
			hide_speech()


func _draw_avatar() -> void:
	if not avatar_panel:
		return
	var size := avatar_panel.size
	var center := size * 0.5

	# Draw robot face outline
	var face_rect := Rect2(size * 0.15, size * 0.7)
	avatar_panel.draw_rect(face_rect, Color(0.08, 0.14, 0.22), true, -1.0)

	# Visor color depending on emotion
	var visor_color := COLOR_CYAN
	match current_emotion:
		Emotion.ALARMED:
			visor_color = COLOR_ALERT
		Emotion.CURIOUS:
			visor_color = COLOR_AMBER
		Emotion.EXCITED, Emotion.PROUD:
			visor_color = Color(0.3, 1.0, 0.5)

	# Visor Glow
	var pulse: float = sin(_anim_time * 4.0) * 0.15 + 0.85
	var glow_c := Color(visor_color.r, visor_color.g, visor_color.b, 0.25 * pulse)
	avatar_panel.draw_circle(center, 22.0, glow_c)

	# Draw Eyes / Visor
	var eye_y: float = center.y
	var eye_height: float = 3.0 if _is_blinking else (8.0 + sin(_anim_time * 3.0) * 1.5)
	var left_eye := Rect2(center.x - 16.0, eye_y - eye_height * 0.5, 10.0, eye_height)
	var right_eye := Rect2(center.x + 6.0, eye_y - eye_height * 0.5, 10.0, eye_height)

	avatar_panel.draw_rect(left_eye, visor_color, true, -1.0)
	avatar_panel.draw_rect(right_eye, visor_color, true, -1.0)

	# Antenna indicator
	var ant_pos := Vector2(center.x, size.y * 0.12)
	avatar_panel.draw_circle(ant_pos, 3.5, visor_color)


func speak(text: String, duration: float = 4.5, emotion: Emotion = Emotion.TALKING) -> void:
	current_emotion = emotion
	_target_text = text
	_display_text = ""
	_typewriter_progress = 0.0
	_is_speaking = true
	_auto_hide_timer = duration
	if speech_bubble:
		speech_bubble.visible = true
	speech_started.emit(text)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_ui_click()


func hide_speech() -> void:
	_is_speaking = false
	current_emotion = Emotion.IDLE
	if speech_bubble:
		speech_bubble.visible = false


func greet_level(level_id: int, title: String, objective: String) -> void:
	if LEVEL_GREETINGS.has(level_id):
		speak(LEVEL_GREETINGS[level_id], 5.0, Emotion.CURIOUS)
	else:
		var txt := "Experiment %d: %s. Objective: %s. Good luck, Technician!" % [level_id, title, objective]
		speak(txt, 4.5, Emotion.IDLE)


func react_to_chain(chain_count: int) -> void:
	if chain_count >= 8:
		speak(CHAIN_REACTIONS[5], 4.0, Emotion.ALARMED)
	elif chain_count >= 6:
		speak(CHAIN_REACTIONS[4], 3.5, Emotion.EXCITED)
	elif chain_count >= 4:
		speak(CHAIN_REACTIONS[2], 3.0, Emotion.PROUD)
	elif chain_count >= 2:
		speak(CHAIN_REACTIONS[0], 2.5, Emotion.TALKING)


func react_to_result(success: bool, stars: int) -> void:
	if success:
		if stars >= 3:
			speak("PERFECT 3-STAR EXPERIMENT! Maximum Core synchronization!", 4.5, Emotion.EXCITED)
		else:
			var idx: int = randi() % WIN_REACTIONS.size()
			speak(WIN_REACTIONS[idx], 4.0, Emotion.PROUD)
	else:
		var idx: int = randi() % FAIL_REACTIONS.size()
		speak(FAIL_REACTIONS[idx], 4.0, Emotion.CURIOUS)


func _on_avatar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if speech_bubble and speech_bubble.visible:
			hide_speech()
		else:
			var quotes := [
				"Need a hint? Check the object descriptions in the bottom tray!",
				"Dr. Nova's motto: If at first you don't succeed, add more rockets!",
				"All laboratory systems operating within tolerable chaos limits.",
				"I'm keeping an eye on your physics trajectory calculations.",
			]
			speak(quotes[randi() % quotes.size()], 4.0, Emotion.TALKING)
