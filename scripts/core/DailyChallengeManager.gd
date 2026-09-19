## Daily Challenge Manager — Live-ops daily puzzle and streak reward engine.
## Autoload singleton — generates seeded daily levels with unique laboratory modifiers.
class_name DailyChallengeManagerClass
extends Node

signal streak_updated(streak_count: int)
signal daily_completed(reward_coins: int)

enum Modifier {
	MOON_GRAVITY,   # 0.35x gravity scale
	HYPER_FUSE,     # 0.5x bomb fuse duration
	SUPER_BOUNCE,   # 1.4x bounce elasticity
	HEAVY_MASS,     # 2.0x mass on interactive bodies
}

const MODIFIER_DATA: Dictionary = {
	Modifier.MOON_GRAVITY: {
		"name": "Moon Gravity",
		"desc": "Arena gravity reduced to 35%. Objects float gracefully across chasms.",
		"icon": "[GRAVITY]",
		"color": Color(0.4, 0.8, 1.0)
	},
	Modifier.HYPER_FUSE: {
		"name": "Hyper Fuse",
		"desc": "Bomb fuses burn at 200% speed. Quick reactions required!",
		"icon": "[FUSE]",
		"color": Color(1.0, 0.4, 0.2)
	},
	Modifier.SUPER_BOUNCE: {
		"name": "Super Elasticity",
		"desc": "All laboratory bodies gain 140% rebound restitution. Maximum ricochets!",
		"icon": "[ELASTIC]",
		"color": Color(0.2, 1.0, 0.5)
	},
	Modifier.HEAVY_MASS: {
		"name": "Heavy Inertia",
		"desc": "Interactive bodies have double mass. High kinetic demolition power!",
		"icon": "[MASS]",
		"color": Color(1.0, 0.85, 0.2)
	}
}

const STREAK_REWARDS: Array[int] = [100, 150, 250, 350, 500, 700, 1000]


func _ready() -> void:
	_check_streak_status()
	print("[DailyChallengeManager] Initialized. Current Streak: %d" % get_streak())


## Get today's date formatted as YYYY-MM-DD.
func get_today_key() -> String:
	var dt := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


## Get integer seed from date key for deterministic generation.
func get_today_seed() -> int:
	var dt := Time.get_date_dict_from_system()
	return dt["year"] * 10000 + dt["month"] * 100 + dt["day"]


## Get today's active laboratory modifier.
func get_today_modifier() -> Modifier:
	var seed_val := get_today_seed()
	return (seed_val % MODIFIER_DATA.size()) as Modifier


## Get modifier data dictionary.
func get_modifier_info() -> Dictionary:
	var mod := get_today_modifier()
	return MODIFIER_DATA[mod]


## Current player streak count.
func get_streak() -> int:
	return SaveManager.data.get("daily", {}).get("streak", 0)


## Whether today's daily experiment has already been cleared.
func is_today_completed() -> bool:
	var last_date: String = SaveManager.data.get("daily", {}).get("last_completed_date", "")
	return last_date == get_today_key()


## Check and update streak status based on calendar days.
func _check_streak_status() -> void:
	var daily: Dictionary = SaveManager.data.get("daily", {})
	var last_date: String = daily.get("last_completed_date", "")
	if last_date.is_empty():
		return

	var today := get_today_key()
	if last_date == today:
		return

	# Calculate day difference
	var last_parts := last_date.split("-")
	var today_parts := today.split("-")
	if last_parts.size() == 3 and today_parts.size() == 3:
		var last_day: int = int(last_parts[2])
		var today_day: int = int(today_parts[2])
		var last_month: int = int(last_parts[1])
		var today_month: int = int(today_parts[1])

		if today_month == last_month and (today_day - last_day > 1):
			# Missed more than 1 day — reset streak
			daily["streak"] = 0
			SaveManager.data["daily"] = daily
			SaveManager.save_data()
			streak_updated.emit(0)


## Record completion of today's experiment.
func record_daily_completed() -> int:
	if is_today_completed():
		return 0

	var today := get_today_key()
	var current_streak := get_streak() + 1
	var reward_idx := clampi(current_streak - 1, 0, STREAK_REWARDS.size() - 1)
	var reward_coins: int = STREAK_REWARDS[reward_idx]

	var daily: Dictionary = SaveManager.data.get("daily", {})
	daily["last_completed_date"] = today
	daily["streak"] = current_streak
	SaveManager.data["daily"] = daily
	SaveManager.add_coins(reward_coins)

	# Check streak achievement
	if current_streak >= 3 and get_node_or_null("/root/AchievementManager"):
		get_node_or_null("/root/AchievementManager").add_progress("DAILY_DEVOTION", 1)

	streak_updated.emit(current_streak)
	daily_completed.emit(reward_coins)
	return reward_coins


## Generate LevelDefinition dynamically for today's challenge.
func generate_daily_level_definition() -> LevelDefinition:
	var seed_val := get_today_seed()
	var def := LevelDefinition.new()
	def.level_id = 990  # Special ID reserved for Daily Experiment
	def.world = 0
	def.title = "Daily Experiment (%s)" % get_today_key()
	def.world_title = "Laboratory Live-Ops"
	def.description = "Seeded experimental trial with %s active!" % get_modifier_info()["name"]
	def.time_limit = 25
	def.par_objects = 3
	def.score_targets = [500, 1200, 2500]

	# Targets
	var t_offset := (seed_val % 5) * 40
	def.targets = [
		Vector2(680 + t_offset, 320),
		Vector2(1180 - t_offset, 460)
	]

	# Pre-placed objects
	def.objects = [
		{"type": "ball", "position": Vector2(300, 180), "rotation": 0.0, "draggable": true},
		{"type": "ramp", "position": Vector2(480, 360), "rotation": 0.0, "draggable": true},
		{"type": "barrel", "position": Vector2(800, 560), "rotation": 0.0, "draggable": false},
		{"type": "bomb", "position": Vector2(1020, 560), "rotation": 0.0, "draggable": false}
	]

	# Inventory
	def.allowed_objects = ["ball", "ramp", "bomb", "magnet"]
	def.inventory = {"ball": 2, "ramp": 2, "bomb": 1, "magnet": 1}
	def.hints = [
		"Take advantage of today's active laboratory modifier",
		"Trigger the explosive sequence before time runs out",
		"Complete today's experiment to advance your streak"
	]

	return def
