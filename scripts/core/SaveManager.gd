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
		"equipped": {
			"bomb": "bomb_default",
			"ball": "ball_default",
			"theme": "theme_default",
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
		"purchases": {
			"remove_ads": false,
			"vip_pass": false,
			"order_history": [],
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
	if not data.has("purchases"):
		data["purchases"] = {
			"remove_ads": false,
			"vip_pass": false,
			"order_history": [],
		}
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


## Whether a world is unlocked (World 1 is always unlocked; World N requires previous world or stars).
func is_world_unlocked(world: int) -> bool:
	if world <= 1:
		return true
	var worlds: Array = data.get("progress", {}).get("worlds_unlocked", [1])
	if world in worlds:
		return true
	var current: int = data.get("progress", {}).get("current_level", 1)
	if current >= (world - 1) * 10 + 1:
		return true
	return get_world_stars(world - 1) >= 12


## Reset all progress and save data to defaults.
func reset_data() -> void:
	_create_default_data()
	save_data()
	data_loaded.emit()


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


## Whether player can afford a given coin cost.
func can_afford(cost: int) -> bool:
	return get_coins() >= cost


## Spend coins if affordable. Returns true on success.
func spend_coins(amount: int) -> bool:
	if not can_afford(amount):
		return false
	data["currency"]["coins"] = get_coins() - amount
	save_data()
	return true


## Check if a specific cosmetic skin is unlocked.
func is_skin_unlocked(skin_id: String) -> bool:
	if skin_id.ends_with("_default"):
		return true
	var skins: Array = data.get("unlocks", {}).get("cosmetics", [])
	return skin_id in skins


## Unlock a specific cosmetic skin.
func unlock_skin(skin_id: String) -> void:
	if not data.has("unlocks"):
		data["unlocks"] = {"cosmetics": []}
	if not data["unlocks"].has("cosmetics"):
		data["unlocks"]["cosmetics"] = []
	if skin_id not in data["unlocks"]["cosmetics"]:
		data["unlocks"]["cosmetics"].append(skin_id)
		save_data()


## Equip a cosmetic skin to a slot.
func equip_cosmetic(slot: String, skin_id: String) -> void:
	if not data.has("equipped"):
		data["equipped"] = {}
	data["equipped"][slot] = skin_id
	save_data()


## Get the currently equipped cosmetic for a slot.
func get_equipped_cosmetic(slot: String) -> String:
	return data.get("equipped", {}).get(slot, "%s_default" % slot)


# --- Monetization & Entitlements ---

## Whether player has removed ads (via Remove Ads or VIP Pass).
func is_ads_removed() -> bool:
	if not data.has("purchases"):
		return false
	return data["purchases"].get("remove_ads", false) or is_vip()


## Whether player owns the VIP Scientist Pass.
func is_vip() -> bool:
	if not data.has("purchases"):
		return false
	return data["purchases"].get("vip_pass", false)


## Grant a purchased commercial product.
func grant_purchase(product_id: String) -> bool:
	if not data.has("purchases"):
		data["purchases"] = {"remove_ads": false, "vip_pass": false, "order_history": []}

	var purchases: Dictionary = data["purchases"]
	if not purchases.has("order_history"):
		purchases["order_history"] = []

	var success := false
	match product_id:
		"coin_pack_small":
			add_coins(500)
			success = true
		"coin_pack_medium":
			add_coins(1500)
			success = true
		"coin_pack_large":
			add_coins(5000)
			success = true
		"remove_ads":
			purchases["remove_ads"] = true
			success = true
		"vip_pass":
			purchases["vip_pass"] = true
			purchases["remove_ads"] = true
			add_coins(1000)  # VIP Welcome bonus
			# Unlock exclusive VIP Gold skins
			unlock_skin("bomb_atomic")
			unlock_skin("ball_quantum")
			unlock_skin("theme_blueprint")
			success = true
		_:
			push_warning("[SaveManager] Unknown product ID: %s" % product_id)
			return false

	if success:
		purchases["order_history"].append({
			"product_id": product_id,
			"timestamp": Time.get_unix_time_from_system(),
		})
		save_data()
		print("[SaveManager] Successfully granted purchase: %s" % product_id)

	return success


## Restore previous purchases.
func restore_purchases(product_ids: Array) -> void:
	for pid in product_ids:
		if pid is String:
			grant_purchase(pid)


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
