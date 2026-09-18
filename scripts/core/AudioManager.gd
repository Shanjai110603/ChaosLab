## Centralized audio manager.
## Autoload singleton — controls music, external SFX playback, and procedural AudioSynthesizer.
class_name AudioManagerClass
extends Node

## Audio bus names.
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

## Maximum number of simultaneous SFX players.
const MAX_SFX_PLAYERS: int = 16

## Pool of AudioStreamPlayer nodes for SFX.
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _music_player: AudioStreamPlayer = null
var _audio_cache: Dictionary = {}

## Procedural sound synthesizer.
var synth: AudioSynthesizer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create SFX pool
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)

	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	# Initialize procedural synthesizer
	synth = AudioSynthesizer.new()
	synth.name = "AudioSynthesizer"
	add_child(synth)

	_setup_audio_buses()
	print("[AudioManager] Initialized with procedural synthesizer and %d SFX players" % MAX_SFX_PLAYERS)


func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_MUSIC)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_SFX)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)


# --- Procedural Audio Synthesizer Triggers ---

## Play procedural explosion sound effect.
func play_explosion(intensity: float = 1.0) -> void:
	if synth:
		synth.play_explosion(intensity)


## Play procedural kinetic impact sound effect.
func play_impact(material: String = "wood", speed: float = 200.0) -> void:
	if synth:
		synth.play_impact(material, speed)


## Play procedural musical chime arpeggio for combos.
func play_chime(combo_tier: int = 1) -> void:
	if synth:
		synth.play_chime(combo_tier)


## Play procedural UI click blip.
func play_ui_blip(action_type: String = "select") -> void:
	if synth:
		synth.play_ui_blip(action_type)


## Play procedural victory fanfare.
func play_fanfare() -> void:
	if synth:
		synth.play_fanfare()


# --- Stream Playback ---

func play_sfx(sound_path: String, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	var stream := _get_or_load_stream(sound_path)
	if not stream:
		return null

	if not SaveManager.get_setting("sfx_enabled", true):
		return null

	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % MAX_SFX_PLAYERS

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	return player


func play_music(music_path: String, volume_db: float = -10.0, fade_duration: float = 1.0) -> void:
	if not SaveManager.get_setting("music_enabled", true):
		return

	var stream := _get_or_load_stream(music_path)
	if not stream:
		return

	if fade_duration > 0.0 and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = volume_db
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = volume_db
		_music_player.play()


func stop_music(fade_duration: float = 0.5) -> void:
	if not _music_player.playing:
		return

	if fade_duration > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_volume))


func set_bus_mute(bus_name: StringName, muted: bool) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, muted)


func _get_or_load_stream(path: String) -> AudioStream:
	if _audio_cache.has(path):
		return _audio_cache[path]

	if not ResourceLoader.exists(path):
		return null

	var stream: AudioStream = load(path)
	if stream:
		_audio_cache[path] = stream
	return stream


func apply_settings() -> void:
	var music_enabled: bool = SaveManager.get_setting("music_enabled", true)
	var sfx_enabled: bool = SaveManager.get_setting("sfx_enabled", true)
	set_bus_mute(BUS_MUSIC, not music_enabled)
	set_bus_mute(BUS_SFX, not sfx_enabled)
	if not music_enabled:
		_music_player.stop()
