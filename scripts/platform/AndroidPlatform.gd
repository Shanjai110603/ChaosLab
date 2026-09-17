## Android platform implementation.
## Supports ads, IAP, haptics, and native sharing (future).
class_name AndroidPlatform
extends BasePlatform


func initialize() -> void:
	print("[AndroidPlatform] Initialized")


func supports_ads() -> bool:
	return true  # Future: AdMob integration


func show_rewarded_ad(callback: Callable) -> void:
	# TODO: Integrate AdMob rewarded ads
	push_warning("[AndroidPlatform] AdMob not yet integrated — simulating reward")
	callback.call(true)


func show_interstitial() -> void:
	# TODO: Integrate AdMob interstitials
	push_warning("[AndroidPlatform] AdMob not yet integrated — skipping interstitial")


func supports_iap() -> bool:
	return true  # Future: Google Play Billing


func purchase(product_id: String, callback: Callable) -> void:
	# TODO: Integrate Google Play Billing
	push_warning("[AndroidPlatform] Billing not yet integrated. Product: %s" % product_id)
	callback.call(false)


func restore_purchases(callback: Callable) -> void:
	# TODO: Integrate purchase restoration
	push_warning("[AndroidPlatform] Billing not yet integrated — no purchases to restore")
	callback.call([])


func haptic(intensity: float) -> void:
	# Use Godot's vibration API on Android
	if intensity > 0.0:
		var duration_ms: int = int(intensity * 50.0)  # 0-50ms based on intensity
		Input.vibrate_handheld(duration_ms)


func share(text: String, image_path: String = "") -> void:
	# TODO: Use Android Intent for native sharing
	push_warning("[AndroidPlatform] Native sharing not yet implemented")
