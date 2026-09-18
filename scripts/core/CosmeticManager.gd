## Central manager for all cosmetic skins, themes, and laboratory customization.
## Autoload singleton — provides skin catalogs, unlocks, and active visual themes.
class_name CosmeticManagerClass
extends Node

signal skin_unlocked(skin_id: String)
signal skin_equipped(slot: String, skin_id: String)

const SLOT_BOMB: String = "bomb"
const SLOT_BALL: String = "ball"
const SLOT_THEME: String = "theme"

## Cosmetic catalog definitions.
const CATALOG: Dictionary = {
	"bomb": [
		{
			"id": "bomb_default",
			"name": "Cast Iron",
			"desc": "Standard military laboratory ordnance.",
			"price": 0,
			"primary_color": Color(0.12, 0.14, 0.18),
			"accent_color": Color(0.9, 0.2, 0.2),
			"spark_color": Color(1.0, 0.5, 0.1),
		},
		{
			"id": "bomb_neon",
			"name": "Cyber Neon",
			"desc": "High-voltage containment vessel with glowing cyan core.",
			"price": 350,
			"primary_color": Color(0.1, 0.05, 0.25),
			"accent_color": Color(0.0, 0.95, 1.0),
			"spark_color": Color(0.9, 0.1, 1.0),
		},
		{
			"id": "bomb_gold",
			"name": "Golden Ordnance",
			"desc": "Pure bullion explosive casing with ruby ignition.",
			"price": 800,
			"primary_color": Color(0.95, 0.8, 0.2),
			"accent_color": Color(0.9, 0.1, 0.2),
			"spark_color": Color(1.0, 0.95, 0.5),
		},
		{
			"id": "bomb_radioactive",
			"name": "Toxic Hazard",
			"desc": "Bio-chemical warhead emitting dangerous isotope glow.",
			"price": 550,
			"primary_color": Color(0.12, 0.28, 0.12),
			"accent_color": Color(0.2, 1.0, 0.3),
			"spark_color": Color(0.5, 1.0, 0.2),
		},
	],
	"ball": [
		{
			"id": "ball_default",
			"name": "Polished Steel",
			"desc": "High-density chromium bearing sphere.",
			"price": 0,
			"primary_color": Color(0.65, 0.72, 0.8),
			"accent_color": Color(0.9, 0.95, 1.0),
			"glow_color": Color(0.5, 0.7, 1.0, 0.3),
		},
		{
			"id": "ball_magma",
			"name": "Molten Magma",
			"desc": "Dense obsidian rock pulsing with volcanic heat.",
			"price": 400,
			"primary_color": Color(0.2, 0.08, 0.05),
			"accent_color": Color(1.0, 0.4, 0.05),
			"glow_color": Color(1.0, 0.3, 0.0, 0.5),
		},
		{
			"id": "ball_plasma",
			"name": "Electric Plasma",
			"desc": "Pure ionization energy trapped inside a forcefield.",
			"price": 650,
			"primary_color": Color(0.05, 0.25, 0.45),
			"accent_color": Color(0.1, 0.9, 1.0),
			"glow_color": Color(0.0, 0.8, 1.0, 0.6),
		},
		{
			"id": "ball_chrome",
			"name": "Rainbow Prism",
			"desc": "Iridescent prism crystal refracting vibrant spectra.",
			"price": 900,
			"primary_color": Color(0.85, 0.85, 0.95),
			"accent_color": Color(1.0, 0.6, 0.8),
			"glow_color": Color(0.8, 0.4, 1.0, 0.5),
		},
	],
	"theme": [
		{
			"id": "theme_default",
			"name": "High-Tech Blue",
			"desc": "Clean blueprint lab grid with cyan energy perimeter.",
			"price": 0,
			"bg_color": Color(0.04, 0.06, 0.1),
			"grid_color": Color(0.0, 0.7, 1.0, 0.06),
			"border_color": Color(0.0, 0.85, 1.0, 0.8),
			"bracket_color": Color(0.0, 0.9, 1.0, 0.9),
		},
		{
			"id": "theme_matrix",
			"name": "Emerald Terminal",
			"desc": "Retro mainframe phosphor terminal environment.",
			"price": 500,
			"bg_color": Color(0.02, 0.08, 0.03),
			"grid_color": Color(0.1, 0.9, 0.3, 0.07),
			"border_color": Color(0.15, 1.0, 0.35, 0.85),
			"bracket_color": Color(0.2, 1.0, 0.4, 0.95),
		},
		{
			"id": "theme_deep_space",
			"name": "Cosmic Nebula",
			"desc": "Deep space void with ultraviolet starfield radiance.",
			"price": 750,
			"bg_color": Color(0.07, 0.03, 0.12),
			"grid_color": Color(0.7, 0.2, 1.0, 0.07),
			"border_color": Color(0.85, 0.25, 1.0, 0.85),
			"bracket_color": Color(0.95, 0.4, 1.0, 0.95),
		},
		{
			"id": "theme_hazard",
			"name": "Amber Hazard",
			"desc": "Heavy industrial quarantine containment testing ground.",
			"price": 1000,
			"bg_color": Color(0.09, 0.07, 0.02),
			"grid_color": Color(1.0, 0.75, 0.0, 0.08),
			"border_color": Color(1.0, 0.8, 0.1, 0.9),
			"bracket_color": Color(1.0, 0.85, 0.2, 1.0),
		},
	],
}


func _ready() -> void:
	# Ensure default skins are unlocked and equipped if missing
	_ensure_default_unlocks()
	print("[CosmeticManager] Initialized with %d categories" % CATALOG.size())


func _ensure_default_unlocks() -> void:
	for slot in [SLOT_BOMB, SLOT_BALL, SLOT_THEME]:
		var default_id := "%s_default" % slot
		if not SaveManager.is_skin_unlocked(default_id):
			SaveManager.unlock_skin(default_id)
		if SaveManager.get_equipped_cosmetic(slot).is_empty():
			SaveManager.equip_cosmetic(slot, default_id)


## Get full item catalog list for a given slot category.
func get_catalog(slot: String) -> Array:
	return CATALOG.get(slot, [])


## Find specific item dictionary by ID.
func get_item(skin_id: String) -> Dictionary:
	for slot in CATALOG.keys():
		for item in CATALOG[slot]:
			if item["id"] == skin_id:
				return item
	return {}


## Whether a skin is unlocked.
func is_unlocked(skin_id: String) -> bool:
	return SaveManager.is_skin_unlocked(skin_id)


## Attempt to purchase/unlock a skin with player coins.
func unlock_skin(skin_id: String) -> bool:
	if is_unlocked(skin_id):
		return true

	var item := get_item(skin_id)
	if item.is_empty():
		return false

	var price: int = item.get("price", 0)
	if not SaveManager.can_afford(price):
		return false

	if SaveManager.spend_coins(price):
		SaveManager.unlock_skin(skin_id)
		skin_unlocked.emit(skin_id)
		return true

	return false


## Equip an unlocked skin to its respective slot.
func equip_skin(slot: String, skin_id: String) -> bool:
	if not is_unlocked(skin_id):
		return false

	SaveManager.equip_cosmetic(slot, skin_id)
	skin_equipped.emit(slot, skin_id)
	return true


## Get currently active skin ID for a slot.
func get_equipped(slot: String) -> String:
	return SaveManager.get_equipped_cosmetic(slot)


## Get the active theme config dictionary.
func get_active_theme() -> Dictionary:
	var theme_id := get_equipped(SLOT_THEME)
	var item := get_item(theme_id)
	if not item.is_empty():
		return item
	return CATALOG["theme"][0]
