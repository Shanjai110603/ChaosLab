## Centralized audio manager.
## Autoload singleton — controls music, SFX playback with bus routing.
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
## Current pool index (round-robin).
var _sfx_pool_index: int = 0
## Music player.
var _music_player: AudioStreamPlayer = null
## Cached audio streams. Key: name, Value: AudioStream.
var _audio_cache: Dictionary = {}


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

	# Ensure audio buses exist
	_setup_audio_buses()
	print("[AudioManager] Initialized with %d SFX players" % MAX_SFX_PLAYERS)


## Setup audio buses if they don't exist in the default layout.
func _setup_audio_buses() -> void:
	# Godot creates the Master bus by default.
	# We check if Music and SFX buses exist; if not, we create them at runtime.
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_MUSIC)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_SFX)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)


## Play a sound effect by resource path or cached name.
## Returns the AudioStreamPlayer used (for chaining if needed).
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


## Play music. Optionally crossfade.
func play_music(music_path: String, volume_db: float = -10.0, fade_duration: float = 1.0) -> void:
	if not SaveManager.get_setting("music_enabled", true):
		return

	var stream := _get_or_load_stream(music_path)
	if not stream:
		return

	if fade_duration > 0.0 and _music_player.playing:
		# Simple crossfade: fade out current, then play new
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


## Stop music with optional fade.
func stop_music(fade_duration: float = 0.5) -> void:
	if not _music_player.playing:
		return

	if fade_duration > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


## Set the volume of a bus by name (0.0 to 1.0 linear scale).
func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_volume))


## Mute/unmute a bus.
func set_bus_mute(bus_name: StringName, muted: bool) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, muted)


## Load or retrieve a cached audio stream.
func _get_or_load_stream(path: String) -> AudioStream:
	if _audio_cache.has(path):
		return _audio_cache[path]

	if not ResourceLoader.exists(path):
		# In Phase 1, many sounds won't exist yet — just return null silently
		return null

	var stream: AudioStream = load(path)
	if stream:
		_audio_cache[path] = stream
	return stream


## Apply settings (call when settings change).
func apply_settings() -> void:
	var music_enabled: bool = SaveManager.get_setting("music_enabled", true)
	var sfx_enabled: bool = SaveManager.get_setting("sfx_enabled", true)
	set_bus_mute(BUS_MUSIC, not music_enabled)
	set_bus_mute(BUS_SFX, not sfx_enabled)
	if not music_enabled:
		_music_player.stop()
