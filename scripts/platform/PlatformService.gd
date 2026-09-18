## Platform abstraction service.
## Autoload singleton — detects platform and provides unified API.
class_name PlatformServiceClass
extends Node

## The active platform implementation.
var _platform: BasePlatform = null

## Interstitial cadence management.
const MIN_LEVELS_BETWEEN_INTERSTITIALS: int = 3
const INTERSTITIAL_COOLDOWN: float = 90.0

var last_interstitial_time: float = -90.0
var levels_completed_since_interstitial: int = 0

## Ad simulation overlay for Windows/Web testing.
var _ad_overlay: AdSimulationOverlay = null

## Platform identifiers.
enum PlatformType {
	WINDOWS,
	WEB,
	ANDROID,
	UNKNOWN,
}

## Current detected platform.
var platform_type: PlatformType = PlatformType.UNKNOWN


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detect_and_init_platform()
	_init_simulation_overlay()
	print("[PlatformService] Platform: %s" % get_platform_name())


## Initialize the simulation overlay for desktop/web testing.
func _init_simulation_overlay() -> void:
	_ad_overlay = AdSimulationOverlay.new()
	_ad_overlay.name = "AdSimulationOverlay"
	add_child(_ad_overlay)


## Detect the current platform and instantiate the correct implementation.
func _detect_and_init_platform() -> void:
	var os_name := OS.get_name()

	match os_name:
		"Android":
			platform_type = PlatformType.ANDROID
			_platform = AndroidPlatform.new()
		"Web":
			platform_type = PlatformType.WEB
			_platform = WebPlatform.new()
		"Windows", "UWP":
			platform_type = PlatformType.WINDOWS
			_platform = WindowsPlatform.new()
		_:
			platform_type = PlatformType.WINDOWS
			_platform = WindowsPlatform.new()
			push_warning("[PlatformService] Unknown OS '%s', defaulting to Windows" % os_name)

	_platform.name = "PlatformImpl"
	add_child(_platform)
	_platform.initialize()


## Get a human-readable platform name.
func get_platform_name() -> String:
	return PlatformType.keys()[platform_type]


## Whether the current platform supports ads.
func supports_ads() -> bool:
	return _platform.supports_ads()


## Notify that a level was completed (advances interstitial pacing).
func on_level_completed() -> void:
	levels_completed_since_interstitial += 1


## Whether an interstitial ad is eligible to be shown.
func can_show_interstitial() -> bool:
	if SaveManager.is_ads_removed():
		return false
	if levels_completed_since_interstitial < MIN_LEVELS_BETWEEN_INTERSTITIALS:
		return false
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_interstitial_time < INTERSTITIAL_COOLDOWN:
		return false
	return true


## Show a rewarded ad. Callback receives true if reward was earned.
func show_rewarded_ad(placement: String, callback: Callable) -> void:
	if _platform.supports_ads() and not OS.is_debug_build():
		_platform.show_rewarded_ad(callback, placement)
	else:
		# Use interactive simulation overlay for Windows/Web/Debug testing
		_ad_overlay.play_ad(AdSimulationOverlay.AdType.REWARDED, placement, callback)


## Show an interstitial ad (respects cadence and VIP/Remove Ads entitlement).
func show_interstitial(placement: String = "level_complete", on_closed: Callable = Callable()) -> void:
	if not can_show_interstitial():
		if on_closed.is_valid():
			on_closed.call()
		return

	last_interstitial_time = Time.get_ticks_msec() / 1000.0
	levels_completed_since_interstitial = 0

	if _platform.supports_ads() and not OS.is_debug_build():
		_platform.show_interstitial(placement, on_closed)
	else:
		_ad_overlay.play_ad(AdSimulationOverlay.AdType.INTERSTITIAL, placement, func(_ok: bool):
			if on_closed.is_valid():
				on_closed.call()
		)


## Whether IAP is supported.
func supports_iap() -> bool:
	return true  # Fully supported via platform or integrated simulator


## Purchase a product by ID (handles simulated purchases on Windows/Web).
func purchase(product_id: String, callback: Callable) -> void:
	if _platform.supports_iap() and not OS.is_debug_build():
		_platform.purchase(product_id, func(success: bool):
			if success:
				SaveManager.grant_purchase(product_id)
			callback.call(success)
		)
	else:
		# Simulation mode: grant purchase immediately
		var granted: bool = SaveManager.grant_purchase(product_id)
		callback.call(granted)


## Restore previous purchases.
func restore_purchases(callback: Callable) -> void:
	if _platform.supports_iap() and not OS.is_debug_build():
		_platform.restore_purchases(callback)
	else:
		var restored: Array = []
		if SaveManager.is_ads_removed():
			restored.append("remove_ads")
		if SaveManager.is_vip():
			restored.append("vip_pass")
		callback.call(restored)


## Trigger haptic feedback.
func haptic(intensity: float = 0.5) -> void:
	if SaveManager.get_setting("haptics_enabled", true):
		_platform.haptic(intensity)


## Light haptic feedback for UI clicks and mild bumps.
func haptic_light() -> void:
	haptic(0.2)


## Medium haptic feedback for kinetic impacts and chain reactions.
func haptic_medium() -> void:
	haptic(0.5)


## Heavy haptic feedback for explosions and target completions.
func haptic_heavy() -> void:
	haptic(1.0)


## Share text/image.
func share(text: String, image_path: String = "") -> void:
	_platform.share(text, image_path)


## Whether this platform is mobile.
func is_mobile() -> bool:
	return platform_type == PlatformType.ANDROID


## Whether this platform is web.
func is_web() -> bool:
	return platform_type == PlatformType.WEB
