## Platform abstraction service.
## Autoload singleton — detects platform and provides unified API.
class_name PlatformServiceClass
extends Node

## The active platform implementation.
var _platform: BasePlatform = null

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
	print("[PlatformService] Platform: %s" % get_platform_name())


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


## Show a rewarded ad. Callback receives true if reward was earned.
func show_rewarded_ad(callback: Callable) -> void:
	_platform.show_rewarded_ad(callback)


## Show an interstitial ad.
func show_interstitial() -> void:
	_platform.show_interstitial()


## Whether IAP is supported.
func supports_iap() -> bool:
	return _platform.supports_iap()


## Purchase a product by ID.
func purchase(product_id: String, callback: Callable) -> void:
	_platform.purchase(product_id, callback)


## Restore previous purchases.
func restore_purchases(callback: Callable) -> void:
	_platform.restore_purchases(callback)


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
