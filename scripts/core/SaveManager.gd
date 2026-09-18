## Versioned local save system.
## Autoload singleton — handles save/load with migration support.
class_name SaveManagerClass
extends Node

## Current save data version. Increment when save format changes.
const SAVE_VERSION: int = 1
## Save file path.
const SAVE_PATH: String = "user://save_data.json"
## Backup save path.
const BACKUP_PATH: String = "user://save_data_backup.json"

## Emitted when save data is loaded.
signal data_loaded()
## Emitted when save data is written.
signal data_saved()

## The current save data dictionary.
var data: Dictionary = {}


func _ready() -> void:
	load_data()
	print("[SaveManager] Initialized. Save version: %d" % SAVE_VERSION)


## Load save data from disk. Creates default data if no save exists.
func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string := file.get_as_text()
			file.close()

			var json := JSON.new()
			var parse_result := json.parse(json_string)
			if parse_result == OK:
				data = json.data
				_migrate_if_needed()
				data_loaded.emit()
				print("[SaveManager] Data loaded successfully")
				return
			else:
				push_warning("[SaveManager] Failed to parse save data, using defaults")

	# No save file or parse error — create defaults
	_create_default_data()
	save_data()
	data_loaded.emit()


## Save current data to disk.
func save_data() -> void:
	# Create backup of existing save
	if FileAccess.file_exists(SAVE_PATH):
		var existing := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if existing:
			var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(existing.get_as_text())
				backup.close()
			existing.close()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		data_saved.emit()
	else:
		push_error("[SaveManager] Failed to open save file for writing")


## Create default save data structure.
func _create_default_data() -> void:
	data = {
		"save_version": SAVE_VERSION,
		"progress": {
			"current_level": 1,
			"completed_levels": {},  # level_id: {stars, score, chain}
			"worlds_unlocked": [1],
		},
		"currency": {
			"coins": 0,
			"gems": 0,
		},
		"unlocks": {
			"objects": ["ball", "box", "barrel", "bomb", "rocket"],
			"cosmetics": [],
			"lab_themes": [],
		},
		"settings": {
			"music_enabled": true,
			"sfx_enabled": true,
			"haptics_enabled": true,
			"graphics_quality": "medium",  # low, medium, high
			"language": "en",
		},
		"stats": {
			"total_experiments": 0,
			"total_chains": 0,
			"best_chain": 0,
			"total_score": 0,
			"best_score": 0,
			"total_play_time": 0.0,
		},
		"daily": {
			"last_completed_date": "",
			"streak": 0,
		},
	}
	print("[SaveManager] Created default save data")


## Migrate save data from older versions.
func _migrate_if_needed() -> void:
	var version: int = data.get("save_version", 0)
	if version == SAVE_VERSION:
		return

	print("[SaveManager] Migrating from v%d to v%d" % [version, SAVE_VERSION])

	# Add migration steps here as save format evolves:
	# if version < 2:
	#     _migrate_v1_to_v2()
	# if version < 3:
	#     _migrate_v2_to_v3()

	data["save_version"] = SAVE_VERSION
	save_data()


# --- Convenience accessors ---

## Get the number of stars earned for a level.
func get_level_stars(level_id: int) -> int:
	var completed: Dictionary = data.get("progress", {}).get("completed_levels", {})
	var level_data: Dictionary = completed.get(str(level_id), {})
	return level_data.get("stars", 0)


## Get the best score for a level.
func get_level_best_score(level_id: int) -> int:
	var completed: Dictionary = data.get("progress", {}).get("completed_levels", {})
	var level_data: Dictionary = completed.get(str(level_id), {})
	return level_data.get("score", 0)


## Whether a level is currently unlocked for play.
func is_level_unlocked(level_id: int) -> bool:
	if level_id <= 1:
		return true
	var current: int = data.get("progress", {}).get("current_level", 1)
	if level_id <= current:
		return true
	# Also check if previous level was cleared with stars
	var prev_stars := get_level_stars(level_id - 1)
	return prev_stars > 0


## Get total stars earned across all levels.
func get_total_stars() -> int:
	var total := 0
	var completed: Dictionary = data.get("progress", {}).get("completed_levels", {})
	for key in completed.keys():
		var info: Dictionary = completed[key]
		total += info.get("stars", 0)
	return total


## Get total stars earned in a specific world (1 = levels 1-10, 2 = levels 11-20).
func get_world_stars(world: int) -> int:
	var total := 0
	var start_id := (world - 1) * 10 + 1
	var end_id := start_id + 9
	for id in range(start_id, end_id + 1):
		total += get_level_stars(id)
	return total


## Save a level completion result (only updates if better).
func save_level_result(level_id: int, score: int, chain: int, stars: int) -> void:
	if not data.has("progress"):
		data["progress"] = {}
	if not data["progress"].has("completed_levels"):
		data["progress"]["completed_levels"] = {}

	var key := str(level_id)
	var existing: Dictionary = data["progress"]["completed_levels"].get(key, {})
	var best_score: int = maxi(existing.get("score", 0), score)
	var best_chain: int = maxi(existing.get("chain", 0), chain)
	var best_stars: int = maxi(existing.get("stars", 0), stars)

	data["progress"]["completed_levels"][key] = {
		"score": best_score,
		"chain": best_chain,
		"stars": best_stars,
	}

	# Update current level progress
	var next_level: int = level_id + 1
	var current: int = data["progress"].get("current_level", 1)
	if next_level > current:
		data["progress"]["current_level"] = next_level

	# Update stats
	var stats: Dictionary = data.get("stats", {})
	stats["total_experiments"] = stats.get("total_experiments", 0) + 1
	stats["total_score"] = stats.get("total_score", 0) + score
	stats["total_chains"] = stats.get("total_chains", 0) + chain
	if score > stats.get("best_score", 0):
		stats["best_score"] = score
	if chain > stats.get("best_chain", 0):
		stats["best_chain"] = chain
	data["stats"] = stats

	save_data()


## Add coins to the player's balance.
func add_coins(amount: int) -> void:
	if not data.has("currency"):
		data["currency"] = {"coins": 0, "gems": 0}
	data["currency"]["coins"] = data["currency"].get("coins", 0) + amount
	save_data()


## Get current coin balance.
func get_coins() -> int:
	return data.get("currency", {}).get("coins", 0)


## Get a setting value.
func get_setting(key: String, default_value: Variant = null) -> Variant:
	return data.get("settings", {}).get(key, default_value)


## Set a setting value and save.
func set_setting(key: String, value: Variant) -> void:
	if not data.has("settings"):
		data["settings"] = {}
	data["settings"][key] = value
	save_data()


## Clear all save data (for debug).
func clear_save() -> void:
	_create_default_data()
	save_data()
	print("[SaveManager] Save data cleared")
