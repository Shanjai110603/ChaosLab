## DebrisManager — Global particle/debris budget enforcer.
## Autoload singleton.
## Prevents debris particle counts from exceeding safe limits on low-end hardware.
## All debris spawners must call DebrisManager.request(count) before spawning
## and DebrisManager.release(count) when debris is freed.
class_name DebrisManager
extends Node

static var instance: DebrisManager = null

## Maximum simultaneous active debris particles across all emitters.
## Tuned per graphics quality profile.
const MAX_PARTICLES_HIGH: int = 128
const MAX_PARTICLES_MEDIUM: int = 96
const MAX_PARTICLES_LOW: int = 48

var _active_count: int = 0
var _budget: int = MAX_PARTICLES_MEDIUM


func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_quality_profile()
	print("[DebrisManager] Initialized. Budget: %d particles" % _budget)


func _apply_quality_profile() -> void:
	if not SaveManager:
		return
	var quality: String = SaveManager.get_setting("graphics_quality", "medium")
	match quality:
		"low":    _budget = MAX_PARTICLES_LOW
		"high":   _budget = MAX_PARTICLES_HIGH
		_:        _budget = MAX_PARTICLES_MEDIUM


## Request permission to spawn `count` debris particles.
## Returns true if within budget (spawn allowed), false if over budget (skip spawn).
static func request(count: int) -> bool:
	if not instance:
		return true  # Fail open if manager not loaded
	if instance._active_count + count > instance._budget:
		return false
	instance._active_count += count
	return true


## Release `count` particles back to the budget (call when debris is freed).
static func release(count: int) -> void:
	if not instance:
		return
	instance._active_count = maxi(0, instance._active_count - count)


## Current number of active tracked particles.
static func get_active_count() -> int:
	return instance._active_count if instance else 0


## Current budget ceiling.
static func get_budget() -> int:
	return instance._budget if instance else MAX_PARTICLES_MEDIUM


## Reconfigure budget if player changes graphics quality at runtime.
static func refresh_quality() -> void:
	if instance:
		instance._apply_quality_profile()
