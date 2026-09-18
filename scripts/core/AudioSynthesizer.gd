## AudioSynthesizer — Real-time procedural PCM waveform sound generator.
## Generates 100% self-contained sound effects using Godot's AudioStreamGenerator.
## No external audio files required!
class_name AudioSynthesizer
extends Node

const SAMPLE_RATE: float = 22050.0
const NUM_VOICES: int = 8

var _players: Array[AudioStreamPlayer] = []
var _playbacks: Array[AudioStreamGeneratorPlayback] = []
var _voice_idx: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_voices()


func _init_voices() -> void:
	for i in NUM_VOICES:
		var p := AudioStreamPlayer.new()
		p.name = "SynthVoice_%d" % i
		p.bus = &"SFX"
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = SAMPLE_RATE
		gen.buffer_length = 0.6
		p.stream = gen
		add_child(p)
		p.play()
		var pb: AudioStreamGeneratorPlayback = p.get_stream_playback()
		_players.append(p)
		_playbacks.append(pb)


func _get_next_playback() -> AudioStreamGeneratorPlayback:
	var pb: AudioStreamGeneratorPlayback = _playbacks[_voice_idx]
	_voice_idx = (_voice_idx + 1) % NUM_VOICES
	return pb


## Play procedural explosion: sub-bass drop + white noise decay.
func play_explosion(intensity: float = 1.0) -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	var duration: float = clampf(0.35 + intensity * 0.25, 0.3, 0.7)
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var phase: float = 0.0
	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration

		# Pitch drops from 120Hz down to 32Hz
		var freq: float = lerpf(120.0, 32.0, progress * progress)
		phase += freq * TAU / SAMPLE_RATE

		# Amplitude decay envelope
		var env: float = pow(1.0 - progress, 2.5) * intensity

		# Low-frequency rumble sine + textured white noise
		var sine_val := sin(phase) * 0.7
		var noise_val := randf_range(-0.35, 0.35)
		var sample := clampf((sine_val + noise_val) * env, -1.0, 1.0)

		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)


## Play procedural kinetic impact: damped sine pulse tuned to material & speed.
func play_impact(material: String = "wood", speed: float = 200.0) -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	var duration: float = 0.08
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var base_freq: float = 380.0
	match material:
		"metal":
			base_freq = 720.0
		"rubber":
			base_freq = 240.0
		"glass":
			base_freq = 1100.0
		"wood":
			base_freq = 360.0

	var velocity_vol := clampf(speed / 800.0, 0.15, 0.9)
	var phase: float = 0.0

	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration

		phase += base_freq * TAU / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 4.0) * velocity_vol
		var sample := clampf(sin(phase) * env, -1.0, 1.0)

		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)


## Play musical chime arpeggio scaled to combo multiplier.
func play_chime(combo_tier: int = 1) -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	# Pentatonic frequencies: C5, D5, E5, G5, A5, C6
	var scale_freqs := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.50]
	var freq_idx := clampi(combo_tier - 1, 0, scale_freqs.size() - 1)
	var target_freq: float = scale_freqs[freq_idx]

	var duration: float = 0.28
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var phase: float = 0.0
	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration

		phase += target_freq * TAU / SAMPLE_RATE
		# Pure bell sine with subtle overtone
		var env: float = pow(1.0 - progress, 2.0) * 0.75
		var fundamental := sin(phase) * 0.8
		var overtone := sin(phase * 2.0) * 0.2
		var sample := clampf((fundamental + overtone) * env, -1.0, 1.0)

		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)


## Play crisp tactile UI button click.
func play_ui_blip(action_type: String = "select") -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	var duration: float = 0.03
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var start_freq := 1200.0 if action_type == "select" else 800.0
	var end_freq := 1800.0 if action_type == "select" else 500.0

	var phase: float = 0.0
	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration

		var f := lerpf(start_freq, end_freq, progress)
		phase += f * TAU / SAMPLE_RATE
		var env: float = (1.0 - progress) * 0.4
		var sample := clampf(sin(phase) * env, -1.0, 1.0)

		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)


## Play celebratory victory triad arpeggio chord for 3-star clear.
func play_fanfare() -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	var duration: float = 0.65
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var c_freq := 523.25
	var e_freq := 659.25
	var g_freq := 783.99

	var phase_c := 0.0
	var phase_e := 0.0
	var phase_g := 0.0

	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration

		phase_c += c_freq * TAU / SAMPLE_RATE
		phase_e += e_freq * TAU / SAMPLE_RATE
		phase_g += g_freq * TAU / SAMPLE_RATE

		var env: float = pow(1.0 - progress, 1.8) * 0.75
		var sample := clampf((sin(phase_c) + sin(phase_e) + sin(phase_g)) * 0.33 * env, -1.0, 1.0)

		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)


## Play quantum portal teleport whoosh waveform.
func play_teleport() -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	var duration: float = 0.22
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var phase: float = 0.0
	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration
		var freq := lerpf(1200.0, 300.0, progress)
		phase += freq * TAU / SAMPLE_RATE
		var env: float = sin(progress * PI) * 0.7
		var sample := clampf(sin(phase) * env, -1.0, 1.0)
		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)


## Play high-frequency laser beam emission pulse.
func play_laser() -> void:
	if not SaveManager.get_setting("sfx_enabled", true):
		return

	var pb := _get_next_playback()
	if not pb:
		return

	var duration: float = 0.12
	var num_samples := int(SAMPLE_RATE * duration)
	var frames := PackedVector2Array()
	frames.resize(num_samples)

	var phase: float = 0.0
	for i in num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration
		var freq := 880.0 + sin(t * 120.0) * 80.0
		phase += freq * TAU / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 2.5) * 0.6
		var sample := clampf(sin(phase) * env, -1.0, 1.0)
		frames[i] = Vector2(sample, sample)

	pb.push_buffer(frames)
