## Android platform implementation.
## Supports ads, IAP, haptics, and native sharing (future).
class_name AndroidPlatform
extends BasePlatform


func initialize() -> void:
	print("[AndroidPlatform] Initialized")


func supports_ads() -> bool:
	return true  # Future: AdMob integration


func show_rewarded_ad(callback: Callable, placement: String = "default") -> void:
	# Future: Native AdMob rewarded ads
	push_warning("[AndroidPlatform] AdMob rewarded ad requested (%s) — simulating reward" % placement)
	callback.call(true)


func show_interstitial(placement: String = "default", on_closed: Callable = Callable()) -> void:
	# Future: Native AdMob interstitials
	push_warning("[AndroidPlatform] AdMob interstitial requested (%s) — skipping" % placement)
	if on_closed.is_valid():
		on_closed.call()


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
		var duration_ms: int = 15
		if intensity > 0.7:
			duration_ms = 85
		elif intensity > 0.3:
			duration_ms = 40
		Input.vibrate_handheld(duration_ms)


func share(text: String, image_path: String = "") -> void:
	# TODO: Use Android Intent for native sharing
	push_warning("[AndroidPlatform] Native sharing not yet implemented")
