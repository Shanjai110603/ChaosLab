## Achievement Manager — 12-badge retention and commercial achievements system.
## Autoload singleton — tracks persistent player milestones with claimable coin bounties.
class_name AchievementManagerClass
extends Node

signal achievement_progress_updated(id: String, current: int, max_val: int)
signal achievement_completed(id: String)
signal reward_claimed(id: String, coins: int)

const CATALOG: Array[Dictionary] = [
	{
		"id": "FIRST_SPARK",
		"name": "First Spark",
		"desc": "Successfully clear your first laboratory experiment.",
		"icon": "[START]",
		"target": 1,
		"reward": 100,
	},
	{
		"id": "PYROMANIAC",
		"name": "Pyromaniac",
		"desc": "Detonate 25 bombs or explosive chemical barrels.",
		"icon": "[BLAST]",
		"target": 25,
		"reward": 250,
	},
	{
		"id": "CHAIN_PRO",
		"name": "Chain Reaction Pro",
		"desc": "Achieve a consecutive 5x chain combo multiplier.",
		"icon": "[CHAIN]",
		"target": 5,
		"reward": 300,
	},
	{
		"id": "CHAIN_GOD",
		"name": "Chaos Overlord",
		"desc": "Achieve a massive 8x chain combo multiplier.",
		"icon": "[CHAOS]",
		"target": 8,
		"reward": 600,
	},
	{
		"id": "PAR_PERFECTIONIST",
		"name": "Par Perfectionist",
		"desc": "Complete 10 levels with leftover inventory par bonus.",
		"icon": "[TARGET]",
		"target": 10,
		"reward": 500,
	},
	{
		"id": "SPEED_DEMON",
		"name": "Speed Demon",
		"desc": "Clear any campaign experiment in under 5.0 seconds.",
		"icon": "[TIMER]",
		"target": 1,
		"reward": 250,
	},
	{
		"id": "ARMORY_NOVICE",
		"name": "Armory Novice",
		"desc": "Unlock your first cosmetic skin or arena theme.",
		"icon": "[SKIN]",
		"target": 1,
		"reward": 200,
	},
	{
		"id": "FASHIONISTA",
		"name": "Laboratory Fashionista",
		"desc": "Collect and unlock 5 cosmetic skins or themes.",
		"icon": "[VIP]",
		"target": 5,
		"reward": 750,
	},
	{
		"id": "PORTAL_TRAVELER",
		"name": "Quantum Traveler",
		"desc": "Teleport physics bodies through wormholes 15 times.",
		"icon": "[WARP]",
		"target": 15,
		"reward": 400,
	},
	{
		"id": "MAGNET_MASTER",
		"name": "Magnetic Flux",
		"desc": "Manipulate 20 metallic objects using electromagnets.",
		"icon": "[FLUX]",
		"target": 20,
		"reward": 400,
	},
	{
		"id": "DAILY_DEVOTION",
		"name": "Daily Devotion",
		"desc": "Maintain a consecutive 3-day daily experiment streak.",
		"icon": "[DAILY]",
		"target": 3,
		"reward": 500,
	},
	{
		"id": "WORLD_MASTER",
		"name": "Mechanics Master",
		"desc": "Earn all 30 stars across World 1 (The Mechanics Lab).",
		"icon": "[CUP]",
		"target": 30,
		"reward": 1000,
	}
]


func _ready() -> void:
	_ensure_save_data()
	print("[AchievementManager] Initialized with %d achievements" % CATALOG.size())


func _ensure_save_data() -> void:
	if not SaveManager.data.has("achievements"):
		SaveManager.data["achievements"] = {}


func get_catalog() -> Array[Dictionary]:
	return CATALOG


func get_achievement(id: String) -> Dictionary:
	for item in CATALOG:
		if item["id"] == id:
			return item
	return {}


func get_progress(id: String) -> int:
	_ensure_save_data()
	var rec: Dictionary = SaveManager.data["achievements"].get(id, {})
	return rec.get("progress", 0)


func is_completed(id: String) -> bool:
	var item := get_achievement(id)
	if item.is_empty():
		return false
	return get_progress(id) >= item.get("target", 1)


func is_claimed(id: String) -> bool:
	_ensure_save_data()
	var rec: Dictionary = SaveManager.data["achievements"].get(id, {})
	return rec.get("claimed", false)


## Increment or set progress for an achievement.
func add_progress(id: String, amount: int = 1) -> void:
	var item := get_achievement(id)
	if item.is_empty():
		return

	_ensure_save_data()
	var rec: Dictionary = SaveManager.data["achievements"].get(id, {"progress": 0, "claimed": false})
	var current: int = rec.get("progress", 0)
	var target: int = item.get("target", 1)

	if current >= target:
		return

	var new_val: int = mini(current + amount, target)
	rec["progress"] = new_val
	SaveManager.data["achievements"][id] = rec
	SaveManager.save_data()

	achievement_progress_updated.emit(id, new_val, target)

	if new_val >= target:
		achievement_completed.emit(id)
		AudioManager.play_fanfare()


## Claim coin reward for a completed achievement.
func claim_reward(id: String) -> bool:
	if not is_completed(id) or is_claimed(id):
		return false

	var item := get_achievement(id)
	var reward: int = item.get("reward", 0)

	_ensure_save_data()
	var rec: Dictionary = SaveManager.data["achievements"].get(id, {})
	rec["claimed"] = true
	SaveManager.data["achievements"][id] = rec
	SaveManager.add_coins(reward)
	SaveManager.save_data()

	reward_claimed.emit(id, reward)
	AudioManager.play_fanfare()
	return true


## Count total completed achievements.
func get_completed_count() -> int:
	var count := 0
	for item in CATALOG:
		if is_completed(item["id"]):
			count += 1
	return count
