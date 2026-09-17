## Base platform abstraction class.
## All platform implementations extend this with their specific behavior.
class_name BasePlatform
extends Node


## Called after the platform node is added to the tree.
func initialize() -> void:
	pass


## Whether this platform supports advertisements.
func supports_ads() -> bool:
	return false


## Show a rewarded ad. Calls callback(true) if reward earned, callback(false) otherwise.
func show_rewarded_ad(callback: Callable) -> void:
	push_warning("[BasePlatform] Rewarded ads not supported on this platform")
	callback.call(false)


## Show an interstitial ad.
func show_interstitial() -> void:
	push_warning("[BasePlatform] Interstitial ads not supported on this platform")


## Whether this platform supports in-app purchases.
func supports_iap() -> bool:
	return false


## Purchase a product. Calls callback(true) on success, callback(false) on failure.
func purchase(product_id: String, callback: Callable) -> void:
	push_warning("[BasePlatform] IAP not supported on this platform. Product: %s" % product_id)
	callback.call(false)


## Restore previous purchases. Calls callback with array of restored product IDs.
func restore_purchases(callback: Callable) -> void:
	push_warning("[BasePlatform] Purchase restoration not supported on this platform")
	callback.call([])


## Trigger haptic feedback. Intensity 0.0 to 1.0.
func haptic(intensity: float) -> void:
	# Default: no-op. Subclasses override if hardware supports it.
	pass


## Share text and optional image.
func share(text: String, image_path: String = "") -> void:
	push_warning("[BasePlatform] Sharing not supported on this platform")


## Get platform-specific configuration value.
func get_config(key: String, default_value: Variant = null) -> Variant:
	return default_value
