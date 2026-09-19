## AdSimulationOverlay — Simulated interactive video ad player.
## Allows testing rewarded ads and interstitials seamlessly across Windows, Web, and dev environments.
class_name AdSimulationOverlay
extends CanvasLayer

signal ad_completed(success: bool)

enum AdType {
	REWARDED,
	INTERSTITIAL,
}

var ad_type: AdType = AdType.REWARDED
var placement_name: String = "reward"
var _callback: Callable = Callable()

var _timer_remaining: float = 3.0
var _total_duration: float = 3.0
var _is_running: bool = false
var _reward_earned: bool = false

# UI references
var _overlay: ColorRect = null
var _panel: PanelContainer = null
var _title_label: Label = null
var _placement_label: Label = null
var _countdown_label: Label = null
var _progress_bar: ProgressBar = null
var _skip_btn: Button = null
var _brand_icon: Label = null
var _sponsor_tag: Label = null


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false


func _create_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.01, 0.02, 0.04, 0.94)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(480, 400)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.14, 0.98)
	style.set_corner_radius_all(16)
	style.set_border_width_all(2)
	style.border_color = Color(0.0, 0.85, 1.0, 0.8)
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 20
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", style)
	_overlay.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	# Header Bar
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(header)

	var header_vbox := VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_vbox)

	_title_label = Label.new()
	_title_label.text = "SPONSORED TRANSMISSION"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	header_vbox.add_child(_title_label)

	_placement_label = Label.new()
	_placement_label.text = "[REWARDED AD: 2X COINS]"
	_placement_label.add_theme_font_size_override("font_size", 12)
	_placement_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.7))
	header_vbox.add_child(_placement_label)

	_skip_btn = Button.new()
	_skip_btn.text = "X"
	_skip_btn.custom_minimum_size = Vector2(36, 36)
	_skip_btn.focus_mode = Control.FOCUS_NONE
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.2, 0.25, 0.35, 0.6)
	skip_style.set_corner_radius_all(18)
	_skip_btn.add_theme_stylebox_override("normal", skip_style)
	_skip_btn.pressed.connect(_on_skip_pressed)
	header.add_child(_skip_btn)

	# Video Viewport Simulation Box
	var video_box := PanelContainer.new()
	video_box.custom_minimum_size = Vector2(424, 210)
	var v_style := StyleBoxFlat.new()
	v_style.bg_color = Color(0.02, 0.03, 0.06, 1.0)
	v_style.set_corner_radius_all(10)
	v_style.set_border_width_all(1)
	v_style.border_color = Color(0.15, 0.25, 0.4, 0.6)
	video_box.add_theme_stylebox_override("panel", v_style)
	vbox.add_child(video_box)

	var video_content := VBoxContainer.new()
	video_content.alignment = BoxContainer.ALIGNMENT_CENTER
	video_content.add_theme_constant_override("separation", 8)
	video_box.add_child(video_content)

	_brand_icon = Label.new()
	_brand_icon.text = "[CORE SPONSOR]"
	_brand_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_brand_icon.add_theme_font_size_override("font_size", 18)
	_brand_icon.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	video_content.add_child(_brand_icon)

	_sponsor_tag = Label.new()
	_sponsor_tag.text = "QUANTUM DYNAMICS LABS\nAdvanced Kinetic Solutions"
	_sponsor_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sponsor_tag.add_theme_font_size_override("font_size", 14)
	_sponsor_tag.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	video_content.add_child(_sponsor_tag)

	# Progress Bar
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 10)
	_progress_bar.show_percentage = false
	var pb_style := StyleBoxFlat.new()
	pb_style.bg_color = Color(0.0, 0.85, 1.0)
	pb_style.set_corner_radius_all(5)
	_progress_bar.add_theme_stylebox_override("fill", pb_style)
	vbox.add_child(_progress_bar)

	# Footer Status
	_countdown_label = Label.new()
	_countdown_label.text = "Reward in 3s..."
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 14)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(_countdown_label)


func play_ad(type: AdType, placement: String, callback: Callable = Callable()) -> void:
	ad_type = type
	placement_name = placement
	_callback = callback
	_reward_earned = false
	_is_running = true

	if ad_type == AdType.REWARDED:
		_total_duration = 3.0
		_timer_remaining = 3.0
		_title_label.text = "REWARDED TRANSMISSION"
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		_placement_label.text = "[REWARD SPONSOR: %s]" % placement.to_upper()
		_countdown_label.text = "Reward in 3s..."
		_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		_skip_btn.visible = true
		_skip_btn.text = "X"
	else:
		_total_duration = 2.0
		_timer_remaining = 2.0
		_title_label.text = "INTERSTITIAL SPONSOR"
		_title_label.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
		_placement_label.text = "[PLACEMENT: %s]" % placement.to_upper()
		_countdown_label.text = "Ad ends in 2s..."
		_countdown_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95))
		_skip_btn.visible = true
		_skip_btn.text = "X"

	_progress_bar.value = 0.0
	visible = true
	AudioManager.play_ui_blip("toggle")


func _process(delta: float) -> void:
	if not _is_running:
		return

	_timer_remaining -= delta
	var progress: float = 1.0 - clampf(_timer_remaining / _total_duration, 0.0, 1.0)
	_progress_bar.value = progress * 100.0

	var seconds_left: int = maxi(ceili(_timer_remaining), 0)

	if ad_type == AdType.REWARDED:
		if _timer_remaining > 0.0:
			_countdown_label.text = "Reward unlocks in %ds..." % seconds_left
		if _timer_remaining <= 0.0:
			_reward_earned = true
			_countdown_label.text = "REWARD GRANTED! YOU MAY CLOSE NOW"
			_countdown_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
			_skip_btn.text = "CLOSE"
			_skip_btn.custom_minimum_size = Vector2(80, 36)
	else:
		if _timer_remaining > 0.0:
			_countdown_label.text = "Closing in %ds..." % seconds_left
		else:
			_close_ad(true)


func _on_skip_pressed() -> void:
	AudioManager.play_ui_blip("click")
	if ad_type == AdType.REWARDED:
		if _reward_earned:
			_close_ad(true)
		else:
			# Closed early without earning reward
			_close_ad(false)
	else:
		_close_ad(true)


func _close_ad(success: bool) -> void:
	_is_running = false
	visible = false

	if success and ad_type == AdType.REWARDED:
		AudioManager.play_ui_blip("star")
	else:
		AudioManager.play_ui_blip("click")

	ad_completed.emit(success)

	if _callback.is_valid():
		_callback.call(success)
